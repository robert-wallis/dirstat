// Copyright (C) 2024 Robert A. Wallis, all rights reserved.
const std = @import("std");
const print = @import("print.zig");

pub fn main() !void {
    const stdout_writer = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_writer);

    const stdout = bw.writer();

    const allocator = std.heap.page_allocator;
    var root_dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer root_dir.close();

    var count_entry_kind = std.EnumArray(std.fs.Dir.Entry.Kind, u32).initFill(0);

    var walker = try root_dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        count_entry_kind.getPtr(entry.kind).* += 1;
    }

    try print.printCountEntryKind(stdout, &count_entry_kind);
    try bw.flush();
}
