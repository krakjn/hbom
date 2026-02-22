const std = @import("std");
const output = @import("../output.zig");

const USB_DEVICES = "/sys/bus/usb/devices";

fn readUsbFile(allocator: std.mem.Allocator, base: []const u8, name: []const u8) ?[]const u8 {
    var path_buf: [512]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ base, name }) catch return null;
    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();
    const content = file.readToEndAlloc(allocator, 512) catch return null;
    const trimmed = std.mem.trim(u8, content, &std.ascii.whitespace);
    if (trimmed.len == 0) {
        allocator.free(content);
        return null;
    }
    return trimmed;
}

fn isUsbDeviceDir(name: []const u8) bool {
    if (name.len == 0 or name[0] == '.') return false;
    for (name) |c| {
        if (c == '-' or (c >= '0' and c <= '9')) continue;
        return false;
    }
    return true;
}

pub fn detect(allocator: std.mem.Allocator) ![]const output.UsbDevice {
    var dir = std.fs.openDirAbsolute(USB_DEVICES, .{ .iterate = true }) catch return &.{};
    defer dir.close();

    var list = std.ArrayList(output.UsbDevice).empty;
    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory) continue;
        const name = entry.name;
        if (!isUsbDeviceDir(name)) continue;

        var base_buf: [256]u8 = undefined;
        const base_path = std.fmt.bufPrint(&base_buf, "{s}/{s}", .{ USB_DEVICES, name }) catch continue;

        const product = readUsbFile(allocator, base_path, "product");
        const manufacturer = readUsbFile(allocator, base_path, "manufacturer");
        const serial = readUsbFile(allocator, base_path, "serial");
        if (product == null and manufacturer == null and serial == null) continue;

        const path = allocator.dupe(u8, name) catch continue;
        list.append(allocator, .{
            .path = path,
            .vendor = manufacturer,
            .product = product,
            .serial = serial,
        }) catch break;
    }
    return try list.toOwnedSlice(allocator);
}
