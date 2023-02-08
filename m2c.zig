const std = @import("std");
const fs = std.fs;
const json = std.json;
const print = std.debug.print;
const process = std.process;

const ArrayList = std.ArrayList;
const File = std.fs.File;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alct = gpa.allocator();

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

fn runCommand(args: []const []const u8) ![]u8 {
    const res = try std.ChildProcess.exec(.{
        .allocator = alct,
        .argv = args,
    });

    return res.stdout;
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
    // run micromamba command
    const args = [_][]const u8{ "micromamba", "--json", "env", "list" };
    var jsonStr = try runCommand(&args);

    // parse micromamba json output
    var parser = std.json.Parser.init(alct, false);
    var tree = try parser.parse(jsonStr);
    var envsDict = tree.root.Object.get("envs").?;

    // convert envs json dict to list of strings
    var envs = ArrayList([]const u8).init(alct);
    for (envsDict.Array.items) |item| {
        try envs.append(item.String);
    }

    return envs.items;
}

fn getEnvironmentsDirs() ![][]const u8 {
    // run micromamba command
    const args = [_][]const u8{ "micromamba", "--json", "config", "list" };
    var jsonStr = try runCommand(&args);

    // parse micromamba json output
    var parser = std.json.Parser.init(alct, false);
    var tree = try parser.parse(jsonStr);
    var envsDirsDict = tree.root.Object.get("envs_dirs").?;

    // convert envs json dict to list of strings
    var envs = ArrayList([]const u8).init(alct);
    for (envsDirsDict.Array.items) |item| {
        try envs.append(item.String);
    }

    return envs.items;
}

fn getBaseEnvPath() ![]const u8 {
    // run micromamba command
    const args = [_][]const u8{ "micromamba", "--json", "info" };
    var jsonStr = try runCommand(&args);

    // parse micromamba json output
    var parser = std.json.Parser.init(alct, false);
    var tree = try parser.parse(jsonStr);
    var baseEnvPath = tree.root.Object.get("base environment").?;

    return baseEnvPath.String;
}

fn writeCondaInfoJson(envs: [][]const u8, envsDirs: [][]const u8, baseEnvPath: []const u8) !void {
    const CondaInfo = struct {
        conda_prefix: []const u8,
        envs: [][]const u8,
        envs_dirs: [][]const u8,
    };

    const condaInfo = CondaInfo{
        .conda_prefix = baseEnvPath,
        .envs = envs,
        .envs_dirs = envsDirs,
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
    var envsDir = try getEnvironmentsDirs();
    var baseEnvPath = try getBaseEnvPath();

    try writeCondaInfoJson(envs, envsDir, baseEnvPath);
}
