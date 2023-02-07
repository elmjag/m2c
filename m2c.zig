const std = @import("std");
const fs = std.fs;
const json = std.json;
const print = std.debug.print;
const process = std.process;

const ArrayList = std.ArrayList;
const File = std.fs.File;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alct = gpa.allocator();

const CondaInfo = struct {
    envs: [][]const u8,
};

const logFilePath = "/tmp/m2c";

fn fileExists(path: [*:0]const u8) bool {
    var res = std.c.access(path, std.os.F_OK);
    return res != -1;
}

fn openLogFile() !File {
    if (fileExists(logFilePath)) {
        var file = try fs.openFileAbsolute(logFilePath, .{ .mode = .write_only });
        try file.seekFromEnd(0);
        return file;
    }

    // log file does not exist
    return try fs.createFileAbsolute(logFilePath, .{ .read = true });
}

fn logCliArguments() !void {
    var file = try openLogFile();
    defer file.close();

    var args = process.args();
    while (args.next()) |arg| {
        try file.writeAll(arg);
        try file.writeAll(" ");
    }
    try file.writeAll("\n");
}

fn runMicromambaEnvs() ![]u8 {
    const args = [_][]const u8{ "micromamba", "--json", "env", "list" };

    const res = try std.ChildProcess.exec(.{
        .allocator = alct,
        .argv = &args,
    });

    return res.stdout;
}

fn getEnvironments() ![][]const u8 {
    var jsonStr = try runMicromambaEnvs();

    var parser = std.json.Parser.init(alct, false);
    var tree = try parser.parse(jsonStr);
    var envsDict = tree.root.Object.get("envs").?;

    var envs = ArrayList([]const u8).init(alct);

    for (envsDict.Array.items) |item| {
        try envs.append(item.String);
    }

    return envs.items;
}

fn writeCondaInfoJson(envs: [][]const u8) !void {
    const condaInfo = CondaInfo{
        .envs = envs,
    };

    const stdout = std.io.getStdOut().writer();
    const formatOptions = json.StringifyOptions{
        .whitespace = .{ .indent = .{ .Space = 2 } },
    };

    try json.stringify(condaInfo, formatOptions, stdout);
}

pub fn main() !void {
    try logCliArguments();
    var envs = try getEnvironments();

    try writeCondaInfoJson(envs);
}
