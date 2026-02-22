const types = @import("../types.zig");

pub fn write(bom: *const types.Hbom, w: anytype) !void {
    try w.writeAll("# TOML output\n");
    if (bom.host.name != null or bom.host.vendor != null or bom.host.serial != null or bom.host.uuid != null) {
        try w.writeAll("[host]\n");
        if (bom.host.name) |v| try w.print("name = \"{s}\"\n", .{v});
        if (bom.host.vendor) |v| try w.print("vendor = \"{s}\"\n", .{v});
        if (bom.host.serial) |v| try w.print("serial = \"{s}\"\n", .{v});
        if (bom.host.uuid) |v| try w.print("uuid = \"{s}\"\n", .{v});
    }
    if (bom.board.name != null or bom.board.vendor != null or bom.board.version != null or bom.board.serial != null) {
        try w.writeAll("[board]\n");
        if (bom.board.name) |v| try w.print("name = \"{s}\"\n", .{v});
        if (bom.board.vendor) |v| try w.print("vendor = \"{s}\"\n", .{v});
        if (bom.board.version) |v| try w.print("version = \"{s}\"\n", .{v});
        if (bom.board.serial) |v| try w.print("serial = \"{s}\"\n", .{v});
    }
    if (bom.bios.vendor != null or bom.bios.version != null or bom.bios.date != null) {
        try w.writeAll("[bios]\n");
        if (bom.bios.vendor) |v| try w.print("vendor = \"{s}\"\n", .{v});
        if (bom.bios.version) |v| try w.print("version = \"{s}\"\n", .{v});
        if (bom.bios.date) |v| try w.print("date = \"{s}\"\n", .{v});
    }
    if (bom.chassis.type != null or bom.chassis.vendor != null or bom.chassis.serial != null) {
        try w.writeAll("[chassis]\n");
        if (bom.chassis.type) |v| try w.print("type = \"{s}\"\n", .{v});
        if (bom.chassis.vendor) |v| try w.print("vendor = \"{s}\"\n", .{v});
        if (bom.chassis.serial) |v| try w.print("serial = \"{s}\"\n", .{v});
    }
    if (bom.chipset) |s| try w.print("chipset = \"{s}\"\n", .{s});
    for (bom.chipsets) |d| {
        try w.writeAll("[[chipsets]]\n");
        try w.print("slot = \"{s}\"\n", .{d.slot});
        if (d.class) |v| try w.print("class = \"{s}\"\n", .{v});
        if (d.vendor) |v| try w.print("vendor = \"{s}\"\n", .{v});
        if (d.device) |v| try w.print("device = \"{s}\"\n", .{v});
        if (d.serial) |v| try w.print("serial = \"{s}\"\n", .{v});
    }
    for (bom.pci) |d| {
        try w.writeAll("[[pci]]\n");
        try w.print("slot = \"{s}\"\n", .{d.slot});
        if (d.class) |v| try w.print("class = \"{s}\"\n", .{v});
        if (d.vendor) |v| try w.print("vendor = \"{s}\"\n", .{v});
        if (d.device) |v| try w.print("device = \"{s}\"\n", .{v});
        if (d.serial) |v| try w.print("serial = \"{s}\"\n", .{v});
    }
    for (bom.usb) |d| {
        try w.writeAll("[[usb]]\n");
        try w.print("path = \"{s}\"\n", .{d.path});
        if (d.vendor) |v| try w.print("vendor = \"{s}\"\n", .{v});
        if (d.product) |v| try w.print("product = \"{s}\"\n", .{v});
        if (d.serial) |v| try w.print("serial = \"{s}\"\n", .{v});
    }
    for (bom.block) |d| {
        try w.writeAll("[[block]]\n");
        try w.print("name = \"{s}\"\n", .{d.name});
        if (d.model) |v| try w.print("model = \"{s}\"\n", .{v});
        if (d.serial) |v| try w.print("serial = \"{s}\"\n", .{v});
        if (d.size) |v| try w.print("size = \"{s}\"\n", .{v});
        if (d.transport) |v| try w.print("transport = \"{s}\"\n", .{v});
    }
    for (bom.input) |d| {
        try w.writeAll("[[input]]\n");
        if (d.name) |v| try w.print("name = \"{s}\"\n", .{v});
        if (d.uniq) |v| try w.print("uniq = \"{s}\"\n", .{v});
    }
    for (bom.net) |d| {
        try w.writeAll("[[net]]\n");
        try w.print("name = \"{s}\"\n", .{d.name});
        if (d.address) |v| try w.print("address = \"{s}\"\n", .{v});
        if (d.type) |v| try w.print("type = \"{s}\"\n", .{v});
        if (d.operstate) |v| try w.print("operstate = \"{s}\"\n", .{v});
        if (d.speed) |v| try w.print("speed = \"{s}\"\n", .{v});
    }
    if (bom.cpu.model_name != null or bom.cpu.vendor != null or bom.cpu.cores != null or bom.cpu.mhz != null) {
        try w.writeAll("[cpu]\n");
        if (bom.cpu.model_name) |v| try w.print("model_name = \"{s}\"\n", .{v});
        if (bom.cpu.vendor) |v| try w.print("vendor = \"{s}\"\n", .{v});
        if (bom.cpu.cores) |v| try w.print("cores = \"{s}\"\n", .{v});
        if (bom.cpu.mhz) |v| try w.print("mhz = \"{s}\"\n", .{v});
    }
    if (bom.memory.total_kb != null or bom.memory.available_kb != null) {
        try w.writeAll("[memory]\n");
        if (bom.memory.total_kb) |v| try w.print("total_kb = \"{s}\"\n", .{v});
        if (bom.memory.available_kb) |v| try w.print("available_kb = \"{s}\"\n", .{v});
    }
    for (bom.sound) |d| {
        try w.writeAll("[[sound]]\n");
        try w.print("id = \"{s}\"\n", .{d.id});
        if (d.name) |v| try w.print("name = \"{s}\"\n", .{v});
    }
    for (bom.gpu) |d| {
        try w.writeAll("[[gpu]]\n");
        try w.print("card = \"{s}\"\n", .{d.card});
        if (d.vendor) |v| try w.print("vendor = \"{s}\"\n", .{v});
        if (d.device) |v| try w.print("device = \"{s}\"\n", .{v});
        if (d.driver) |v| try w.print("driver = \"{s}\"\n", .{v});
    }
    for (bom.thermal) |d| {
        try w.writeAll("[[thermal]]\n");
        try w.print("name = \"{s}\"\n", .{d.name});
        if (d.type) |v| try w.print("type = \"{s}\"\n", .{v});
        if (d.temp) |v| try w.print("temp = \"{s}\"\n", .{v});
    }
    for (bom.power) |d| {
        try w.writeAll("[[power]]\n");
        try w.print("name = \"{s}\"\n", .{d.name});
        if (d.type) |v| try w.print("type = \"{s}\"\n", .{v});
        if (d.status) |v| try w.print("status = \"{s}\"\n", .{v});
        if (d.capacity) |v| try w.print("capacity = \"{s}\"\n", .{v});
        if (d.manufacturer) |v| try w.print("manufacturer = \"{s}\"\n", .{v});
        if (d.model_name) |v| try w.print("model_name = \"{s}\"\n", .{v});
        if (d.serial) |v| try w.print("serial = \"{s}\"\n", .{v});
    }
    for (bom.platform) |d| {
        try w.writeAll("[[platform]]\n");
        try w.print("name = \"{s}\"\n", .{d.name});
        if (d.driver) |v| try w.print("driver = \"{s}\"\n", .{v});
        if (d.modalias) |v| try w.print("modalias = \"{s}\"\n", .{v});
    }
    for (bom.acpi) |d| {
        try w.writeAll("[[acpi]]\n");
        try w.print("name = \"{s}\"\n", .{d.name});
        if (d.status) |v| try w.print("status = \"{s}\"\n", .{v});
    }
    for (bom.virtio) |d| {
        try w.writeAll("[[virtio]]\n");
        try w.print("name = \"{s}\"\n", .{d.name});
        if (d.device_id) |v| try w.print("device_id = \"{s}\"\n", .{v});
    }
    for (bom.i2c) |d| {
        try w.writeAll("[[i2c]]\n");
        try w.print("name = \"{s}\"\n", .{d.name});
        if (d.modalias) |v| try w.print("modalias = \"{s}\"\n", .{v});
    }
    if (bom.tpm) |t| {
        if (t.version != null) {
            try w.writeAll("[tpm]\n");
            if (t.version) |v| try w.print("version = \"{s}\"\n", .{v});
        }
    }
}
