const std = @import("std");
const types = @import("../types.zig");
const common = @import("common.zig");

fn csvEscape(w: anytype, s: []const u8) !void {
    var need_quotes = false;
    for (s) |c| {
        if (c == '"' or c == ',' or c == '\n' or c == '\r') {
            need_quotes = true;
            break;
        }
    }
    if (need_quotes) try w.writeByte('"');
    for (s) |c| {
        if (c == '"') {
            try w.writeAll("\"\"");
        } else {
            try w.writeByte(c);
        }
    }
    if (need_quotes) try w.writeByte('"');
}

pub fn write(bom: *const types.Hbom, w: anytype) !void {
    try w.writeAll("section,key,value\n");
    const writeRow = struct {
        fn f(wa: anytype, sec: []const u8, key: []const u8, val: ?[]const u8) !void {
            if (val == null or val.?.len == 0) return;
            const v = if (common.isDmiPlaceholder(val.?)) "placeholder" else val.?;
            try wa.print("{s},", .{sec});
            try csvEscape(wa, key);
            try wa.writeAll(",");
            try csvEscape(wa, v);
            try wa.writeAll("\n");
        }
    }.f;
    if (bom.host.name != null or bom.host.vendor != null or bom.host.serial != null or bom.host.uuid != null) {
        try writeRow(w, "host", "name", bom.host.name);
        try writeRow(w, "host", "vendor", bom.host.vendor);
        try writeRow(w, "host", "serial", bom.host.serial);
        try writeRow(w, "host", "uuid", bom.host.uuid);
    }
    if (bom.board.name != null or bom.board.vendor != null or bom.board.version != null or bom.board.serial != null) {
        try writeRow(w, "board", "name", bom.board.name);
        try writeRow(w, "board", "vendor", bom.board.vendor);
        try writeRow(w, "board", "version", bom.board.version);
        try writeRow(w, "board", "serial", bom.board.serial);
    }
    if (bom.bios.vendor != null or bom.bios.version != null or bom.bios.date != null) {
        try writeRow(w, "bios", "vendor", bom.bios.vendor);
        try writeRow(w, "bios", "version", bom.bios.version);
        try writeRow(w, "bios", "date", bom.bios.date);
    }
    if (bom.chassis.type != null or bom.chassis.vendor != null or bom.chassis.serial != null) {
        try writeRow(w, "chassis", "type", bom.chassis.type);
        try writeRow(w, "chassis", "vendor", bom.chassis.vendor);
        try writeRow(w, "chassis", "serial", bom.chassis.serial);
    }
    if (bom.chipset) |s| try writeRow(w, "chipset", "chipset", s);
    for (bom.chipsets, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "chipsets.{d}", .{i}) catch continue;
        try writeRow(w, sec, "slot", d.slot);
        try writeRow(w, sec, "class", d.class);
        try writeRow(w, sec, "vendor", d.vendor);
        try writeRow(w, sec, "device", d.device);
        try writeRow(w, sec, "serial", d.serial);
    }
    for (bom.pci, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "pci.{d}", .{i}) catch continue;
        try writeRow(w, sec, "slot", d.slot);
        try writeRow(w, sec, "class", d.class);
        try writeRow(w, sec, "vendor", d.vendor);
        try writeRow(w, sec, "device", d.device);
        try writeRow(w, sec, "serial", d.serial);
    }
    for (bom.usb, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "usb.{d}", .{i}) catch continue;
        try writeRow(w, sec, "path", d.path);
        try writeRow(w, sec, "vendor", d.vendor);
        try writeRow(w, sec, "product", d.product);
        try writeRow(w, sec, "serial", d.serial);
    }
    for (bom.block, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "block.{d}", .{i}) catch continue;
        try writeRow(w, sec, "name", d.name);
        try writeRow(w, sec, "model", d.model);
        try writeRow(w, sec, "serial", d.serial);
        try writeRow(w, sec, "size", d.size);
        try writeRow(w, sec, "transport", d.transport);
    }
    for (bom.input, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "input.{d}", .{i}) catch continue;
        try writeRow(w, sec, "name", d.name);
        try writeRow(w, sec, "uniq", d.uniq);
    }
    for (bom.net, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "net.{d}", .{i}) catch continue;
        try writeRow(w, sec, "name", d.name);
        try writeRow(w, sec, "address", d.address);
        try writeRow(w, sec, "type", d.type);
        try writeRow(w, sec, "operstate", d.operstate);
        try writeRow(w, sec, "speed", d.speed);
    }
    if (bom.cpu.model_name != null or bom.cpu.vendor != null or bom.cpu.cores != null or bom.cpu.mhz != null) {
        try writeRow(w, "cpu", "model_name", bom.cpu.model_name);
        try writeRow(w, "cpu", "vendor", bom.cpu.vendor);
        try writeRow(w, "cpu", "cores", bom.cpu.cores);
        try writeRow(w, "cpu", "mhz", bom.cpu.mhz);
    }
    if (bom.memory.total_kb != null or bom.memory.available_kb != null) {
        try writeRow(w, "memory", "total_kb", bom.memory.total_kb);
        try writeRow(w, "memory", "available_kb", bom.memory.available_kb);
    }
    for (bom.sound, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "sound.{d}", .{i}) catch continue;
        try writeRow(w, sec, "id", d.id);
        try writeRow(w, sec, "name", d.name);
    }
    for (bom.gpu, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "gpu.{d}", .{i}) catch continue;
        try writeRow(w, sec, "card", d.card);
        try writeRow(w, sec, "vendor", d.vendor);
        try writeRow(w, sec, "device", d.device);
        try writeRow(w, sec, "driver", d.driver);
    }
    for (bom.thermal, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "thermal.{d}", .{i}) catch continue;
        try writeRow(w, sec, "name", d.name);
        try writeRow(w, sec, "type", d.type);
        try writeRow(w, sec, "temp", d.temp);
    }
    for (bom.power, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "power.{d}", .{i}) catch continue;
        try writeRow(w, sec, "name", d.name);
        try writeRow(w, sec, "type", d.type);
        try writeRow(w, sec, "status", d.status);
        try writeRow(w, sec, "capacity", d.capacity);
        try writeRow(w, sec, "manufacturer", d.manufacturer);
        try writeRow(w, sec, "model_name", d.model_name);
        try writeRow(w, sec, "serial", d.serial);
    }
    for (bom.platform, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "platform.{d}", .{i}) catch continue;
        try writeRow(w, sec, "name", d.name);
        try writeRow(w, sec, "driver", d.driver);
        try writeRow(w, sec, "modalias", d.modalias);
    }
    for (bom.acpi, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "acpi.{d}", .{i}) catch continue;
        try writeRow(w, sec, "name", d.name);
        try writeRow(w, sec, "status", d.status);
    }
    for (bom.virtio, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "virtio.{d}", .{i}) catch continue;
        try writeRow(w, sec, "name", d.name);
        try writeRow(w, sec, "device_id", d.device_id);
    }
    for (bom.i2c, 0..) |d, i| {
        var buf: [32]u8 = undefined;
        const sec = std.fmt.bufPrint(&buf, "i2c.{d}", .{i}) catch continue;
        try writeRow(w, sec, "name", d.name);
        try writeRow(w, sec, "modalias", d.modalias);
    }
    if (bom.tpm) |t| {
        if (t.version != null) try writeRow(w, "tpm", "version", t.version);
    }
}
