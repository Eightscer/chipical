const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "chipical",
        .root_source_file = b.path("src/interface.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.linkSystemLibrary("sdl2");
    exe.linkLibC();
    b.installArtifact(exe);
}
