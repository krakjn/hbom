const std = @import("std");
const output = @import("../output.zig");

const SYS_BLOCK = "/sys/block";

fn readBlockFile(allocator: std.mem.Allocator, base: []const u8, name: []const u8) ?[]const u8 {
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

pub fn detect(allocator: std.mem.Allocator) ![]const output.BlockDevice {
    var dir = std.fs.openDirAbsolute(SYS_BLOCK, .{ .iterate = true }) catch return &.{};
    defer dir.close();

    var list = std.ArrayList(output.BlockDevice).empty;
    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory and entry.kind != .sym_link) continue;
        const name = entry.name;
        if (name.len == 0 or name[0] == '.') continue;

        var base_buf: [256]u8 = undefined;
        const base_path = std.fmt.bufPrint(&base_buf, "{s}/{s}", .{ SYS_BLOCK, name }) catch continue;

        const dev_name = allocator.dupe(u8, name) catch continue;
        const model = readBlockFile(allocator, base_path, "device/model");
        const serial = readBlockFile(allocator, base_path, "device/serial");
        const size = readBlockFile(allocator, base_path, "size");
        var size_str: ?[]const u8 = null;
        if (size) |s| {
            const n = std.fmt.parseInt(u64, s, 10) catch null;
            if (n) |val| {
                size_str = std.fmt.allocPrint(allocator, "{d}", .{val * 512}) catch null;
            }
        }
        const transport = readBlockFile(allocator, base_path, "device/transport");

        list.append(allocator, .{
            .name = dev_name,
            .model = model,
            .serial = serial,
            .size = size_str,
            .transport = transport,
        }) catch break;
    }
    return try list.toOwnedSlice(allocator);
}
