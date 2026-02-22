const std = @import("std");
const output = @import("../output.zig");

const INPUT_CLASS = "/sys/class/input";

fn readInputFile(allocator: std.mem.Allocator, base: []const u8, name: []const u8) ?[]const u8 {
    var path_buf: [512]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ base, name }) catch return null;
    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();
    const content = file.readToEndAlloc(allocator, 256) catch return null;
    const trimmed = std.mem.trim(u8, content, &std.ascii.whitespace);
    if (trimmed.len == 0) {
        allocator.free(content);
        return null;
    }
    return trimmed;
}

pub fn detect(allocator: std.mem.Allocator) ![]const output.InputDevice {
    var dir = std.fs.openDirAbsolute(INPUT_CLASS, .{ .iterate = true }) catch return &.{};
    defer dir.close();

    var list = std.ArrayList(output.InputDevice).empty;
    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory) continue;
        const name = entry.name;
        if (name.len == 0 or !std.mem.startsWith(u8, name, "event")) continue;

        var base_buf: [256]u8 = undefined;
        const base_path = std.fmt.bufPrint(&base_buf, "{s}/{s}/device", .{ INPUT_CLASS, name }) catch continue;

        const dev_name = readInputFile(allocator, base_path, "name");
        const uniq = readInputFile(allocator, base_path, "uniq");
        if (dev_name == null and uniq == null) continue;

        list.append(allocator, .{
            .name = dev_name,
            .uniq = uniq,
        }) catch break;
    }
    return try list.toOwnedSlice(allocator);
}
