const types = @import("../types.zig");
const common = @import("common.zig");

fn writeIniVal(w: anytype, val: []const u8) !void {
    const out = if (common.isDmiPlaceholder(val)) "placeholder" else val;
    for (out) |c| {
        if (c == '\n' or c == '\r' or c == '=' or c == ';' or c == '#') try w.writeByte('\\');
        try w.writeByte(c);
    }
    try w.writeAll("\n");
}

fn writeIniKey(w: anytype, key: []const u8, val: ?[]const u8) !void {
    if (val == null or val.?.len == 0) return;
    try w.print("{s} = ", .{key});
    try writeIniVal(w, val.?);
}

pub fn write(bom: *const types.Hbom, w: anytype) !void {
    if (bom.host.name != null or bom.host.vendor != null or bom.host.serial != null or bom.host.uuid != null) {
        try w.writeAll("[host]\n");
        try writeIniKey(w, "name", bom.host.name);
        try writeIniKey(w, "vendor", bom.host.vendor);
        try writeIniKey(w, "serial", bom.host.serial);
        try writeIniKey(w, "uuid", bom.host.uuid);
    }
    if (bom.board.name != null or bom.board.vendor != null or bom.board.version != null or bom.board.serial != null) {
        try w.writeAll("[board]\n");
        try writeIniKey(w, "name", bom.board.name);
        try writeIniKey(w, "vendor", bom.board.vendor);
        try writeIniKey(w, "version", bom.board.version);
        try writeIniKey(w, "serial", bom.board.serial);
    }
    if (bom.bios.vendor != null or bom.bios.version != null or bom.bios.date != null) {
        try w.writeAll("[bios]\n");
        try writeIniKey(w, "vendor", bom.bios.vendor);
        try writeIniKey(w, "version", bom.bios.version);
        try writeIniKey(w, "date", bom.bios.date);
    }
    if (bom.chassis.type != null or bom.chassis.vendor != null or bom.chassis.serial != null) {
        try w.writeAll("[chassis]\n");
        try writeIniKey(w, "type", bom.chassis.type);
        try writeIniKey(w, "vendor", bom.chassis.vendor);
        try writeIniKey(w, "serial", bom.chassis.serial);
    }
    if (bom.chipset) |s| {
        try w.writeAll("[chipset]\n");
        try writeIniKey(w, "chipset", s);
    }
    for (bom.chipsets, 0..) |d, i| {
        try w.print("[chipsets.{d}]\n", .{i});
        try writeIniKey(w, "slot", d.slot);
        try writeIniKey(w, "class", d.class);
        try writeIniKey(w, "vendor", d.vendor);
        try writeIniKey(w, "device", d.device);
        try writeIniKey(w, "serial", d.serial);
    }
    for (bom.pci, 0..) |d, i| {
        try w.print("[pci.{d}]\n", .{i});
        try writeIniKey(w, "slot", d.slot);
        try writeIniKey(w, "class", d.class);
        try writeIniKey(w, "vendor", d.vendor);
        try writeIniKey(w, "device", d.device);
        try writeIniKey(w, "serial", d.serial);
    }
    for (bom.usb, 0..) |d, i| {
        try w.print("[usb.{d}]\n", .{i});
        try writeIniKey(w, "path", d.path);
        try writeIniKey(w, "vendor", d.vendor);
        try writeIniKey(w, "product", d.product);
        try writeIniKey(w, "serial", d.serial);
    }
    for (bom.block, 0..) |d, i| {
        try w.print("[block.{d}]\n", .{i});
        try writeIniKey(w, "name", d.name);
        try writeIniKey(w, "model", d.model);
        try writeIniKey(w, "serial", d.serial);
        try writeIniKey(w, "size", d.size);
        try writeIniKey(w, "transport", d.transport);
    }
    for (bom.input, 0..) |d, i| {
        try w.print("[input.{d}]\n", .{i});
        try writeIniKey(w, "name", d.name);
        try writeIniKey(w, "uniq", d.uniq);
    }
    for (bom.net, 0..) |d, i| {
        try w.print("[net.{d}]\n", .{i});
        try writeIniKey(w, "name", d.name);
        try writeIniKey(w, "address", d.address);
        try writeIniKey(w, "type", d.type);
        try writeIniKey(w, "operstate", d.operstate);
        try writeIniKey(w, "speed", d.speed);
    }
    if (bom.cpu.model_name != null or bom.cpu.vendor != null or bom.cpu.cores != null or bom.cpu.mhz != null) {
        try w.writeAll("[cpu]\n");
        try writeIniKey(w, "model_name", bom.cpu.model_name);
        try writeIniKey(w, "vendor", bom.cpu.vendor);
        try writeIniKey(w, "cores", bom.cpu.cores);
        try writeIniKey(w, "mhz", bom.cpu.mhz);
    }
    if (bom.memory.total_kb != null or bom.memory.available_kb != null) {
        try w.writeAll("[memory]\n");
        try writeIniKey(w, "total_kb", bom.memory.total_kb);
        try writeIniKey(w, "available_kb", bom.memory.available_kb);
    }
    for (bom.sound, 0..) |d, i| {
        try w.print("[sound.{d}]\n", .{i});
        try writeIniKey(w, "id", d.id);
        try writeIniKey(w, "name", d.name);
    }
    for (bom.gpu, 0..) |d, i| {
        try w.print("[gpu.{d}]\n", .{i});
        try writeIniKey(w, "card", d.card);
        try writeIniKey(w, "vendor", d.vendor);
        try writeIniKey(w, "device", d.device);
        try writeIniKey(w, "driver", d.driver);
    }
    for (bom.thermal, 0..) |d, i| {
        try w.print("[thermal.{d}]\n", .{i});
        try writeIniKey(w, "name", d.name);
        try writeIniKey(w, "type", d.type);
        try writeIniKey(w, "temp", d.temp);
    }
    for (bom.power, 0..) |d, i| {
        try w.print("[power.{d}]\n", .{i});
        try writeIniKey(w, "name", d.name);
        try writeIniKey(w, "type", d.type);
        try writeIniKey(w, "status", d.status);
        try writeIniKey(w, "capacity", d.capacity);
        try writeIniKey(w, "manufacturer", d.manufacturer);
        try writeIniKey(w, "model_name", d.model_name);
        try writeIniKey(w, "serial", d.serial);
    }
    for (bom.platform, 0..) |d, i| {
        try w.print("[platform.{d}]\n", .{i});
        try writeIniKey(w, "name", d.name);
        try writeIniKey(w, "driver", d.driver);
        try writeIniKey(w, "modalias", d.modalias);
    }
    for (bom.acpi, 0..) |d, i| {
        try w.print("[acpi.{d}]\n", .{i});
        try writeIniKey(w, "name", d.name);
        try writeIniKey(w, "status", d.status);
    }
    for (bom.virtio, 0..) |d, i| {
        try w.print("[virtio.{d}]\n", .{i});
        try writeIniKey(w, "name", d.name);
        try writeIniKey(w, "device_id", d.device_id);
    }
    for (bom.i2c, 0..) |d, i| {
        try w.print("[i2c.{d}]\n", .{i});
        try writeIniKey(w, "name", d.name);
        try writeIniKey(w, "modalias", d.modalias);
    }
    if (bom.tpm) |t| {
        if (t.version != null) {
            try w.writeAll("[tpm]\n");
            try writeIniKey(w, "version", t.version);
        }
    }
}
