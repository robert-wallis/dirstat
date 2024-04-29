// Copyright (C) 2024 Robert A. Wallis, all rights reserved.
const std = @import("std");

pub fn extension(filename: []const u8) ?[]const u8 {
    if (std.mem.lastIndexOf(u8, filename, ".")) |pos| {
        return filename[pos..];
    }
    return null;
}

test extension {
    try std.testing.expectEqualStrings(".jpg", extension("success-kid.jpg").?);
    try std.testing.expectEqualStrings(".DS_Store", extension(".DS_Store").?);
    try std.testing.expectEqualStrings("none", extension("LICENSE") orelse "none");

    const oprah_bees = "oprah-bees.gif".*;
    const fellow_kids = "fellow-kids.gif".*;
    const oprah_bees_ext = extension(&oprah_bees).?;
    const fellow_kids_ext = extension(&fellow_kids).?;
    try std.testing.expectEqualStrings(oprah_bees_ext, fellow_kids_ext);

    const hashString = std.hash_map.hashString;
    try std.testing.expectEqual(hashString(oprah_bees_ext), hashString(fellow_kids_ext));
}
