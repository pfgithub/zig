const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .sanitize_address = true,
    });
    exe_mod.linkSystemLibrary("clang_rt.asan_osx_dynamic", .{});
    exe_mod.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/Cellar/llvm@18/18.1.8/lib/clang/18/lib/darwin/" });

    const exe = b.addExecutable(.{
        .name = "tmp",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
