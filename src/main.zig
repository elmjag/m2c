const std = @import("std");

const argparse = @import("argparse.zig");
const parseArgs = argparse.parseArgs;
const doInfoCommand = @import("info.zig").doInfoCommand;

const Logger = @import("log.zig").Logger;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alct = gpa.allocator();

var logger: ?Logger = null;

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = level;
    _ = scope;

    // init our custom logger
    if (logger == null) {
        logger = Logger.init();
    }

    // pass all logging to our custom logger's log 'method'
    logger.?.log(format, args);
}

pub fn main() !void {
    const Commands = argparse.Commands;
    const args = try parseArgs(alct);

    switch (args.command) {
        Commands.run => {
            std.log.info("RUN\n", .{});
        },
        Commands.info => {
            try doInfoCommand(alct);
        },
    }
}
