// Copyright (C) 2024 Robert A. Wallis, all rights reserved.
const std = @import("std");

pub const Order = enum {
    keyAscending, // reverse alphabetical
    keyDescending, // alphabetical
    valueAscending, // smallest to largest count
    valueDescending, // largest to smallest count
};

pub const KV = struct {
    key: []const u8,
    value: u64,
};

const OrderContext = struct {
    const Self = @This();
    order: Order,
    items: []KV,

    pub fn lessThan(self: Self, a: usize, b: usize) bool {
        return switch (self.order) {
            .keyAscending => return std.mem.lessThan(u8, self.items[a].key, self.items[b].key),
            .keyDescending => return std.mem.lessThan(u8, self.items[b].key, self.items[a].key),
            .valueAscending => return self.items[a].value < self.items[b].value,
            .valueDescending => return self.items[a].value > self.items[b].value,
        };
    }

    pub fn swap(self: Self, a: usize, b: usize) void {
        return std.mem.swap(KV, &self.items[a], &self.items[b]);
    }
};

/// Caller owns memory returned.
/// Takes an iterator of enum,val entries, and sorts them into an list of []u8,val pairs.
pub fn sortEnumIterator(allocator: std.mem.Allocator, iterator: anytype, order: Order) ![]KV {
    var list = std.ArrayList(KV).init(allocator);
    defer list.deinit();

    while (iterator.next()) |entry| {
        if (entry.value.* > 0)
            try list.append(.{ .key = @tagName(entry.key), .value = entry.value.* });
    }

    std.sort.pdqContext(0, list.items.len, OrderContext{ .items = list.items, .order = order });

    return try list.toOwnedSlice();
}

/// Caller owns memory returned.
/// Takes an iterator of []u8,val entries, and sorts them into an list of []u8,val pairs.
pub fn sortStringIterator(allocator: std.mem.Allocator, iterator: anytype, order: Order) ![]KV {
    var list = std.ArrayList(KV).init(allocator);
    defer list.deinit();

    while (iterator.next()) |entry| {
        if (entry.value_ptr.* > 0)
            try list.append(.{ .key = entry.key_ptr.*, .value = entry.value_ptr.* });
    }

    std.sort.pdqContext(0, list.items.len, OrderContext{ .items = list.items, .order = order });

    return try list.toOwnedSlice();
}

test "OrderBy .value K:[]const u8" {
    const allocator = std.testing.allocator;
    var hash_map = std.StringHashMap(u32).init(allocator);
    defer hash_map.deinit();
    try hash_map.put("c", 1);
    try hash_map.put("a", 10);
    try hash_map.put("b", 255);

    {
        var iterator = hash_map.iterator();
        const items = try sortStringIterator(allocator, &iterator, .valueDescending);
        defer allocator.free(items);

        try std.testing.expectEqual(255, items[0].value);
        try std.testing.expectEqual(10, items[1].value);
        try std.testing.expectEqual(1, items[2].value);
        try std.testing.expectEqual(3, items.len);
    }
    {
        var iterator = hash_map.iterator();
        const items = try sortStringIterator(allocator, &iterator, .valueAscending);
        defer allocator.free(items);

        try std.testing.expectEqual(1, items[0].value);
        try std.testing.expectEqual(10, items[1].value);
        try std.testing.expectEqual(255, items[2].value);
        try std.testing.expectEqual(3, items.len);
    }
}

test "OrderBy .key K:[]const u8" {
    const allocator = std.testing.allocator;
    var hash_map = std.StringHashMap(u32).init(allocator);
    defer hash_map.deinit();
    try hash_map.put("c", 1);
    try hash_map.put("a", 10);
    try hash_map.put("b", 255);

    {
        var iterator = hash_map.iterator();
        const items = try sortStringIterator(allocator, &iterator, .keyDescending);
        defer allocator.free(items);

        try std.testing.expectEqualStrings("c", items[0].key);
        try std.testing.expectEqualStrings("b", items[1].key);
        try std.testing.expectEqualStrings("a", items[2].key);
        try std.testing.expectEqual(3, items.len);
    }
    {
        var iterator = hash_map.iterator();
        const items = try sortStringIterator(allocator, &iterator, .keyAscending);
        defer allocator.free(items);

        try std.testing.expectEqualStrings("a", items[0].key);
        try std.testing.expectEqualStrings("b", items[1].key);
        try std.testing.expectEqualStrings("c", items[2].key);
        try std.testing.expectEqual(3, items.len);
    }
}

test "OrderBy .key K:enum" {
    const allocator = std.testing.allocator;
    var enum_array = std.EnumArray(std.fs.Dir.Entry.Kind, u32).initFill(0);
    enum_array.set(.file, 1);
    enum_array.set(.directory, 10);
    enum_array.set(.sym_link, 255);

    {
        var iterator = enum_array.iterator();
        const items = try sortEnumIterator(allocator, &iterator, .keyAscending);
        defer allocator.free(items);

        try std.testing.expectEqualStrings("directory", items[0].key);
        try std.testing.expectEqualStrings("file", items[1].key);
        try std.testing.expectEqualStrings("sym_link", items[2].key);
        try std.testing.expectEqual(3, items.len);
    }
    {
        var iterator = enum_array.iterator();
        const items = try sortEnumIterator(allocator, &iterator, .keyDescending);
        defer allocator.free(items);

        try std.testing.expectEqualStrings("sym_link", items[0].key);
        try std.testing.expectEqualStrings("file", items[1].key);
        try std.testing.expectEqualStrings("directory", items[2].key);
        try std.testing.expectEqual(3, items.len);
    }
}
