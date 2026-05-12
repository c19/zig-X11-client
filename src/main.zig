const std = @import("std");
const Io = std.Io;
const proto = @import("proto.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const path = "/tmp/.X11-unix/X0";
    const addr: Io.net.UnixAddress = try .init(path);
    var conn = try addr.connect(io);
    defer conn.close(io);

    var read_buf: [64 * 1024]u8 = undefined;
    var write_buf: [64 * 1024]u8 = undefined;
    var reader = conn.reader(io, &read_buf);
    var writer = conn.writer(io, &write_buf);

    const req: proto.SetupRequest = .{};
    const setup_req_bytes: [@sizeOf(proto.SetupRequest)]u8 = @bitCast(req);
    try writer.interface.writeAll(&setup_req_bytes);
    try writer.interface.flush();

    var reader_buf: [64 * 1024]u8 = undefined;
    var data: [1][]u8 = .{&reader_buf};
    while (true) {
        const n = try reader.interface.readVec(&data);

        for (reader_buf[0..n]) |byte| {
            std.log.debug("{X:0>2}", .{byte});
        }
        std.log.debug("----------", .{});
    }
}
