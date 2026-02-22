const std = @import("std");
const output = @import("../output.zig");

const SYS_ACPI = "/sys/bus/acpi/devices";

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

pub fn detect(allocator: std.mem.Allocator) ![]const output.AcpiDevice {
    var dir = std.fs.openDirAbsolute(SYS_ACPI, .{ .iterate = true }) catch return &.{};
    defer dir.close();

    var list = std.ArrayList(output.AcpiDevice).empty;
    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory and entry.kind != .sym_link) continue;
        const name = entry.name;
        if (name.len == 0 or name[0] == '.') continue;

        var base_buf: [256]u8 = undefined;
        const base_path = std.fmt.bufPrint(&base_buf, "{s}/{s}", .{ SYS_ACPI, name }) catch continue;

        const dev_name = allocator.dupe(u8, name) catch continue;
        const status = readSys(allocator, base_path, "status");

        list.append(allocator, .{
            .name = dev_name,
            .status = status,
        }) catch break;
    }
    return try list.toOwnedSlice(allocator);
}
