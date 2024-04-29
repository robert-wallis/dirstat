// Copyright (C) 2024 Robert A. Wallis, all rights reserved.
const std = @import("std");

pub const Order = enum {
    keyAscending, // reverse alphabetical
    keyDescending, // alphabetical
    valueAscending, // smallest to largest count
    valueDescending, // largest to smallest count
};

fn valueAscendingCompare(comptime KV: type) (fn (_: void, a: KV, b: KV) std.math.Order) {
    return struct {
        fn compare(_: void, a: KV, b: KV) std.math.Order {
            return std.math.order(a.value, b.value);
        }
    }.compare;
}

fn valueDescendingCompare(comptime KV: type) (fn (_: void, a: KV, b: KV) std.math.Order) {
    return struct {
        fn compare(_: void, a: KV, b: KV) std.math.Order {
            return std.math.order(b.value, a.value);
        }
    }.compare;
}

fn keyAscendingCompare(comptime KV: type) (fn (_: void, a: KV, b: KV) std.math.Order) {
    return struct {
        fn compare(_: void, a: KV, b: KV) std.math.Order {
            return std.mem.order(u8, a.key, b.key);
        }
    }.compare;
}

fn keyDescendingCompare(comptime KV: type) (fn (_: void, a: KV, b: KV) std.math.Order) {
    return struct {
        fn compare(_: void, a: KV, b: KV) std.math.Order {
            return std.mem.order(u8, b.key, a.key);
        }
    }.compare;
}

pub fn OrderBy(comptime V: type, order: Order) type {
    const KV = struct {
        key: []const u8,
        value: V,
    };

    const compareFn = switch (order) {
        .keyAscending => keyAscendingCompare(KV),
        .keyDescending => keyDescendingCompare(KV),
        .valueAscending => valueAscendingCompare(KV),
        .valueDescending => valueDescendingCompare(KV),
    };
    const CollectionPQ = std.PriorityQueue(KV, void, compareFn);

    return struct {
        const Self = @This();

        queue: CollectionPQ,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .queue = CollectionPQ.init(allocator, {}),
            };
        }

        pub fn add(self: *Self, key: []const u8, value: V) !void {
            try self.queue.add(.{ .key = key, .value = value });
        }

        pub fn addPtrIterator(self: *Self, iter: anytype) !void {
            while (iter.next()) |elem| {
                try self.add(elem.key_ptr.*, elem.value_ptr.*);
            }
        }

        pub fn deinit(self: Self) void {
            self.queue.deinit();
        }

        pub fn next(self: *Self) ?KV {
            return self.queue.removeOrNull();
        }
    };
}

test "OrderBy .value K:[]const u8" {
    const allocator = std.testing.allocator;
    var hash_map = std.StringHashMap(u32).init(allocator);
    defer hash_map.deinit();
    try hash_map.put("c", 1);
    try hash_map.put("a", 10);
    try hash_map.put("b", 255);

    {
        var ob = OrderBy(u32, .valueDescending).init(allocator);
        defer ob.deinit();

        var iter = hash_map.iterator();
        try ob.addPtrIterator(&iter);

        const a = ob.next();
        const b = ob.next();
        const c = ob.next();
        const d = ob.next();
        try std.testing.expectEqual(255, a.?.value);
        try std.testing.expectEqual(10, b.?.value);
        try std.testing.expectEqual(1, c.?.value);
        try std.testing.expectEqual(null, d);
    }
    {
        var ob = OrderBy(u32, .valueAscending).init(allocator);
        defer ob.deinit();

        var iter = hash_map.iterator();
        try ob.addPtrIterator(&iter);

        const a = ob.next();
        const b = ob.next();
        const c = ob.next();
        const d = ob.next();
        try std.testing.expectEqual(1, a.?.value);
        try std.testing.expectEqual(10, b.?.value);
        try std.testing.expectEqual(255, c.?.value);
        try std.testing.expectEqual(null, d);
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
        var ob = OrderBy(u32, .keyAscending).init(allocator);
        defer ob.deinit();

        var iter = hash_map.iterator();
        try ob.addPtrIterator(&iter);

        const a = ob.next();
        const b = ob.next();
        const c = ob.next();
        const d = ob.next();
        try std.testing.expectEqualStrings("a", a.?.key);
        try std.testing.expectEqualStrings("b", b.?.key);
        try std.testing.expectEqualStrings("c", c.?.key);
        try std.testing.expectEqual(null, d);
    }
    {
        var ob = OrderBy(u32, .keyDescending).init(allocator);
        defer ob.deinit();

        var iter = hash_map.iterator();
        try ob.addPtrIterator(&iter);

        const a = ob.next();
        const b = ob.next();
        const c = ob.next();
        const d = ob.next();
        try std.testing.expectEqualStrings("c", a.?.key);
        try std.testing.expectEqualStrings("b", b.?.key);
        try std.testing.expectEqualStrings("a", c.?.key);
        try std.testing.expectEqual(null, d);
    }
}

test "OrderBy .key K:enum" {
    const allocator = std.testing.allocator;
    var enum_array = std.EnumArray(std.fs.Dir.Entry.Kind, u32).initFill(0);
    enum_array.set(.file, 1);
    enum_array.set(.directory, 10);
    enum_array.set(.sym_link, 255);

    {
        var ob = OrderBy(u32, .keyAscending).init(allocator);
        defer ob.deinit();

        var iter = enum_array.iterator();
        while (iter.next()) |elem| {
            if (elem.value.* > 0)
                try ob.add(@tagName(elem.key), elem.value.*);
        }

        const a = ob.next();
        const b = ob.next();
        const c = ob.next();
        const d = ob.next();
        try std.testing.expectEqualStrings("directory", a.?.key);
        try std.testing.expectEqualStrings("file", b.?.key);
        try std.testing.expectEqualStrings("sym_link", c.?.key);
        try std.testing.expectEqual(null, d);
    }
    {
        var ob = OrderBy(u32, .keyDescending).init(allocator);
        defer ob.deinit();

        var iter = enum_array.iterator();
        while (iter.next()) |elem| {
            if (elem.value.* > 0)
                try ob.add(@tagName(elem.key), elem.value.*);
        }

        const a = ob.next();
        const b = ob.next();
        const c = ob.next();
        const d = ob.next();
        try std.testing.expectEqualStrings("sym_link", a.?.key);
        try std.testing.expectEqualStrings("file", b.?.key);
        try std.testing.expectEqualStrings("directory", c.?.key);
        try std.testing.expectEqual(null, d);
    }
}
