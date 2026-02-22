const std = @import("std");
const types = @import("types.zig");

pub const Host = types.Host;
pub const Board = types.Board;
pub const Bios = types.Bios;
pub const Chassis = types.Chassis;
pub const Devicetree = types.Devicetree;
pub const PciDevice = types.PciDevice;
pub const UsbDevice = types.UsbDevice;
pub const BlockDevice = types.BlockDevice;
pub const InputDevice = types.InputDevice;
pub const NetIface = types.NetIface;
pub const Cpu = types.Cpu;
pub const Memory = types.Memory;
pub const SoundCard = types.SoundCard;
pub const Gpu = types.Gpu;
pub const ThermalZone = types.ThermalZone;
pub const PowerSupply = types.PowerSupply;
pub const PlatformDevice = types.PlatformDevice;
pub const AcpiDevice = types.AcpiDevice;
pub const VirtioDevice = types.VirtioDevice;
pub const I2cDevice = types.I2cDevice;
pub const Tpm = types.Tpm;
pub const Hbom = types.Hbom;
pub const isChipsetClass = types.isChipsetClass;
pub const deriveChipset = types.deriveChipset;

pub const Format = enum { json, toml, ini, csv };

pub const WriteOptions = struct {
    pretty: bool = false,
};

pub const Destination = union(enum) {
    path: []const u8,
    stdout,
};

pub fn write(allocator: std.mem.Allocator, bom: *const Hbom, dest: Destination, format: Format, options: WriteOptions) !void {
    switch (dest) {
        .path => |path| {
            const file = try std.fs.cwd().createFile(path, .{});
            defer file.close();
            var buf: [65536]u8 = undefined;
            var file_writer = file.writer(&buf);
            try writeFormat(allocator, bom, format, options, &file_writer.interface);
            try file_writer.interface.flush();
        },
        .stdout => {
            var buf: [65536]u8 = undefined;
            var file_writer = std.fs.File.stdout().writer(&buf);
            try writeFormat(allocator, bom, format, options, &file_writer.interface);
            try file_writer.interface.flush();
        },
    }
}

fn writeFormat(allocator: std.mem.Allocator, bom: *const Hbom, format: Format, options: WriteOptions, w: anytype) !void {
    const json_mod = @import("output/json.zig");
    const toml_mod = @import("output/toml.zig");
    const ini_mod = @import("output/ini.zig");
    const csv_mod = @import("output/csv.zig");
    switch (format) {
        .json => {
            if (options.pretty) {
                var list = try std.ArrayList(u8).initCapacity(allocator, 65536);
                defer list.deinit(allocator);
                try json_mod.writeCompact(bom, list.writer(allocator));
                var parsed = std.json.parseFromSlice(std.json.Value, allocator, list.items, .{}) catch return;
                defer parsed.deinit();
                try w.print("{f}", .{std.json.fmt(parsed.value, .{ .whitespace = .indent_2 })});
                try w.writeAll("\n");
            } else {
                try json_mod.writeCompact(bom, w);
            }
        },
        .toml => try toml_mod.write(bom, w),
        .ini => try ini_mod.write(bom, w),
        .csv => try csv_mod.write(bom, w),
    }
}
