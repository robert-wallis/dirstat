// Copyright (C) 2024 Robert A. Wallis, all rights reserved.
const std = @import("std");

pub fn printCountEntryKind(writer: anytype, count_entry_kind: *std.EnumArray(std.fs.Dir.Entry.Kind, u32)) !void {
    var count_entry_kind_iter = count_entry_kind.iterator();
    while (count_entry_kind_iter.next()) |field| {
        if (field.value.* > 0)
            try writer.print("{s:10}: {}\n", .{ @tagName(field.key), field.value.* });
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
