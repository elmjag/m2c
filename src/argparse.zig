const std = @import("std");
const eql = std.mem.eql;
const log = std.log;
const print = std.debug.print;
const process = std.process;

const Allocator = std.mem.Allocator;

pub const Commands = enum { info, run };
const Args = struct {
    command: Commands,
    params: [][]const u8,
};

pub fn parseArgs(allocator: Allocator) !Args {
    const args = try process.argsAlloc(allocator);
    log.info("invoked with: {s}", .{args});

    var command: ?Commands = null;

    if (eql(u8, args[1], "info")) {
        command = Commands.info;
    } else if (eql(u8, args[1], "run")) {
        command = Commands.run;
    } else {
        unreachable;
    }

    return Args{
        .command = command.?,
        .params = args[2..],
    };
}
