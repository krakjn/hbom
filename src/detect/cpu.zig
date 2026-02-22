const std = @import("std");
const output = @import("../output.zig");

const CPUINFO = "/proc/cpuinfo";
const SYS_CPU = "/sys/devices/system/cpu";

fn readFile(allocator: std.mem.Allocator, path: []const u8) ?[]const u8 {
    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();
    const content = file.readToEndAlloc(allocator, 4096) catch return null;
    const trimmed = std.mem.trim(u8, content, &std.ascii.whitespace);
    if (trimmed.len == 0) {
        allocator.free(content);
        return null;
    }
    return trimmed;
}

fn parseCpuinfoField(content: []const u8, key: []const u8) ?[]const u8 {
    var iter = std.mem.splitScalar(u8, content, '\n');
    while (iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (std.mem.startsWith(u8, trimmed, key) and trimmed.len > key.len and trimmed[key.len] == '\t') {
            return std.mem.trim(u8, trimmed[key.len..], &std.ascii.whitespace);
        }
    }
    return null;
}

pub fn detect(allocator: std.mem.Allocator) !output.Cpu {
    var result = output.Cpu{};
    const content = readFile(allocator, CPUINFO) orelse return result;
    defer allocator.free(content);

    result.model_name = parseCpuinfoField(content, "model name");
    if (result.model_name) |s| result.model_name = allocator.dupe(u8, s) catch null;
    result.vendor = parseCpuinfoField(content, "vendor_id");
    if (result.vendor) |s| result.vendor = allocator.dupe(u8, s) catch null;

    var cpu_count: u32 = 0;
    var iter = std.mem.splitScalar(u8, content, '\n');
    while (iter.next()) |line| {
        if (std.mem.startsWith(u8, std.mem.trim(u8, line, &std.ascii.whitespace), "processor")) cpu_count += 1;
    }
    if (cpu_count > 0) {
        result.cores = std.fmt.allocPrint(allocator, "{d}", .{cpu_count}) catch null;
    }

    var mhz_buf: [64]u8 = undefined;
    const mhz_path = std.fmt.bufPrint(&mhz_buf, "{s}/cpu0/cpufreq/scaling_cur_freq", .{SYS_CPU}) catch return result;
    if (readFile(allocator, mhz_path)) |s| {
        defer allocator.free(s);
        const khz = std.fmt.parseInt(u32, s, 10) catch null;
        if (khz) |k| {
            result.mhz = std.fmt.allocPrint(allocator, "{d}", .{k / 1000}) catch null;
        }
    }
    if (result.mhz == null) {
        const mhz_str = parseCpuinfoField(content, "cpu MHz");
        if (mhz_str) |s| result.mhz = allocator.dupe(u8, s) catch null;
    }
    return result;
}
