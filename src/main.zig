const std = @import("std");
const detect = @import("detect/dmi.zig");
const detect_dt = @import("detect/devicetree.zig");
const detect_pci = @import("detect/pci.zig");
const detect_usb = @import("detect/usb.zig");
const detect_block = @import("detect/block.zig");
const detect_input = @import("detect/input.zig");
const output = @import("output.zig");

const default_output_path = "hbom.json";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout_to = parseArgs(allocator) catch |err| {
        if (err == error.PrintHelp) {
            printHelp();
            return;
        }
        std.log.err("failed to parse arguments", .{});
        return err;
    };
    defer if (stdout_to == .file) allocator.free(stdout_to.file);

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
    };

    bom.mergeDevicetreeIntoHostBoard();

    const chipset_desc = output.deriveChipset(&bom);
    if (chipset_desc) |s| bom.chipset = s;

    switch (stdout_to) {
        .default_file => try output.writeToFile(arena_alloc, &bom, default_output_path),
        .file => |path| try output.writeToFile(arena_alloc, &bom, path),
        .stdout => try output.writeToStdout(arena_alloc, &bom),
    }
}

const OutputDest = union(enum) {
    default_file,
    file: []const u8,
    stdout,
};

fn parseArgs(allocator: std.mem.Allocator) !OutputDest {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // skip exe name

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            return error.PrintHelp;
        }
        if (std.mem.eql(u8, arg, "--stdout")) {
            return .stdout;
        }
        if (std.mem.eql(u8, arg, "--output") or std.mem.eql(u8, arg, "-o")) {
            const path = args.next() orelse {
                std.log.err("--output / -o requires a path", .{});
                return error.InvalidArgs;
            };
            return .{ .file = try allocator.dupe(u8, path) };
        }
    }
    return .default_file;
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
        \\  -o, --output FILE   Write JSON to FILE.
        \\  --stdout      Print JSON to stdout.
        \\  -h, --help    Show this help.
        \\
    , .{}) catch {};
    w.flush() catch {};
}
