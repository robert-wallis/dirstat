// Copyright (C) 2024 Robert A. Wallis, all rights reserved.
const std = @import("std");
const string = @import("string.zig");
const order = @import("order.zig");
const option = @import("option.zig");
const print = @import("print.zig");

pub fn analyzePath(path: []const u8, options: *const option.Options) !void {
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
        if (entry.kind == .file) {
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
    }

    // stats are now aggregated time for reporting

    const stdout = std.io.getStdOut().writer();

    {
        var iterator = kind_count.iterator();
        const items = try order.sortEnumIterator(allocator, &iterator, options.order_by);
        defer allocator.free(items);

        try stdout.print("kind:\n", .{});
        try print.printIterator(stdout, items);
    }

    try stdout.print("\n", .{});

    {
        var iterator = kind_bytes.iterator();
        const items = try order.sortEnumIterator(allocator, &iterator, options.order_by);
        defer allocator.free(items);

        try stdout.print("bytes by kind:\n", .{});
        try print.printBytesIterator(stdout, items, options);
    }

    try stdout.print("\n", .{});

    {
        var iterator = extension_count.iterator();
        const items = try order.sortStringIterator(allocator, &iterator, options.order_by);
        defer allocator.free(items);

        try stdout.print("extension:\n", .{});
        try print.printIterator(stdout, items);
    }

    try stdout.print("\n", .{});

    {
        var iterator = extension_bytes.iterator();
        const items = try order.sortStringIterator(allocator, &iterator, options.order_by);
        defer allocator.free(items);

        try stdout.print("bytes by extension:\n", .{});
        try print.printBytesIterator(stdout, items, options);
    }
}
