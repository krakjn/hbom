const std = @import("std");

const linux_musl_targets = [_]struct {
    std.Target.Query,
    []const u8, // name
}{
    .{ .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl }, "hbom-x86_64-linux-musl" },
    .{ .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .musl }, "hbom-i386-linux-musl" },
    .{ .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl }, "hbom-aarch64-linux-musl" },
    .{ .{ .cpu_arch = .arm, .os_tag = .linux, .abi = .musleabihf }, "hbom-arm-linux-musl" },
};

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    var primary_exe: ?*std.Build.Step.Compile = null;

    for (linux_musl_targets) |spec| {
        const resolved = b.resolveTargetQuery(spec.@"0");
        const mod = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = resolved,
            .optimize = optimize,
            .link_libc = true,
        });
        const exe = b.addExecutable(.{
            .name = spec.@"1",
            .root_module = mod,
        });
        b.installArtifact(exe);
        if (primary_exe == null) primary_exe = exe;
    }

    const run_cmd = b.addRunArtifact(primary_exe.?);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run hbom (writes hbom.json by default)");
    run_step.dependOn(&run_cmd.step);
}
