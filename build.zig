const std = @import("std");

const RequirementError = error{
    UnsupportedArch,
    UnsupportedOS,
};

pub fn build(b: *std.build.Builder) RequirementError!void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const cross_target = b.standardTargetOptions(.{});

    // Ensure Chez actually supports our target
    //
    // This is currently a bit of a hack. We should really be
    // generating machine type codes and checking them or something
    // along those lines.
    // const target = (try std.zig.system.NativeTargetInfo.detect(gpa, cross_target)).target;
    // if (!target.cpu.arch.isX86()) {
    //     switch (target.os.tag) {
    //         .linux => {},
    //         else => return RequirementError.UnsupportedArch,
    //     }
    // } else {
    //     switch (target.os.tag) {
    //         .linux, .macos, .windows => {},
    //         else => return RequirementError.UnsupportedOS,
    //     }
    // }

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zig-chez", "src/main.zig");
    exe.setTarget(cross_target);
    exe.setBuildMode(mode);

    exe.linkLibC();

    const chez_kernel = b.addStaticLibrary("kernel", null);
    chez_kernel.setTarget(cross_target);
    chez_kernel.setBuildMode(mode);
    chez_kernel.linkLibC();
    chez_kernel.addCSourceFiles(&.{
        "libs/ChezScheme/c/statics.c",
        "libs/ChezScheme/c/segment.c",
        "libs/ChezScheme/c/alloc.c",
        "libs/ChezScheme/c/symbol.c",
        "libs/ChezScheme/c/intern.c",
        "libs/ChezScheme/c/gcwrapper.c",
        "libs/ChezScheme/c/gc-011.c",
        "libs/ChezScheme/c/gc-ocd.c",
        "libs/ChezScheme/c/gc-oce.c",
        "libs/ChezScheme/c/number.c",
        "libs/ChezScheme/c/schsig.c",
        "libs/ChezScheme/c/io.c",
        "libs/ChezScheme/c/new-io.c",
        "libs/ChezScheme/c/print.c",
        "libs/ChezScheme/c/fasl.c",
        "libs/ChezScheme/c/stats.c",
        "libs/ChezScheme/c/foreign.c",
        "libs/ChezScheme/c/prim.c",
        "libs/ChezScheme/c/prim5.c",
        "libs/ChezScheme/c/flushcache.c",
        "libs/ChezScheme/c/schlib.c",
        "libs/ChezScheme/c/thread.c",
        "libs/ChezScheme/c/expeditor.c",
        "libs/ChezScheme/c/scheme.c",
        "libs/ChezScheme/c/compress-io.c",
        // Hardcoding this, again...
        "libs/ChezScheme/c/i3le.c",
    }, &.{
        "-Wall",
        "-W",
        "-Wstrict-prototypes",
        "-Wwrite-strings",
        "-Wno-missing-field-initializers",
        // Actually important parts
        "-DDISABLE_CURSES",
        "-DDISABLE_X11",
        "-DUSE_OSSP_UUID",
        // What a terrible night for a curse
        "-fno-sanitize=undefined",
        "-DX86_64",
    });

    // Just shove everything into the generated dir :)
    chez_kernel.addIncludeDir("generated/ChezScheme/");
    chez_kernel.addIncludeDir("include/");

    // Currently everything just sits in this include dir. I want to
    // generate this all.
    exe.addIncludeDir("include/");
    exe.linkLibrary(chez_kernel);

    const zlib = b.addStaticLibrary("z", null);
    zlib.setTarget(cross_target);
    zlib.setBuildMode(mode);
    zlib.linkLibC();
    zlib.addCSourceFiles(&.{
        "libs/ChezScheme/zlib/adler32.c",
        "libs/ChezScheme/zlib/crc32.c",
        "libs/ChezScheme/zlib/deflate.c",
        "libs/ChezScheme/zlib/infback.c",
        "libs/ChezScheme/zlib/inffast.c",
        "libs/ChezScheme/zlib/inflate.c",
        "libs/ChezScheme/zlib/inftrees.c",
        "libs/ChezScheme/zlib/trees.c",
        "libs/ChezScheme/zlib/zutil.c",
        "libs/ChezScheme/zlib/compress.c",
        "libs/ChezScheme/zlib/uncompr.c",
        "libs/ChezScheme/zlib/gzclose.c",
        "libs/ChezScheme/zlib/gzlib.c",
        "libs/ChezScheme/zlib/gzread.c",
        "libs/ChezScheme/zlib/gzwrite.c",
    }, &.{
        "-Wall",
        "-W",
        "-Wmissing-prototypes",
        "-Wstrict-prototypes",
        "-Wwrite-strings",
        "-Wconversion",
        "-Wpointer-arith",
        "-Wno-missing-field-initializers",
        // Actually important
        "-DZ_HAVE_UNISTD_H",
        "-DZ_HAVE_STDARG_H",
        "-D_LARGEFILE64_SOURCE",
    });

    chez_kernel.addIncludeDir("libs/ChezScheme/zlib/");
    exe.linkLibrary(zlib);

    const lz4 = b.addStaticLibrary("lz4", null);
    lz4.setTarget(cross_target);
    lz4.setBuildMode(mode);
    lz4.linkLibC();
    lz4.addCSourceFiles(&.{
        "libs/ChezScheme/lz4/lib/lz4.c",
        "libs/ChezScheme/lz4/lib/lz4frame.c",
        "libs/ChezScheme/lz4/lib/lz4hc.c",
        "libs/ChezScheme/lz4/lib/xxhash.c",
    }, &.{
        "-Wall",
        "-W",
        "-Wstrict-prototypes",
        "-Wwrite-strings",
        "-Wno-missing-field-initializers",
        // Actually important
        "-m64",
    });

    chez_kernel.addIncludeDir("libs/ChezScheme/lz4/lib/");
    exe.linkLibrary(lz4);

    const uuid = b.addStaticLibrary("uuid", null);
    uuid.setTarget(cross_target);
    uuid.setBuildMode(mode);
    uuid.linkLibC();
    uuid.addCSourceFiles(&.{
        "libs/ossp-uuid/uuid.c",
        "libs/ossp-uuid/uuid_md5.c",
        "libs/ossp-uuid/uuid_sha1.c",
        "libs/ossp-uuid/uuid_prng.c",
        "libs/ossp-uuid/uuid_mac.c",
        "libs/ossp-uuid/uuid_time.c",
        "libs/ossp-uuid/uuid_ui64.c",
        "libs/ossp-uuid/uuid_ui128.c",
        "libs/ossp-uuid/uuid_str.c",
    }, &.{
        "-Wall",
        "-W",
        "-Wstrict-prototypes",
        "-Wwrite-strings",
        "-Wno-missing-field-initializers",
    });

    uuid.addIncludeDir("generated/ossp-uuid/");
    // Copied over currently due to ossp-uuid having uuid.h.in, not
    // uuid.h. TODO is implement a "IncludeStep" of some sort that
    // handles this and scheme.h shenanigans.
    chez_kernel.addIncludeDir("include/");
    exe.linkLibrary(uuid);

    // exe.linkSystemLibrary("ncurses");
    // exe.linkSystemLibrary("x11");
    // exe.linkSystemLibrary("uuid");

    // const nix_chez_kernel_path = std.os.getenv("NIX_CHEZ_KERNEL_OBJ") orelse
    //     return error.EnvironmentVariableNotFound;
    // exe.addObjectFile(nix_chez_kernel_path);

    // exe.addIncludeDir("./include");

    exe.install();

    // const run_cmd = exe.run();
    // run_cmd.step.dependOn(b.getInstallStep());
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);

    // const exe_tests = b.addTest("src/main.zig");
    // exe_tests.setTarget(cross_target);
    // exe_tests.setBuildMode(mode);

    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&exe_tests.step);
}
