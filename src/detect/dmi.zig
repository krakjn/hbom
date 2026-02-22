const std = @import("std");
const output = @import("../output.zig");

const DMI_PATHS = [_][]const u8{
    "/sys/devices/virtual/dmi/id",
    "/sys/class/dmi/id",
};

fn readDmiFile(allocator: std.mem.Allocator, base: []const u8, name: []const u8) ?[]const u8 {
    var path_buf: [256]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ base, name }) catch return null;
    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();
    const content = file.readToEndAlloc(allocator, 4096) catch return null;
    const trimmed = std.mem.trim(u8, content, &std.ascii.whitespace);
    if (trimmed.len == 0) {
        allocator.free(content);
        return null;
    }
    return trimmed;
}

fn readDmiField(allocator: std.mem.Allocator, name: []const u8) ?[]const u8 {
    for (DMI_PATHS) |base| {
        if (readDmiFile(allocator, base, name)) |s| return s;
    }
    return null;
}

pub fn detectHost(allocator: std.mem.Allocator) !output.Host {
    var h = output.Host{};
    h.name = readDmiField(allocator, "product_name");
    h.vendor = readDmiField(allocator, "sys_vendor");
    h.serial = readDmiField(allocator, "product_serial");
    h.uuid = readDmiField(allocator, "product_uuid");
    return h;
}

pub fn detectBoard(allocator: std.mem.Allocator) !output.Board {
    var b = output.Board{};
    b.name = readDmiField(allocator, "board_name");
    b.vendor = readDmiField(allocator, "board_vendor");
    b.version = readDmiField(allocator, "board_version");
    b.serial = readDmiField(allocator, "board_serial");
    return b;
}

pub fn detectBios(allocator: std.mem.Allocator) !output.Bios {
    var b = output.Bios{};
    b.vendor = readDmiField(allocator, "bios_vendor");
    b.version = readDmiField(allocator, "bios_version");
    b.date = readDmiField(allocator, "bios_date");
    return b;
}

pub fn detectChassis(allocator: std.mem.Allocator) !output.Chassis {
    var c = output.Chassis{};
    c.type = readDmiField(allocator, "chassis_type");
    c.vendor = readDmiField(allocator, "chassis_vendor");
    c.serial = readDmiField(allocator, "chassis_serial");
    return c;
}
