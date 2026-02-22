const std = @import("std");
const output = @import("../output.zig");
const c = @cImport({
    @cInclude("unistd.h");
});

const SYS_NET = "/sys/class/net";

fn readSys(allocator: std.mem.Allocator, base: []const u8, name: []const u8) ?[]const u8 {
    var path_buf: [512]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ base, name }) catch return null;
    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();
    var buf: [256]u8 = undefined;
    const n = c.read(file.handle, buf[0..].ptr, buf.len);
    if (n <= 0) return null;
    const trimmed = std.mem.trim(u8, buf[0..@as(usize, @intCast(n))], &std.ascii.whitespace);
    if (trimmed.len == 0) return null;
    return allocator.dupe(u8, trimmed) catch null;
}

pub fn detect(allocator: std.mem.Allocator) ![]const output.NetIface {
    var dir = std.fs.openDirAbsolute(SYS_NET, .{ .iterate = true }) catch return &.{};
    defer dir.close();

    var list = std.ArrayList(output.NetIface).empty;
    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory and entry.kind != .sym_link) continue;
        const name = entry.name;
        if (name.len == 0 or name[0] == '.') continue;

        var base_buf: [256]u8 = undefined;
        const base_path = std.fmt.bufPrint(&base_buf, "{s}/{s}", .{ SYS_NET, name }) catch continue;

        const dev_name = allocator.dupe(u8, name) catch continue;
        var addr = readSys(allocator, base_path, "address");
        if (addr == null) addr = readSys(allocator, base_path, "device/address");
        const iface_type = readSys(allocator, base_path, "type");
        const operstate = readSys(allocator, base_path, "operstate");
        const speed = readSys(allocator, base_path, "speed");

        list.append(allocator, .{
            .name = dev_name,
            .address = addr,
            .type = iface_type,
            .operstate = operstate,
            .speed = speed,
        }) catch break;
    }
    return try list.toOwnedSlice(allocator);
}
