const std = @import("std");
const output = @import("../output.zig");

const MEMINFO = "/proc/meminfo";

fn readFile(allocator: std.mem.Allocator, path: []const u8) ?[]const u8 {
    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();
    const content = file.readToEndAlloc(allocator, 8192) catch return null;
    if (content.len == 0) {
        allocator.free(content);
        return null;
    }
    return content;
}

fn parseMeminfo(content: []const u8, key: []const u8) ?[]const u8 {
    var iter = std.mem.splitScalar(u8, content, '\n');
    while (iter.next()) |line| {
        if (std.mem.startsWith(u8, line, key) and line.len > key.len) {
            var rest = std.mem.trim(u8, line[key.len..], &std.ascii.whitespace);
            if (std.mem.indexOf(u8, rest, " ")) |space| rest = rest[0..space];
            return rest;
        }
    }
    return null;
}

pub fn detect(allocator: std.mem.Allocator) !output.Memory {
    var result = output.Memory{};
    const content = readFile(allocator, MEMINFO) orelse return result;
    defer allocator.free(content);

    const total = parseMeminfo(content, "MemTotal:");
    if (total) |s| result.total_kb = allocator.dupe(u8, s) catch null;
    const avail = parseMeminfo(content, "MemAvailable:");
    if (avail) |s| result.available_kb = allocator.dupe(u8, s) catch null;
    return result;
}
