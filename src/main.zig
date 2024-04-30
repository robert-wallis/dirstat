// Copyright (C) 2024 Robert A. Wallis, all rights reserved.
const order = @import("order.zig");
const print = @import("print.zig");
const std = @import("std");
const string = @import("string.zig");

pub const Options = struct {
    order_by: order.Order,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();

    var paths = std.ArrayList([]const u8).init(allocator);
    defer paths.deinit();

    var options: Options = .{ .order_by = .valueDescending };
    {
        var args_iter = try std.process.argsWithAllocator(allocator);
        defer args_iter.deinit();
        var arg_idx: usize = 0;
        while (args_iter.next()) |arg| {
            if (std.mem.eql(u8, "--", arg[0..2])) {
                if (std.mem.eql(u8, "key-asc", arg[2..])) {
                    options.order_by = .keyAscending;
                } else if (std.mem.eql(u8, "key-desc", arg[2..])) {
                    options.order_by = .keyDescending;
                } else if (std.mem.eql(u8, "key", arg[2..])) {
                    options.order_by = .keyAscending;
                } else if (std.mem.eql(u8, "value-asc", arg[2..])) {
                    options.order_by = .valueAscending;
                } else if (std.mem.eql(u8, "value-desc", arg[2..])) {
                    options.order_by = .valueDescending;
                } else if (std.mem.eql(u8, "value", arg[2..])) {
                    options.order_by = .valueDescending;
                } else {
                    try usage();
                    std.process.exit(1);
                    return;
                }
            } else if ('-' == arg[0]) {
                if (std.mem.indexOf(u8, arg, "k") != null) {
                    if (std.mem.indexOf(u8, arg, "a") != null) {
                        options.order_by = .keyAscending;
                    } else if (std.mem.indexOf(u8, arg, "d") != null) {
                        options.order_by = .keyDescending;
                    } else {
                        options.order_by = .keyAscending;
                    }
                } else if (std.mem.indexOf(u8, arg, "v") != null) {
                    if (std.mem.indexOf(u8, arg, "a") != null) {
                        options.order_by = .valueAscending;
                    } else if (std.mem.indexOf(u8, arg, "d") != null) {
                        options.order_by = .valueDescending;
                    } else {
                        options.order_by = .valueAscending;
                    }
                }
            } else if (arg_idx > 0) {
                try paths.append(arg);
            }
            arg_idx += 1;
        }
    }

    if (paths.items.len == 0) {
        try paths.append("."); // default to this folder
    }

    for (paths.items) |path| {
        try stdout.print("path: {s}\n\n", .{path});
        try pathWalker(path);
    }
}

