const std = @import("std");
const output = @import("../output.zig");

const SYS_TPM = "/sys/class/tpm";
const SYS_TPM_ALT = "/sys/class/firmware-attributes";

fn readSys(allocator: std.mem.Allocator, path: []const u8) ?[]const u8 {
    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();
    const content = file.readToEndAlloc(allocator, 64) catch return null;
    const trimmed = std.mem.trim(u8, content, &std.ascii.whitespace);
    if (trimmed.len == 0) {
        allocator.free(content);
        return null;
    }
    return trimmed;
}

pub fn detect(allocator: std.mem.Allocator) !?output.Tpm {
    var result = output.Tpm{};
    var path_buf: [128]u8 = undefined;
    const path0 = std.fmt.bufPrint(&path_buf, "{s}/tpm0/tpm_version_major", .{SYS_TPM}) catch return null;
    if (readSys(allocator, path0)) |major| {
        defer allocator.free(major);
        var minor_path_buf: [128]u8 = undefined;
        const minor_path = std.fmt.bufPrint(&minor_path_buf, "{s}/tpm0/tpm_version_minor", .{SYS_TPM}) catch return result;
        const minor = readSys(allocator, minor_path);
        result.version = std.fmt.allocPrint(allocator, "{s}.{s}", .{ major, minor orelse "0" }) catch major;
        return result;
    }
    return null;
}
