const std = @import("std");
const B = std.Build;

pub fn build(b: *B) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    {
        _ = b.addModule("zig-package-template", .{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        });
    }

    {
        const tests = b.addTest(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        });

        const run_tests = b.addRunArtifact(tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_tests.step);
    }

    {
        const tests_check = b.addTest(.{
            .name = "check",
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        });

        const check = b.step("check", "Check if tests compile");
        check.dependOn(&tests_check.step);
    }
}

fn addDependencies(
    compile_step: *B.Step.Compile,
    b: *B,
    target: B.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    _ = compile_step;
    _ = b;
    _ = target;
    _ = optimize;
}
