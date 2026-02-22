const std = @import("std");

pub fn isDmiPlaceholder(s: []const u8) bool {
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

pub fn classSubclassToName(class_hex: u32) ?[]const u8 {
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
