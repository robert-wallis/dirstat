// Copyright (C) 2024 Robert A. Wallis, all rights reserved.
const std = @import("std");

pub fn printIterator(writer: anytype, name: []const u8, iterator: anytype) !void {
    try writer.print("{s}:\n", .{name});
    while (iterator.next()) |entry| {
        if (entry.value > 0)
            try writer.print("{}\t{s}\n", .{ entry.value, entry.key });
    }
}

pub fn countEntryKindUnordered(writer: anytype, count_entry_kind: *std.EnumArray(std.fs.Dir.Entry.Kind, u32)) !void {
    try writer.print("kinds:\n", .{});
    var count_entry_kind_iter = count_entry_kind.iterator();
    while (count_entry_kind_iter.next()) |field| {
        if (field.value.* > 0)
            try writer.print("{}\t{s}\n", .{ field.value.*, @tagName(field.key) });
    }
}

pub fn extensionsUnordered(writer: anytype, count_extensions: *std.StringHashMap(u32)) !void {
    try writer.print("extensions:\n", .{});
    var iter = count_extensions.iterator();
    while (iter.next()) |entry| {
        try writer.print("{}\t{s}\n", .{ entry.value_ptr.*, entry.key_ptr.* });
    }
}
