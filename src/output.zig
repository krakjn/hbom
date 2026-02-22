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

pub const Hbom = struct {
    host: Host = .{},
    board: Board = .{},
    bios: Bios = .{},
    chassis: Chassis = .{},
    chipset: ?[]const u8 = null,
    devicetree: Devicetree = .{},
    pci: []const PciDevice = &.{},
    usb: []const UsbDevice = &.{},
    block: []const BlockDevice = &.{},
    input: []const InputDevice = &.{},

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

pub fn deriveChipset(bom: *const Hbom) ?[]const u8 {
    for (bom.pci) |d| {
        const class = d.class orelse continue;
        if (class.len >= 2 and class[0] == '0' and class[1] == 'x') {
            const val = std.fmt.parseInt(u32, class[2..], 16) catch continue;
            const class_byte = (val >> 16) & 0xff;
            if (class_byte == 0x06 or class_byte == 0x0c) {
                return bom.board.name orelse bom.board.vendor orelse "PCI bridge/serial (from enumeration)";
            }
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

    try w.writeAll("}\n");
}
