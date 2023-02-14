const std = @import("std");
const fs = std.fs;

const File = std.fs.File;

const LOG_FILE_PATH = "/tmp/m2c";

fn fileExists(path: [*:0]const u8) bool {
    var res = std.c.access(path, std.os.F_OK);
    return res != -1;
}

fn openLogFile() !File {
    if (fileExists(LOG_FILE_PATH)) {
        var file = try fs.openFileAbsolute(LOG_FILE_PATH, .{ .mode = .write_only });
        try file.seekFromEnd(0);
        return file;
    }

    // log file does not exist
    return try fs.createFileAbsolute(LOG_FILE_PATH, .{ .read = true });
}

fn logToStderr(comptime format: []const u8, args: anytype) void {
    std.debug.print(format, args);
}

pub const Logger = struct {
    log_file: ?File,

    pub fn init() Logger {
        const log_file = openLogFile() catch null;

        if (log_file == null) {
            logToStderr("failed to open log file '{s}', will log to stderr.\n", .{LOG_FILE_PATH});
        }

        return Logger{
            .log_file = log_file,
        };
    }

    pub fn log(self: Logger, comptime format: []const u8, args: anytype) void {
        const formatLn = format ++ "<--\n";
        if (self.log_file) |log_file| {
            log_file.writer().print(formatLn, args) catch {
                logToStderr(formatLn, args);
            };
            return;
        }

        logToStderr(formatLn, args);
    }
};
