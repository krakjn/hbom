const std = @import("std");
const detect_pci = @import("detect/pci.zig");

pub const Host = struct {
    name: ?[]const u8 = null,
    vendor: ?[]const u8 = null,
    serial: ?[]const u8 = null,
    uuid: ?[]const u8 = null,
};

pub const Board = struct {
    name: ?[]const u8 = null,
    vendor: ?[]const u8 = null,
    version: ?[]const u8 = null,
    serial: ?[]const u8 = null,
};

pub const Bios = struct {
    vendor: ?[]const u8 = null,
    version: ?[]const u8 = null,
    date: ?[]const u8 = null,
};

pub const Chassis = struct {
    type: ?[]const u8 = null,
    vendor: ?[]const u8 = null,
    serial: ?[]const u8 = null,
};

pub const Devicetree = struct {
    model: ?[]const u8 = null,
    serial_number: ?[]const u8 = null,
    compatible: ?[]const u8 = null,
    board_compatible: ?[]const u8 = null,
};

pub const PciDevice = struct {
    slot: []const u8,
    class: ?[]const u8 = null,
    vendor: ?[]const u8 = null,
    device: ?[]const u8 = null,
    serial: ?[]const u8 = null,
};

pub const UsbDevice = struct {
    path: []const u8,
    vendor: ?[]const u8 = null,
    product: ?[]const u8 = null,
    serial: ?[]const u8 = null,
};

pub const BlockDevice = struct {
    name: []const u8,
    model: ?[]const u8 = null,
    serial: ?[]const u8 = null,
    size: ?[]const u8 = null,
    transport: ?[]const u8 = null,
};

pub const InputDevice = struct {
    name: ?[]const u8 = null,
    uniq: ?[]const u8 = null,
};

pub const NetIface = struct {
    name: []const u8,
    address: ?[]const u8 = null,
    type: ?[]const u8 = null,
    operstate: ?[]const u8 = null,
    speed: ?[]const u8 = null,
};

pub const Cpu = struct {
    model_name: ?[]const u8 = null,
    vendor: ?[]const u8 = null,
    cores: ?[]const u8 = null,
    mhz: ?[]const u8 = null,
};

pub const Memory = struct {
    total_kb: ?[]const u8 = null,
    available_kb: ?[]const u8 = null,
};

pub const SoundCard = struct {
    id: []const u8,
    name: ?[]const u8 = null,
};

pub const Gpu = struct {
    card: []const u8,
    vendor: ?[]const u8 = null,
    device: ?[]const u8 = null,
    driver: ?[]const u8 = null,
};

pub const ThermalZone = struct {
    name: []const u8,
    type: ?[]const u8 = null,
    temp: ?[]const u8 = null,
};

pub const PowerSupply = struct {
    name: []const u8,
    type: ?[]const u8 = null,
    status: ?[]const u8 = null,
    capacity: ?[]const u8 = null,
    manufacturer: ?[]const u8 = null,
    model_name: ?[]const u8 = null,
    serial: ?[]const u8 = null,
};

pub const PlatformDevice = struct {
    name: []const u8,
    driver: ?[]const u8 = null,
    modalias: ?[]const u8 = null,
};

pub const AcpiDevice = struct {
    name: []const u8,
    status: ?[]const u8 = null,
};

pub const VirtioDevice = struct {
    name: []const u8,
    device_id: ?[]const u8 = null,
};

pub const I2cDevice = struct {
    name: []const u8,
    modalias: ?[]const u8 = null,
};

pub const Tpm = struct {
    version: ?[]const u8 = null,
};

pub const Hbom = struct {
    host: Host = .{},
    board: Board = .{},
    bios: Bios = .{},
    chassis: Chassis = .{},
    chipset: ?[]const u8 = null,
    chipsets: []const PciDevice = &.{},
    devicetree: Devicetree = .{},
    pci: []const PciDevice = &.{},
    usb: []const UsbDevice = &.{},
    block: []const BlockDevice = &.{},
    input: []const InputDevice = &.{},
    net: []const NetIface = &.{},
    cpu: Cpu = .{},
    memory: Memory = .{},
    sound: []const SoundCard = &.{},
    gpu: []const Gpu = &.{},
    thermal: []const ThermalZone = &.{},
    power: []const PowerSupply = &.{},
    platform: []const PlatformDevice = &.{},
    acpi: []const AcpiDevice = &.{},
    virtio: []const VirtioDevice = &.{},
    i2c: []const I2cDevice = &.{},
    tpm: ?Tpm = null,

    pub fn mergeDevicetreeIntoHostBoard(self: *Hbom) void {
        if (self.host.name == null and self.devicetree.model != null) {
            self.host.name = self.devicetree.model;
        }
        if (self.host.serial == null and self.devicetree.serial_number != null) {
            self.host.serial = self.devicetree.serial_number;
        }
        if (self.board.name == null and self.devicetree.board_compatible != null) {
            self.board.name = self.devicetree.board_compatible;
        }
        if (self.board.name == null and self.devicetree.compatible != null) {
            self.board.name = self.devicetree.compatible;
        }
    }
};