fn pathWalker(path: []const u8) !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    var root_dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
    defer root_dir.close();

    var kind_count = std.EnumArray(std.fs.Dir.Entry.Kind, u32).initFill(0);
    var kind_bytes = std.EnumArray(std.fs.Dir.Entry.Kind, u64).initFill(0);
    var extension_count = std.StringHashMap(u32).init(allocator);
    defer extension_count.deinit();
    var extension_bytes = std.StringHashMap(u64).init(allocator);
    defer extension_bytes.deinit();

    var walker = try root_dir.walk(allocator);
    defer walker.deinit();

    // go through every file in the path
    while (try walker.next()) |entry| {
        // update the number of this kind of file
        kind_count.getPtr(entry.kind).* += 1;

        // get the stats for the file, so we can update the number of bytes it takes
        const stat_opt: ?std.fs.File.Stat = entry.dir.statFile(entry.basename) catch null;
        // add to the bytes for this kind of file
        if (stat_opt) |stat|
            kind_bytes.getPtr(entry.kind).* += stat.size;

        // if there's a file extension
        if (string.extension(entry.basename)) |ext| {
            if (extension_count.getPtr(ext)) |val| {
                // extension already in count
                val.* += 1;
            } else {
                // extension not in count, need to alloc some space to save the string, because it is owned by walker right now
                const ext_dup = try arena_alloc.dupe(u8, ext);
                try extension_count.put(ext_dup, 1);
            }
            if (stat_opt) |stat| {
                // update size statistics for this stat
                if (extension_bytes.getPtr(ext)) |val| {
                    // extension already list of bytes for this extension
                    val.* += stat.size;
                } else {
                    // extension not in the map, need to alloc the key because it's owned by walker right now
                    const ext_dup = try arena_alloc.dupe(u8, ext);
                    try extension_bytes.put(ext_dup, stat.size);
                }
            }
        }
    }

    // stats are now aggregated time for reporting

    const stdout = std.io.getStdOut().writer();

    {
        var ordered = order.OrderBy(u32, .valueDescending).init(allocator);
        defer ordered.deinit();
        var iter = kind_count.iterator();
        try ordered.addEnumIterator(&iter);
        try print.printIterator(stdout, "kind", &ordered);
    }

    try stdout.print("\n", .{});

    {
        const KV = struct {
            key: []const u8,
            value: u64,
        };
        const ValueDescending = struct {
            items: []KV,
            pub fn lessThan(_: @This(), lhs: KV, rhs: KV) bool {
                return rhs.value < lhs.value; // backwards on purpose to do descending
            }
        };
        var list = std.ArrayList(KV).init(allocator);
        defer list.deinit();
        var iter = kind_bytes.iterator();
        while (iter.next()) |entry| {
            if (entry.value.* > 0)
                try list.append(.{ .key = @tagName(entry.key), .value = entry.value.* });
        }
        std.mem.sort(KV, list.items, ValueDescending{ .items = list.items }, ValueDescending.lessThan);
        try stdout.print("bytes by kind:\n", .{});
        for (list.items) |entry| {
            try stdout.print("{}\t{s}\n", .{ entry.value, entry.key });
        }
    }

    try stdout.print("\n", .{});

    {
        var ordered = order.OrderBy(u32, .valueDescending).init(allocator);
        defer ordered.deinit();
        var iter = extension_count.iterator();
        try ordered.addPtrIterator(&iter);
        try print.printIterator(stdout, "extension", &ordered);
    }

    try stdout.print("\n", .{});

    {
        const KV = struct {
            key: []const u8,
            value: u64,
        };
        const ValueDescending = struct {
            items: []KV,
            pub fn lessThan(_: @This(), lhs: KV, rhs: KV) bool {
                return rhs.value < lhs.value; // backwards on purpose to do descending
            }
        };
        var list = std.ArrayList(KV).init(allocator);
        defer list.deinit();
        var iter = extension_bytes.iterator();
        while (iter.next()) |entry| {
            if (entry.value_ptr.* > 0)
                try list.append(.{ .key = entry.key_ptr.*, .value = entry.value_ptr.* });
        }
        std.mem.sort(KV, list.items, ValueDescending{ .items = list.items }, ValueDescending.lessThan);
        try stdout.print("bytes by extension:\n", .{});
        for (list.items) |entry| {
            try stdout.print("{}\t{s}\n", .{ entry.value, entry.key });
        }
    }
}

fn usage() !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print("usage:\tdirstat [-k][-v][-a][-d] [path [path ...]]\n", .{});
    try stderr.print("\t-k --key\tsort by key\n", .{});
    try stderr.print("\t        \tkey is sorted by alphabetically unless -d is used\n", .{});
    try stderr.print("\t-v --value\tsort by Value\n", .{});
    try stderr.print("\t          \tvalue is the default sort\n", .{});
    try stderr.print("\t          \tvalue is sorted by largest to smallest unless -a is used\n", .{});
    try stderr.print("\t-a --key-asc --value-asc\tsort by value acending, lowest to highest\n", .{});
    try stderr.print("\t-d --value-desc --value-desc\tsort by value descending, highest to lowest\n", .{});
}
