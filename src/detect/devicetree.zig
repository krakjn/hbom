const std = @import("std");
const output = @import("../output.zig");

const DT_BASE = "/sys/firmware/devicetree/base";

fn readDtFile(allocator: std.mem.Allocator, path: []const u8) ?[]const u8 {
    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();
    const content = file.readToEndAlloc(allocator, 4096) catch return null;
    const trimmed = std.mem.trim(u8, content, &std.ascii.whitespace);
    const trimmed2 = std.mem.trimRight(u8, trimmed, "\x00");
    if (trimmed2.len == 0) {
        allocator.free(content);
        return null;
    }
    return trimmed2;
}

pub fn detect(allocator: std.mem.Allocator) !output.Devicetree {
    var dt = output.Devicetree{};
    dt.model = readDtFile(allocator, DT_BASE ++ "/model");
    dt.serial_number = readDtFile(allocator, DT_BASE ++ "/serial-number");
    dt.compatible = readDtFile(allocator, DT_BASE ++ "/compatible");
    dt.board_compatible = readDtFile(allocator, DT_BASE ++ "/smbios/smbios/baseboard/product");
    if (dt.board_compatible == null) {
        dt.board_compatible = readDtFile(allocator, DT_BASE ++ "/board");
    }
    return dt;
}