pub fn isChipsetClass(class: ?[]const u8) bool {
    const c = class orelse return false;
    if (c.len < 2 or c[0] != '0' or c[1] != 'x') return false;
    const val = std.fmt.parseInt(u32, c[2..], 16) catch return false;
    const class_byte = (val >> 16) & 0xff;
    return class_byte == 0x06 or class_byte == 0x0c or class_byte == 0x07;
}

fn classSubclassToName(class_hex: u32) ?[]const u8 {
    const class_byte = (class_hex >> 16) & 0xff;
    const subclass_byte = (class_hex >> 8) & 0xff;
    switch (class_byte) {
        0x06 => switch (subclass_byte) {
            0x00 => return "Host bridge",
            0x01 => return "ISA bridge",
            0x02 => return "EISA bridge",
            0x03 => return "MC",
            0x04 => return "PCI bridge",
            0x05 => return "PCMCIA bridge",
            0x06 => return "NuBus bridge",
            0x07 => return "CardBus bridge",
            0x08 => return "RACEway bridge",
            0x09 => return "PCI-Semiconductor bridge",
            0x0a => return "InfiniBand",
            0x80 => return "Other bridge",
            else => return "Bridge",
        },
        0x07 => switch (subclass_byte) {
            0x00 => return "Serial controller",
            0x01 => return "Parallel controller",
            0x02 => return "Multiport serial",
            0x03 => return "Modem",
            0x04 => return "GPIB",
            0x05 => return "Smartship",
            0x80 => return "Other communication",
            else => return "Communication controller",
        },
        0x0c => switch (subclass_byte) {
            0x00 => return "FireWire",
            0x01 => return "ACCESS",
            0x02 => return "SSA",
            0x03 => return "USB controller",
            0x04 => return "Fibre Channel",
            0x05 => return "SMBus",
            0x06 => return "InfiniBand",
            0x07 => return "IPMI",
            0x08 => return "SERCOS",
            0x09 => return "CANbus",
            0x80 => return "Other serial bus",
            else => return "Serial bus",
        },
        else => return null,
    }
}

pub fn deriveChipset(bom: *const Hbom) ?[]const u8 {
    for (bom.pci) |d| {
        if (isChipsetClass(d.class)) {
            return bom.board.name orelse bom.board.vendor orelse "PCI bridge/serial (from enumeration)";
        }
    }
    return bom.board.vendor orelse bom.board.name;
}

fn trimNewline(s: []const u8) []const u8 {
    return std.mem.trimRight(u8, s, &std.ascii.whitespace);
}

fn writeJsonString(w: anytype, s: []const u8) !void {
    try w.writeAll("\"");
    for (s) |c| {
        switch (c) {
            '\\' => try w.writeAll("\\\\"),
            '"' => try w.writeAll("\\\""),
            '\n' => try w.writeAll("\\n"),
            '\r' => try w.writeAll("\\r"),
            '\t' => try w.writeAll("\\t"),
            else => try w.writeByte(c),
        }
    }
    try w.writeAll("\"");
}

fn isDmiPlaceholder(s: []const u8) bool {
    const placeholders = [_][]const u8{
        "x.x",
        "Default string",
        "To be filled by O.E.M.",
        "To Be Filled By O.E.M.",
        "OEM",
        "Default",
        "N/A",
        "None",
    };
    const trimmed = std.mem.trim(u8, s, &std.ascii.whitespace);
    for (placeholders) |p| {
        if (std.mem.eql(u8, trimmed, p)) return true;
    }
    return false;
}

fn writeOptionalString(w: anytype, key: []const u8, val: ?[]const u8, need_comma: *bool) !void {
    if (val == null or val.?.len == 0) return;
    if (need_comma.*) try w.writeAll(",");
    need_comma.* = true;
    try w.print("\"{s}\":", .{key});
    const out = if (isDmiPlaceholder(val.?)) "placeholder" else val.?;
    try writeJsonString(w, out);
}

