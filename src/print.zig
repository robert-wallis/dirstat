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

/// Returns the number of bytes in a human format.
/// ex. 1024 -> 1K
pub fn formatBytesHuman(out: []u8, bytes: u64) []u8 {
    if (bytes < 1024) {
        return std.fmt.bufPrint(out, "{d}B", .{bytes}) catch out[0..0];
    } else if (bytes < 0x10_0000) {
        return std.fmt.bufPrint(out, "{d}K", .{bytes / 0x400}) catch out[0..0];
    } else if (bytes < 0x4000_0000) {
        // https://soundcloud.com/neilcic/mouth-moods#t=8%3A22 300MB of hard drive storage capcity, that's right
        return std.fmt.bufPrint(out, "{d}M", .{bytes / 0x10_0000}) catch out[0..0];
    } else if (bytes < 0x100_0000_0000) {
        return std.fmt.bufPrint(out, "{d}G", .{bytes / 0x4000_0000}) catch out[0..0];
    } else if (bytes < 0x4_0000_0000_0000) {
        return std.fmt.bufPrint(out, "{d}T", .{bytes / 0x100_0000_0000}) catch out[0..0];
    } else if (bytes < 0x1000_0000_0000_0000) {
        return std.fmt.bufPrint(out, "{d}P", .{bytes / 0x4_0000_0000_0000}) catch out[0..0];
    }
    return std.fmt.bufPrint(out, "{d}E", .{bytes / 0x1000_0000_0000_0000}) catch out[0..0];
}

test formatBytesHuman {
    var out: [64]u8 = undefined;
    try std.testing.expectEqualStrings("0B", formatBytesHuman(&out, 0));
    try std.testing.expectEqualStrings("1023B", formatBytesHuman(&out, 0x400 - 1));
    try std.testing.expectEqualStrings("1K", formatBytesHuman(&out, 0x400));
    try std.testing.expectEqualStrings("1023K", formatBytesHuman(&out, 0x10_0000 - 1));
    try std.testing.expectEqualStrings("1M", formatBytesHuman(&out, 0x10_0000));
    try std.testing.expectEqualStrings("1023M", formatBytesHuman(&out, 0x4000_0000 - 1));
    try std.testing.expectEqualStrings("1G", formatBytesHuman(&out, 0x4000_0000));
    try std.testing.expectEqualStrings("1023G", formatBytesHuman(&out, 0x100_0000_0000 - 1));
    try std.testing.expectEqualStrings("1T", formatBytesHuman(&out, 0x100_0000_0000));
    try std.testing.expectEqualStrings("1023T", formatBytesHuman(&out, 0x4_0000_0000_0000 - 1));
    try std.testing.expectEqualStrings("1P", formatBytesHuman(&out, 0x4_0000_0000_0000));
    try std.testing.expectEqualStrings("1023P", formatBytesHuman(&out, 0x1000_0000_0000_0000 - 1));
    try std.testing.expectEqualStrings("1E", formatBytesHuman(&out, 0x1000_0000_0000_0000));
    try std.testing.expectEqualStrings("15E", formatBytesHuman(&out, 0xFFFF_FFFF_FFFF_FFFF));
}
