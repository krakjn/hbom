const std = @import("std");
const output = @import("../output.zig");

const SYS_THERMAL = "/sys/class/thermal";

fn readSys(allocator: std.mem.Allocator, base: []const u8, name: []const u8) ?[]const u8 {
    var path_buf: [512]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ base, name }) catch return null;
    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();
    const content = file.readToEndAlloc(allocator, 128) catch return null;
    const trimmed = std.mem.trim(u8, content, &std.ascii.whitespace);
    if (trimmed.len == 0) {
        allocator.free(content);
        return null;
    }
    return trimmed;
}

pub fn detect(allocator: std.mem.Allocator) ![]const output.ThermalZone {
    var dir = std.fs.openDirAbsolute(SYS_THERMAL, .{ .iterate = true }) catch return &.{};
    defer dir.close();

    var list = std.ArrayList(output.ThermalZone).empty;
    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory and entry.kind != .sym_link) continue;
        const name = entry.name;
        if (name.len < 13 or !std.mem.startsWith(u8, name, "thermal_zone")) continue;

        var base_buf: [256]u8 = undefined;
        const base_path = std.fmt.bufPrint(&base_buf, "{s}/{s}", .{ SYS_THERMAL, name }) catch continue;

        const zone_name = allocator.dupe(u8, name) catch continue;
        const zone_type = readSys(allocator, base_path, "type");
        const temp = readSys(allocator, base_path, "temp");

        list.append(allocator, .{
            .name = zone_name,
            .type = zone_type,
            .temp = temp,
        }) catch break;
    }
    return try list.toOwnedSlice(allocator);
}
