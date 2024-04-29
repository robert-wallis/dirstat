// Copyright (C) 2024 Robert A. Wallis, all rights reserved.
const order = @import("order.zig");
const print = @import("print.zig");
const std = @import("std");
const string = @import("string.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();

    var paths = std.ArrayList([]const u8).init(allocator);
    defer paths.deinit();

    {
        var args_iter = try std.process.argsWithAllocator(allocator);
        defer args_iter.deinit();
        var arg_idx: usize = 0;
        while (args_iter.next()) |arg| {
            if (std.mem.eql(u8, arg[0..2], "--")) {
                try usage();
                return error.Usage;
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

    var count_entry_kind = std.EnumArray(std.fs.Dir.Entry.Kind, u32).initFill(0);
    var count_extensions = std.StringHashMap(u32).init(allocator);
    defer count_extensions.deinit();

    var walker = try root_dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        count_entry_kind.getPtr(entry.kind).* += 1;
        if (string.extension(entry.basename)) |ext| {
            if (count_extensions.getPtr(ext)) |val| {
                val.* += 1;
            } else {
                const ext_dup = try arena_alloc.dupe(u8, ext);
                try count_extensions.put(ext_dup, 1);
            }
        }
    }

    const stdout = std.io.getStdOut().writer();

    {
        var kinds_ordered = order.OrderBy(u32, .valueDescending).init(allocator);
        defer kinds_ordered.deinit();
        var count_entry_kind_iter = count_entry_kind.iterator();
        while (count_entry_kind_iter.next()) |entry| {
            try kinds_ordered.add(@tagName(entry.key), entry.value.*);
        }
        try print.printIterator(stdout, "kind", &kinds_ordered);
    }

    try stdout.print("\n", .{});

    {
        var extensions_ordered = order.OrderBy(u32, .valueDescending).init(allocator);
        defer extensions_ordered.deinit();
        var count_extensions_iter = count_extensions.iterator();
        try extensions_ordered.addPtrIterator(&count_extensions_iter);
        try print.printIterator(stdout, "extension", &extensions_ordered);
    }
}

fn usage() !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print("usage:\tdirstat [path [path ...]]\n", .{});
}
