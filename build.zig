const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .x86_64,
            .os_tag = .windows,
            .abi = .msvc,
        },
    });

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "capslang",
        .root_source_file = .{ .cwd_relative = "capslang.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.subsystem = .Windows;
    exe.want_lto = false;

    b.installArtifact(exe);
}
