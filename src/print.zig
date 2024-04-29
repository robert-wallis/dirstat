// Copyright (C) 2024 Robert A. Wallis, all rights reserved.
const std = @import("std");

pub const Order = enum {
    unordered,
    key,
    value,
};

pub fn countEntryKind(writer: anytype, count_entry_kind: *std.EnumArray(std.fs.Dir.Entry.Kind, u32)) !void {
    try writer.print("kinds:\n", .{});
    var count_entry_kind_iter = count_entry_kind.iterator();
    while (count_entry_kind_iter.next()) |field| {
        if (field.value.* > 0)
            try writer.print("{}\t{s}\n", .{ field.value.*, @tagName(field.key) });
    }
}

/// a single letter representing a directory entry kind
pub fn singleLetterFileKind(kind: std.fs.Dir.Entry.Kind) u8 {
    return switch (kind) {
        .block_device => 'b',
        .character_device => 'c',
        .directory => 'd',
        .named_pipe => 'p',
        .sym_link => 's',
        .file => 'f',
        .unix_domain_socket => 'u',
        .whiteout => 'w',
        .door => 'r',
        .event_port => 'e',
        .unknown => '?',
    };
}

pub fn extensions(writer: anytype, count_extensions: *std.StringHashMap(u32)) !void {
    try writer.print("extensions:\n", .{});
    var iter = count_extensions.iterator();
    while (iter.next()) |entry| {
        try writer.print("{}\t{s}\n", .{ entry.value_ptr.*, entry.key_ptr.* });
    }
}
