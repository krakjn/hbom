const std = @import("std");
const detect = @import("detect/dmi.zig");
const detect_dt = @import("detect/devicetree.zig");
const detect_pci = @import("detect/pci.zig");
const detect_usb = @import("detect/usb.zig");
const detect_block = @import("detect/block.zig");
const detect_input = @import("detect/input.zig");
const detect_net = @import("detect/net.zig");
const detect_cpu = @import("detect/cpu.zig");
const detect_memory = @import("detect/memory.zig");
const detect_sound = @import("detect/sound.zig");
const detect_gpu = @import("detect/gpu.zig");
const detect_thermal = @import("detect/thermal.zig");
const detect_power = @import("detect/power.zig");
const detect_platform = @import("detect/platform.zig");
const detect_acpi = @import("detect/acpi.zig");
const detect_virtio = @import("detect/virtio.zig");
const detect_i2c = @import("detect/i2c.zig");
const detect_tpm = @import("detect/tpm.zig");
const output = @import("output.zig");

const version_info = @import("version");

const default_output_basename = "hbom";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout_to = parseArgs(allocator) catch |err| {
        if (err == error.PrintHelp) {
            printHelp();
            return;
        }
        if (err == error.PrintVersion) {
            std.debug.print("hbom {s}\n", .{version_info.version});
            return;
        }
        std.log.err("failed to parse arguments", .{});
        return err;
    };
    defer if (stdout_to == .file) allocator.free(stdout_to.file.path);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    var bom = output.Hbom{
        .host = try detect.detectHost(arena_alloc),
        .board = try detect.detectBoard(arena_alloc),
        .bios = try detect.detectBios(arena_alloc),
        .chassis = try detect.detectChassis(arena_alloc),
        .devicetree = try detect_dt.detect(arena_alloc),
        .pci = try detect_pci.detect(arena_alloc),
        .usb = try detect_usb.detect(arena_alloc),
        .block = try detect_block.detect(arena_alloc),
        .input = try detect_input.detect(arena_alloc),
        .net = try detect_net.detect(arena_alloc),
        .cpu = try detect_cpu.detect(arena_alloc),
        .memory = try detect_memory.detect(arena_alloc),
        .sound = try detect_sound.detect(arena_alloc),
        .gpu = try detect_gpu.detect(arena_alloc),
        .thermal = try detect_thermal.detect(arena_alloc),
        .power = try detect_power.detect(arena_alloc),
        .platform = try detect_platform.detect(arena_alloc),
        .acpi = try detect_acpi.detect(arena_alloc),
        .virtio = try detect_virtio.detect(arena_alloc),
        .i2c = try detect_i2c.detect(arena_alloc),
        .tpm = detect_tpm.detect(arena_alloc) catch null,
    };

    bom.mergeDevicetreeIntoHostBoard();

    var chipsets_list = std.ArrayList(output.PciDevice).empty;
    for (bom.pci) |d| {
        if (output.isChipsetClass(d.class)) {
            chipsets_list.append(arena_alloc, d) catch break;
        }
    }
    bom.chipsets = try chipsets_list.toOwnedSlice(arena_alloc);

    const chipset_desc = output.deriveChipset(&bom);
    if (chipset_desc) |s| bom.chipset = s;

    const format = switch (stdout_to) {
        .default_file => |o| o.format,
        .file => |o| o.format,
        .stdout => |o| o.format,
    };
    const pretty = switch (stdout_to) {
        .default_file => |o| o.pretty,
        .file => |o| o.pretty,
        .stdout => |o| o.pretty,
    };
    var default_path: ?[]const u8 = null;
    defer if (default_path) |p| allocator.free(p);
    const dest: output.Destination = switch (stdout_to) {
        .default_file => blk: {
            default_path = try defaultPathForFormat(allocator, format);
            break :blk .{ .path = default_path.? };
        },
        .file => |o| .{ .path = o.path },
        .stdout => .stdout,
    };
    try output.write(arena_alloc, &bom, dest, format, .{ .pretty = pretty });
}

const OutputDest = union(enum) {
    default_file: struct { format: output.Format, pretty: bool },
    file: struct { path: []const u8, format: output.Format, pretty: bool },
    stdout: struct { format: output.Format, pretty: bool },
};

fn defaultPathForFormat(allocator: std.mem.Allocator, format: output.Format) ![]const u8 {
    const ext = switch (format) {
        .json => "json",
        .toml => "toml",
        .ini => "ini",
        .csv => "csv",
    };
    return std.fmt.allocPrint(allocator, "{s}.{s}", .{ default_output_basename, ext });
}

fn parseArgs(allocator: std.mem.Allocator) !OutputDest {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // skip exe name

    var pretty = false;
    var to_stdout = false;
    var output_path: ?[]const u8 = null;
    var format: output.Format = .json;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            return error.PrintHelp;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            return error.PrintVersion;
        }
        if (std.mem.eql(u8, arg, "--stdout")) {
            to_stdout = true;
        } else if (std.mem.eql(u8, arg, "--pretty") or std.mem.eql(u8, arg, "-p")) {
            pretty = true;
        } else if (std.mem.startsWith(u8, arg, "--format=")) {
            format = parseFormat(arg["--format=".len..]) orelse {
                std.log.err("unknown format: {s}", .{arg["--format=".len..]});
                return error.InvalidArgs;
            };
        } else if (std.mem.eql(u8, arg, "-f")) {
            const val = args.next() orelse {
                std.log.err("-f requires format (json, toml, ini, csv)", .{});
                return error.InvalidArgs;
            };
            format = parseFormat(val) orelse {
                std.log.err("unknown format: {s}", .{val});
                return error.InvalidArgs;
            };
        } else if (std.mem.eql(u8, arg, "--output") or std.mem.eql(u8, arg, "-o")) {
            const path = args.next() orelse {
                std.log.err("--output / -o requires a path", .{});
                return error.InvalidArgs;
            };
            output_path = try allocator.dupe(u8, path);
        }
    }

    if (output_path) |path| return .{ .file = .{ .path = path, .format = format, .pretty = pretty } };
    if (to_stdout) return .{ .stdout = .{ .format = format, .pretty = pretty } };
    return .{ .default_file = .{ .format = format, .pretty = pretty } };
}

fn parseFormat(s: []const u8) ?output.Format {
    if (std.mem.eql(u8, s, "json")) return .json;
    if (std.mem.eql(u8, s, "toml")) return .toml;
    if (std.mem.eql(u8, s, "ini")) return .ini;
    if (std.mem.eql(u8, s, "csv")) return .csv;
    return null;
}

fn printHelp() void {
    var buf: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&buf);
    var w = &file_writer.interface;
    w.print(
        \\hbom - Hardware Bill of Materials (Linux)
        \\Usage: hbom [options]
        \\
        \\  (no args)    Write condensed JSON to hbom.json in the current directory.
        \\  -o, --output FILE   Write output to FILE.
        \\  --stdout      Print output to stdout.
        \\  -f, --format FORMAT   Output format: json (default), toml, ini, csv.
        \\  -p, --pretty   Pretty-print JSON (no effect for other formats).
        \\  -h, --help    Show this help.
        \\
    , .{}) catch {};
    w.flush() catch {};
}
