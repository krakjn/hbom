const std = @import("std");
const output = @import("../output.zig");

const SYS_PLATFORM = "/sys/bus/platform/devices";

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

pub fn detect(allocator: std.mem.Allocator) ![]const output.PlatformDevice {
    var dir = std.fs.openDirAbsolute(SYS_PLATFORM, .{ .iterate = true }) catch return &.{};
    defer dir.close();

    var list = std.ArrayList(output.PlatformDevice).empty;
    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory and entry.kind != .sym_link) continue;
        const name = entry.name;
        if (name.len == 0 or name[0] == '.') continue;

        var base_buf: [256]u8 = undefined;
        const base_path = std.fmt.bufPrint(&base_buf, "{s}/{s}", .{ SYS_PLATFORM, name }) catch continue;

        const dev_name = allocator.dupe(u8, name) catch continue;
        var driver_path_buf: [320]u8 = undefined;
        const driver_path = std.fmt.bufPrint(&driver_path_buf, "{s}/driver", .{base_path}) catch continue;
        var driver: ?[]const u8 = null;
        var link_buf: [256]u8 = undefined;
        if (std.posix.readlink(driver_path, &link_buf)) |link_slice| {
            driver = allocator.dupe(u8, link_slice) catch null;
        } else |_| {}
        const modalias = readSys(allocator, base_path, "modalias");

        list.append(allocator, .{
            .name = dev_name,
            .driver = driver,
            .modalias = modalias,
        }) catch break;
    }
    return try list.toOwnedSlice(allocator);
}
