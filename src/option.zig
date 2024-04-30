// Copyright (C) 2024 Robert A. Wallis, all rights reserved.
const std = @import("std");
const order = @import("order.zig");

pub const Options = struct {
    order_by: order.Order,
    human_readable_bytes: bool,
    paths: std.ArrayList([]const u8),
};

/// caller owns Options.paths
pub fn parse(allocator: std.mem.Allocator, arg_iterator: anytype) !Options {
    var arg_idx: usize = 0;
    var options: Options = .{ .order_by = .valueDescending, .human_readable_bytes = true, .paths = std.ArrayList([]const u8).init(allocator) };
    while (arg_iterator.next()) |arg| {
        if (std.mem.eql(u8, "--", arg[0..2])) {
            if (std.mem.eql(u8, "key-asc", arg[2..])) {
                options.order_by = .keyAscending;
            } else if (std.mem.eql(u8, "key-desc", arg[2..])) {
                options.order_by = .keyDescending;
            } else if (std.mem.eql(u8, "key", arg[2..])) {
                options.order_by = .keyAscending;
            } else if (std.mem.eql(u8, "value-asc", arg[2..])) {
                options.order_by = .valueAscending;
            } else if (std.mem.eql(u8, "value-desc", arg[2..])) {
                options.order_by = .valueDescending;
            } else if (std.mem.eql(u8, "value", arg[2..])) {
                options.order_by = .valueDescending;
            } else if (std.mem.eql(u8, "bytes", arg[2..])) {
                options.human_readable_bytes = false;
            } else {
                try usage();
                std.process.exit(1);
                return;
            }
        } else if ('-' == arg[0]) {
            var found_arg = false;
            if (std.mem.indexOf(u8, arg, "k") != null) {
                if (std.mem.indexOf(u8, arg, "a") != null) {
                    options.order_by = .keyAscending;
                } else if (std.mem.indexOf(u8, arg, "d") != null) {
                    options.order_by = .keyDescending;
                } else {
                    options.order_by = .keyAscending;
                }
                found_arg = true;
            } else if (std.mem.indexOf(u8, arg, "v") != null) {
                if (std.mem.indexOf(u8, arg, "a") != null) {
                    options.order_by = .valueAscending;
                } else if (std.mem.indexOf(u8, arg, "d") != null) {
                    options.order_by = .valueDescending;
                } else {
                    options.order_by = .valueAscending;
                }
                found_arg = true;
            }
            if (std.mem.indexOf(u8, arg, "b") != null) {
                options.human_readable_bytes = false;
                found_arg = true;
            }
            if (!found_arg) {
                try usage();
                std.process.exit(1);
                return;
            }
        } else if (arg_idx > 0) {
            try options.paths.append(arg);
        }
        arg_idx += 1;
    }

    if (options.paths.items.len == 0) {
        try options.paths.append("."); // default to this folder
    }

    return options;
}

test "parse default" {
    var it = try std.process.ArgIteratorGeneral(.{}).init(std.testing.allocator, "/tmp/dirstat");
    defer it.deinit();

    const options = try parse(std.testing.allocator, &it);
    defer options.paths.deinit();

    try std.testing.expectEqual(options.order_by, .valueDescending);
    try std.testing.expectEqual(options.human_readable_bytes, true);
    try std.testing.expectEqualSlices([]const u8, &.{&".".*}, options.paths.items);
}

test "parse many paths" {
    var it = try std.process.ArgIteratorGeneral(.{}).init(std.testing.allocator, "/tmp/dirstat many paths");
    defer it.deinit();

    const options = try parse(std.testing.allocator, &it);
    defer options.paths.deinit();

    try std.testing.expectEqual(options.order_by, .valueDescending);
    try std.testing.expectEqual(options.human_readable_bytes, true);
    try std.testing.expectEqualStrings("many", options.paths.items[0]);
    try std.testing.expectEqualStrings("paths", options.paths.items[1]);
    try std.testing.expectEqual(2, options.paths.items.len);
}

test "parse -vab many paths" {
    var it = try std.process.ArgIteratorGeneral(.{}).init(std.testing.allocator, "/tmp/dirstat -vab many paths");
    defer it.deinit();

    const options = try parse(std.testing.allocator, &it);
    defer options.paths.deinit();

    try std.testing.expectEqual(options.order_by, .valueAscending);
    try std.testing.expectEqual(options.human_readable_bytes, false);
    try std.testing.expectEqualStrings("many", options.paths.items[0]);
    try std.testing.expectEqualStrings("paths", options.paths.items[1]);
    try std.testing.expectEqual(2, options.paths.items.len);
}

test "parse -kd --bytes many paths" {
    var it = try std.process.ArgIteratorGeneral(.{}).init(std.testing.allocator, "/tmp/dirstat -kd --bytes many paths");
    defer it.deinit();

    const options = try parse(std.testing.allocator, &it);
    defer options.paths.deinit();

    try std.testing.expectEqual(options.order_by, .keyDescending);
    try std.testing.expectEqual(options.human_readable_bytes, false);
    try std.testing.expectEqualStrings("many", options.paths.items[0]);
    try std.testing.expectEqualStrings("paths", options.paths.items[1]);
    try std.testing.expectEqual(2, options.paths.items.len);
}

fn usage() !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print("usage:\tdirstat [-k][-v][-a][-d] [path [path ...]]\n", .{});
    try stderr.print("\t-k --key\tsort by key\n", .{});
    try stderr.print("\t        \tkey is sorted by alphabetically unless -d is used\n", .{});
    try stderr.print("\t-v --value\tsort by Value\n", .{});
    try stderr.print("\t          \tvalue is the default sort\n", .{});
    try stderr.print("\t          \tvalue is sorted by largest to smallest unless -a is used\n", .{});
    try stderr.print("\t-a --key-asc --value-asc\tsort by value acending, lowest to highest\n", .{});
    try stderr.print("\t-d --value-desc --value-desc\tsort by value descending, highest to lowest\n", .{});
    try stderr.print("\t-b --bytes\toutput just bytes, 1048576 is shown instead of 1M\n", .{});
}
