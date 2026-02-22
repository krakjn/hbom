const std = @import("std");

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

pub fn deriveChipset(bom: *const Hbom) ?[]const u8 {
    for (bom.pci) |d| {
        if (isChipsetClass(d.class)) {
            return bom.board.name orelse bom.board.vendor orelse "PCI bridge/serial (from enumeration)";
        }
    }
    return bom.board.vendor orelse bom.board.name;
}
