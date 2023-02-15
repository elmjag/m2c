const std = @import("std");

const runCommand = @import("util.zig").runCommand;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn doRunCommand(params: [][]const u8, allocator: Allocator) !void {
    var args = ArrayList([]const u8).init(allocator);
    try args.append("micromamba");
    try args.append("run");
    try args.append("--name");
    try args.append(params[1]);
    for (params[3..]) |param| {
        try args.append(param);
    }

    const res = try runCommand(args.items, allocator);
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}", .{res});
}
