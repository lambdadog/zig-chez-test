const std = @import("std");

const scheme = @cImport({
    @cDefine("SCHEME_STATIC", "1");
    @cInclude("scheme.h");
});

fn abnormal_exit() callconv(.C) void {
    std.log.err("Abnormal exit.", .{});
    std.os.exit(1);
}

pub fn main() anyerror!void {
    std.log.info("Initializing Chez.", .{});
    scheme.Sscheme_init(abnormal_exit);

    scheme.Sset_verbose(1);

    std.log.info("Registering boot files.", .{});
    scheme.Sregister_boot_file("./libs/ChezScheme/boot/ta6le/petite.boot");
    scheme.Sregister_boot_file("./libs/ChezScheme/boot/ta6le/scheme.boot");

    std.log.info("Building heap.", .{});
    scheme.Sbuild_heap(null, null);

    scheme.Senable_expeditor(null);

    std.log.info("Kernel version is: {s}", .{scheme.Skernel_version()});

    std.log.info("Starting scheme.", .{});

    _ = scheme.Sscheme_start(0, null);
}
