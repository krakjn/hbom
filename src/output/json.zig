const std = @import("std");
const types = @import("../types.zig");
const common = @import("common.zig");

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

fn writeOptionalString(w: anytype, key: []const u8, val: ?[]const u8, need_comma: *bool) !void {
    if (val == null or val.?.len == 0) return;
    if (need_comma.*) try w.writeAll(",");
    need_comma.* = true;
    try w.print("\"{s}\":", .{key});
    const out = if (common.isDmiPlaceholder(val.?)) "placeholder" else val.?;
    try writeJsonString(w, out);
}

pub fn writeCompact(bom: *const types.Hbom, w: anytype) !void {
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
                    if (common.classSubclassToName(val)) |type_name| {
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
        need_comma = true;
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
