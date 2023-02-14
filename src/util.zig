const std = @import("std");
const Allocator = std.mem.Allocator;
const ChildProcess = std.ChildProcess;

pub fn runCommand(args: []const []const u8, allocator: Allocator) ![]u8 {
    const res = try ChildProcess.exec(.{
        .allocator = allocator,
        .argv = args,
    });

    return res.stdout;
}
