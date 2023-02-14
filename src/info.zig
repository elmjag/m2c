const std = @import("std");
const json = std.json;

const runCommand = @import("util.zig").runCommand;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn getEnvironments(allocator: Allocator) ![][]const u8 {
    // run micromamba command
    const args = [_][]const u8{ "micromamba", "--json", "env", "list" };
    var jsonStr = try runCommand(&args, allocator);

    // parse micromamba json output
    var parser = json.Parser.init(allocator, false);
    var tree = try parser.parse(jsonStr);
    var envsDict = tree.root.Object.get("envs").?;

    // convert envs json dict to list of strings
    var envs = ArrayList([]const u8).init(allocator);
    for (envsDict.Array.items) |item| {
        try envs.append(item.String);
    }

    return envs.items;
}

fn getEnvironmentsDirs(allocator: Allocator) ![][]const u8 {
    // run micromamba command
    const args = [_][]const u8{ "micromamba", "--json", "config", "list" };
    var jsonStr = try runCommand(&args, allocator);

    // parse micromamba json output
    var parser = json.Parser.init(allocator, false);
    var tree = try parser.parse(jsonStr);
    var envsDirsDict = tree.root.Object.get("envs_dirs").?;

    // convert envs json dict to list of strings
    var envs = ArrayList([]const u8).init(allocator);
    for (envsDirsDict.Array.items) |item| {
        try envs.append(item.String);
    }

    return envs.items;
}

fn getBaseEnvPath(allocator: Allocator) ![]const u8 {
    // run micromamba command
    const args = [_][]const u8{ "micromamba", "--json", "info" };
    var jsonStr = try runCommand(&args, allocator);

    // parse micromamba json output
    var parser = json.Parser.init(allocator, false);
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

pub fn doInfoCommand(allocator: Allocator) !void {
    var envs = try getEnvironments(allocator);
    var envsDir = try getEnvironmentsDirs(allocator);
    var baseEnvPath = try getBaseEnvPath(allocator);

    try writeCondaInfoJson(envs, envsDir, baseEnvPath);
}
