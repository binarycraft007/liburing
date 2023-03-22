const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "uring",
        .target = target,
        .optimize = optimize,
    });
    const io_uring_ver_h = b.addConfigHeader(.{
        .style = .blank,
        .include_path = "liburing/io_uring_version.h",
    }, .{
        .IO_URING_VERSION_MAJOR = 2,
        .IO_URING_VERSION_MINOR = 4,
    });
    lib.addConfigHeader(io_uring_ver_h);
    lib.addCSourceFiles(&.{
        "src/setup.c",
        "src/queue.c",
        "src/register.c",
        "src/syscall.c",
        "src/version.c",
        "src/nolibc.c",
    }, &.{
        "-D_GNU_SOURCE",
        "-D_LARGEFILE_SOURCE",
        "-D_FILE_OFFSET_BITS=64",
        "-nostdlib",
        "-nodefaultlibs",
        "-ffreestanding",
        "-Wall",
        "-Wextra",
        "-fno-stack-protector",
        "-Wno-unused-parameter",
        "-Wno-sign-compare",
        "-DLIBURING_INTERNAL",

        "-DCONFIG_NOLIBC",
        "-DCONFIG_HAVE_KERNEL_RWF_T",
        "-DCONFIG_HAVE_KERNEL_TIMESPEC",
        "-DCONFIG_HAVE_OPEN_HOW",
        "-DCONFIG_HAVE_STATX",
        "-DCONFIG_HAVE_GLIBC_STATX",
        "-DCONFIG_HAVE_CXX",
        "-DCONFIG_HAVE_UCONTEXT",
        "-DCONFIG_HAVE_STRINGOP_OVERFLOW",
        "-DCONFIG_HAVE_ARRAY_BOUNDS",
        "-DCONFIG_HAVE_NVME_URING",
        "-DCONFIG_HAVE_FANOTIFY",
    });
    lib.addIncludePath("src/include");
    lib.installHeadersDirectory("src/include", "");
    lib.installConfigHeader(io_uring_ver_h, .{});
    lib.linkLibC();
    lib.install();

    const lib_tests = b.addTest(.{
        .root_source_file = .{ .path = "test/tests.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib_tests.addIncludePath("src/include");
    lib_tests.linkLibrary(lib);
    lib_tests.linkLibC();
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&lib_tests.step);
}
