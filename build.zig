const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    // Primary binary: x86_64 Linux musl (all builds use musl)
    const target_x64 = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
        .abi = .musl,
    });
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target_x64,
        .optimize = optimize,
        .link_libc = true,
    });
    const exe = b.addExecutable(.{
        .name = "hbom",
        .root_module = root_module,
    });
    b.installArtifact(exe);

    // 32-bit x86 Linux musl
    const target_musl32 = b.resolveTargetQuery(.{
        .cpu_arch = .x86,
        .os_tag = .linux,
        .abi = .musl,
    });
    const mod_musl32 = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target_musl32,
        .optimize = optimize,
        .link_libc = true,
    });
    const exe_musl32 = b.addExecutable(.{
        .name = "hbom-i386-linux-musl",
        .root_module = mod_musl32,
    });
    b.installArtifact(exe_musl32);

    // 64-bit ARM Linux musl (aarch64 / arm64)
    const target_arm64 = b.resolveTargetQuery(.{
        .cpu_arch = .aarch64,
        .os_tag = .linux,
        .abi = .musl,
    });
    const mod_arm64 = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target_arm64,
        .optimize = optimize,
        .link_libc = true,
    });
    const exe_arm64 = b.addExecutable(.{
        .name = "hbom-aarch64-linux-musl",
        .root_module = mod_arm64,
    });
    b.installArtifact(exe_arm64);

    // 32-bit ARM Linux musl (hard-float ABI)
    const target_arm = b.resolveTargetQuery(.{
        .cpu_arch = .arm,
        .os_tag = .linux,
        .abi = .musleabihf,
    });
    const mod_arm = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target_arm,
        .optimize = optimize,
        .link_libc = true,
    });
    const exe_arm = b.addExecutable(.{
        .name = "hbom-arm-linux-musl",
        .root_module = mod_arm,
    });
    b.installArtifact(exe_arm);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run hbom (writes hbom.json by default)");
    run_step.dependOn(&run_cmd.step);
}
