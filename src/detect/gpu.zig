const std = @import("std");
const output = @import("../output.zig");

const SYS_DRM = "/sys/class/drm";

fn readSys(allocator: std.mem.Allocator, base: []const u8, name: []const u8) ?[]const u8 {
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

pub fn detect(allocator: std.mem.Allocator) ![]const output.Gpu {
    var dir = std.fs.openDirAbsolute(SYS_DRM, .{ .iterate = true }) catch return &.{};
    defer dir.close();

    var list = std.ArrayList(output.Gpu).empty;
    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory and entry.kind != .sym_link) continue;
        const name = entry.name;
        if (name.len < 5 or !std.mem.startsWith(u8, name, "card")) continue;
        if (std.mem.indexOf(u8, name, "-")) |_| continue;

        var base_buf: [256]u8 = undefined;
        const base_path = std.fmt.bufPrint(&base_buf, "{s}/{s}", .{ SYS_DRM, name }) catch continue;
        var device_path_buf: [320]u8 = undefined;
        const device_path = std.fmt.bufPrint(&device_path_buf, "{s}/device", .{base_path}) catch continue;

        const card = allocator.dupe(u8, name) catch continue;
        const vendor = readSys(allocator, device_path, "vendor") orelse readSys(allocator, base_path, "device/vendor");
        const device = readSys(allocator, device_path, "device") orelse readSys(allocator, base_path, "device/device");
        const driver = readSys(allocator, device_path, "driver") orelse readSys(allocator, base_path, "device/driver");

        list.append(allocator, .{
            .card = card,
            .vendor = vendor,
            .device = device,
            .driver = driver,
        }) catch break;
    }
    return try list.toOwnedSlice(allocator);
}
