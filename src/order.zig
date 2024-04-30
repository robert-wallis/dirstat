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

//
const ContextKeyAsc = struct {
    const Self = @This();
    items: []KV,
    pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
        return std.mem.lessThan(u8, ctx.items[a].key, ctx.items[b].key);
    }

    pub fn swap(ctx: @This(), a: usize, b: usize) void {
        return std.mem.swap(KV, &ctx.items[a], &ctx.items[b]);
    }
};

const ContextKeyDesc = struct {
    const Self = @This();
    items: []KV,
    pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
        return std.mem.lessThan(u8, ctx.items[b].key, ctx.items[a].key); // backwards on purpose to do descending
    }

    pub fn swap(ctx: @This(), a: usize, b: usize) void {
        return std.mem.swap(KV, &ctx.items[a], &ctx.items[b]);
    }
};

const ContextValueAsc = struct {
    const Self = @This();
    items: []KV,
    pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
        return ctx.items[a].value < ctx.items[b].value;
    }

    pub fn swap(ctx: @This(), a: usize, b: usize) void {
        return std.mem.swap(KV, &ctx.items[a], &ctx.items[b]);
    }
};

const ContextValueDesc = struct {
    const Self = @This();
    items: []KV,
    pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
        return ctx.items[a].value > ctx.items[b].value;
    }

    pub fn swap(ctx: @This(), a: usize, b: usize) void {
        return std.mem.swap(KV, &ctx.items[a], &ctx.items[b]);
    }
};

const ContextUnion = union(Order) {
    const Self = @This();

    keyAscending: ContextKeyAsc,
    keyDescending: ContextKeyDesc,
    valueAscending: ContextValueAsc,
    valueDescending: ContextValueDesc,

    fn fromOrder(order: Order, items: []KV) ContextUnion {
        return switch (order) {
            .keyAscending => .{ .keyAscending = ContextKeyAsc{ .items = items } },
            .keyDescending => .{ .keyDescending = ContextKeyDesc{ .items = items } },
            .valueAscending => .{ .valueAscending = ContextValueAsc{ .items = items } },
            .valueDescending => .{ .valueDescending = ContextValueDesc{ .items = items } },
        };
    }

    pub fn lessThan(self: Self, a: usize, b: usize) bool {
        return switch (self) {
            .keyAscending => |c| c.lessThan(a, b),
            .keyDescending => |c| c.lessThan(a, b),
            .valueAscending => |c| c.lessThan(a, b),
            .valueDescending => |c| c.lessThan(a, b),
        };
    }

    pub fn swap(self: Self, a: usize, b: usize) void {
        return switch (self) {
            .keyAscending => |c| c.swap(a, b),
            .keyDescending => |c| c.swap(a, b),
            .valueAscending => |c| c.swap(a, b),
            .valueDescending => |c| c.swap(a, b),
        };
    }
};

pub fn sortEnumIterator(allocator: std.mem.Allocator, iterator: anytype, order: Order) ![]KV {
    var list = std.ArrayList(KV).init(allocator);
    defer list.deinit();

    while (iterator.next()) |entry| {
        if (entry.value.* > 0)
            try list.append(.{ .key = @tagName(entry.key), .value = entry.value.* });
    }

    const ctx = ContextUnion.fromOrder(order, list.items);
    std.sort.pdqContext(0, list.items.len, ctx);

    return try list.toOwnedSlice();
}

pub fn sortStringIterator(allocator: std.mem.Allocator, iterator: anytype, order: Order) ![]KV {
    var list = std.ArrayList(KV).init(allocator);
    defer list.deinit();

    while (iterator.next()) |entry| {
        if (entry.value_ptr.* > 0)
            try list.append(.{ .key = entry.key_ptr.*, .value = entry.value_ptr.* });
    }

    const ctx = ContextUnion.fromOrder(order, list.items);
    std.sort.pdqContext(0, list.items.len, ctx);

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
