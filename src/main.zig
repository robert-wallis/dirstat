// Copyright (C) 2024 Robert A. Wallis, all rights reserved.
const analyze = @import("analyze.zig");
const option = @import("option.zig");
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();

    var args_iter = try std.process.argsWithAllocator(allocator);
    defer args_iter.deinit();
    var options = try option.parse(allocator, &args_iter);
    defer options.paths.deinit();

    for (options.paths.items) |path| {
        try stdout.print("path: {s}\n\n", .{path});
        try analyze.analyzePath(path, &options);
    }
}
