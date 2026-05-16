const std = @import("std");

fn bin(b: *std.Build, comptime name: []const u8, filename: []const u8, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(filename),
            .optimize = optimize,
            .target = target,
        }),
    });
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    var run_step = b.step(name, "build and run " ++ name);
    run_step.dependOn(&run_cmd.step);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    bin(b, "client", "src/main.zig", target, optimize);
    bin(b, "proto-setup", "src/X11/proto/setup.zig", target, optimize);
    bin(b, "mitm-socket", "src/tools/mitm-socket.zig", target, optimize);
}