pub fn writeToFile(allocator: std.mem.Allocator, bom: *const Hbom, path: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();
    var buf: [65536]u8 = undefined;
    var file_writer = file.writer(&buf);
    try writeJson(allocator, bom, &file_writer.interface);
    try file_writer.interface.flush();
}

pub fn writeToStdout(allocator: std.mem.Allocator, bom: *const Hbom) !void {
    var buf: [65536]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&buf);
    try writeJson(allocator, bom, &file_writer.interface);
    try file_writer.interface.flush();
}

fn writeJson(allocator: std.mem.Allocator, bom: *const Hbom, w: anytype) !void {
    _ = allocator;
    try w.writeAll("{");

    var need_comma = false;

    if (bom.host.name != null or bom.host.vendor != null or bom.host.serial != null or bom.host.uuid != null) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"host\":{");
        var h = false;
        try writeOptionalString(w, "name", bom.host.name, &h);
        try writeOptionalString(w, "vendor", bom.host.vendor, &h);
        try writeOptionalString(w, "serial", bom.host.serial, &h);
        try writeOptionalString(w, "uuid", bom.host.uuid, &h);
        try w.writeAll("}");
    }

    if (bom.board.name != null or bom.board.vendor != null or bom.board.version != null or bom.board.serial != null) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"board\":{");
        var h = false;
        try writeOptionalString(w, "name", bom.board.name, &h);
        try writeOptionalString(w, "vendor", bom.board.vendor, &h);
        try writeOptionalString(w, "version", bom.board.version, &h);
        try writeOptionalString(w, "serial", bom.board.serial, &h);
        try w.writeAll("}");
    }

    if (bom.bios.vendor != null or bom.bios.version != null or bom.bios.date != null) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"bios\":{");
        var h = false;
        try writeOptionalString(w, "vendor", bom.bios.vendor, &h);
        try writeOptionalString(w, "version", bom.bios.version, &h);
        try writeOptionalString(w, "date", bom.bios.date, &h);
        try w.writeAll("}");
    }

    if (bom.chassis.type != null or bom.chassis.vendor != null or bom.chassis.serial != null) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"chassis\":{");
        var h = false;
        try writeOptionalString(w, "type", bom.chassis.type, &h);
        try writeOptionalString(w, "vendor", bom.chassis.vendor, &h);
        try writeOptionalString(w, "serial", bom.chassis.serial, &h);
        try w.writeAll("}");
    }

    if (bom.chipset) |s| {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"chipset\":");
        try writeJsonString(w, s);
    }

    if (bom.chipsets.len > 0) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"chipsets\":[");
        for (bom.chipsets, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try w.print("\"slot\":", .{});
            try writeJsonString(w, d.slot);
            h = true;
            try writeOptionalString(w, "class", d.class, &h);
            try writeOptionalString(w, "vendor", d.vendor, &h);
            try writeOptionalString(w, "device", d.device, &h);
            try writeOptionalString(w, "serial", d.serial, &h);
            if (d.class) |class_str| {
                if (class_str.len >= 2 and class_str[0] == '0' and class_str[1] == 'x') {
                    const val = std.fmt.parseInt(u32, class_str[2..], 16) catch 0;
                    if (classSubclassToName(val)) |type_name| {
                        if (h) try w.writeAll(",");
                        try w.writeAll("\"type\":");
                        try writeJsonString(w, type_name);
                    }
                }
            }
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.pci.len > 0) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"pci\":[");
        for (bom.pci, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try w.print("\"slot\":", .{});
            try writeJsonString(w, d.slot);
            h = true;
            try writeOptionalString(w, "class", d.class, &h);
            try writeOptionalString(w, "vendor", d.vendor, &h);
            try writeOptionalString(w, "device", d.device, &h);
            try writeOptionalString(w, "serial", d.serial, &h);
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.usb.len > 0) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"usb\":[");
        for (bom.usb, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try w.print("\"path\":", .{});
            try writeJsonString(w, d.path);
            h = true;
            try writeOptionalString(w, "vendor", d.vendor, &h);
            try writeOptionalString(w, "product", d.product, &h);
            try writeOptionalString(w, "serial", d.serial, &h);
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.block.len > 0) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"block\":[");
        for (bom.block, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try w.print("\"name\":", .{});
            try writeJsonString(w, d.name);
            h = true;
            try writeOptionalString(w, "model", d.model, &h);
            try writeOptionalString(w, "serial", d.serial, &h);
            try writeOptionalString(w, "size", d.size, &h);
            try writeOptionalString(w, "transport", d.transport, &h);
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.input.len > 0) {
        if (need_comma) try w.writeAll(",");
        try w.writeAll("\"input\":[");
        for (bom.input, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try writeOptionalString(w, "name", d.name, &h);
            try writeOptionalString(w, "uniq", d.uniq, &h);
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.net.len > 0) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"net\":[");
        for (bom.net, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try w.print("\"name\":", .{});
            try writeJsonString(w, d.name);
            h = true;
            try writeOptionalString(w, "address", d.address, &h);
            try writeOptionalString(w, "type", d.type, &h);
            try writeOptionalString(w, "operstate", d.operstate, &h);
            try writeOptionalString(w, "speed", d.speed, &h);
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.cpu.model_name != null or bom.cpu.vendor != null or bom.cpu.cores != null or bom.cpu.mhz != null) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"cpu\":{");
        var h = false;
        try writeOptionalString(w, "model_name", bom.cpu.model_name, &h);
        try writeOptionalString(w, "vendor", bom.cpu.vendor, &h);
        try writeOptionalString(w, "cores", bom.cpu.cores, &h);
        try writeOptionalString(w, "mhz", bom.cpu.mhz, &h);
        try w.writeAll("}");
    }

    if (bom.memory.total_kb != null or bom.memory.available_kb != null) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"memory\":{");
        var h = false;
        try writeOptionalString(w, "total_kb", bom.memory.total_kb, &h);
        try writeOptionalString(w, "available_kb", bom.memory.available_kb, &h);
        try w.writeAll("}");
    }

    if (bom.sound.len > 0) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"sound\":[");
        for (bom.sound, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try w.print("\"id\":", .{});
            try writeJsonString(w, d.id);
            h = true;
            try writeOptionalString(w, "name", d.name, &h);
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.gpu.len > 0) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"gpu\":[");
        for (bom.gpu, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try w.print("\"card\":", .{});
            try writeJsonString(w, d.card);
            h = true;
            try writeOptionalString(w, "vendor", d.vendor, &h);
            try writeOptionalString(w, "device", d.device, &h);
            try writeOptionalString(w, "driver", d.driver, &h);
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.thermal.len > 0) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"thermal\":[");
        for (bom.thermal, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try w.print("\"name\":", .{});
            try writeJsonString(w, d.name);
            h = true;
            try writeOptionalString(w, "type", d.type, &h);
            try writeOptionalString(w, "temp", d.temp, &h);
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.power.len > 0) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"power\":[");
        for (bom.power, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try w.print("\"name\":", .{});
            try writeJsonString(w, d.name);
            h = true;
            try writeOptionalString(w, "type", d.type, &h);
            try writeOptionalString(w, "status", d.status, &h);
            try writeOptionalString(w, "capacity", d.capacity, &h);
            try writeOptionalString(w, "manufacturer", d.manufacturer, &h);
            try writeOptionalString(w, "model_name", d.model_name, &h);
            try writeOptionalString(w, "serial", d.serial, &h);
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.platform.len > 0) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"platform\":[");
        for (bom.platform, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try w.print("\"name\":", .{});
            try writeJsonString(w, d.name);
            h = true;
            try writeOptionalString(w, "driver", d.driver, &h);
            try writeOptionalString(w, "modalias", d.modalias, &h);
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.acpi.len > 0) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"acpi\":[");
        for (bom.acpi, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try w.print("\"name\":", .{});
            try writeJsonString(w, d.name);
            h = true;
            try writeOptionalString(w, "status", d.status, &h);
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.virtio.len > 0) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"virtio\":[");
        for (bom.virtio, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try w.print("\"name\":", .{});
            try writeJsonString(w, d.name);
            h = true;
            try writeOptionalString(w, "device_id", d.device_id, &h);
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.i2c.len > 0) {
        if (need_comma) try w.writeAll(",");
        need_comma = true;
        try w.writeAll("\"i2c\":[");
        for (bom.i2c, 0..) |d, i| {
            if (i > 0) try w.writeAll(",");
            try w.writeAll("{");
            var h = false;
            try w.print("\"name\":", .{});
            try writeJsonString(w, d.name);
            h = true;
            try writeOptionalString(w, "modalias", d.modalias, &h);
            try w.writeAll("}");
        }
        try w.writeAll("]");
    }

    if (bom.tpm) |t| {
        if (t.version != null) {
            if (need_comma) try w.writeAll(",");
            need_comma = true;
            try w.writeAll("\"tpm\":{");
            var h = false;
            try writeOptionalString(w, "version", t.version, &h);
            try w.writeAll("}");
        }
    }

    try w.writeAll("}\n");
}
