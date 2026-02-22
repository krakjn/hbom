const std = @import("std");
const output = @import("../output.zig");

const SYS_SOUND = "/sys/class/sound";

fn readSys(allocator: std.mem.Allocator, base: []const u8, name: []const u8) ?[]const u8 {
    var path_buf: [512]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ base, name }) catch return null;
    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();
    const content = file.readToEndAlloc(allocator, 256) catch return null;
    const trimmed = std.mem.trim(u8, content, &std.ascii.whitespace);
    if (trimmed.len == 0) {
        allocator.free(content);
        return null;
    }
    return trimmed;
}

pub fn detect(allocator: std.mem.Allocator) ![]const output.SoundCard {
    var dir = std.fs.openDirAbsolute(SYS_SOUND, .{ .iterate = true }) catch return &.{};
    defer dir.close();

    var list = std.ArrayList(output.SoundCard).empty;
    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory and entry.kind != .sym_link) continue;
        const name = entry.name;
        if (name.len < 5 or !std.mem.startsWith(u8, name, "card")) continue;
        const card_id = name[4..];
        if (card_id.len == 0 or card_id[0] < '0' or card_id[0] > '9') continue;

        var base_buf: [256]u8 = undefined;
        const base_path = std.fmt.bufPrint(&base_buf, "{s}/{s}", .{ SYS_SOUND, name }) catch continue;

        const id = allocator.dupe(u8, name) catch continue;
        var card_name = readSys(allocator, base_path, "id");
        if (card_name == null) card_name = readSys(allocator, base_path, "device/name");

        list.append(allocator, .{
            .id = id,
            .name = card_name,
        }) catch break;
    }
    return try list.toOwnedSlice(allocator);
}
