const std = @import("std");

const Header = packed struct {
    opcode: u8,
    length_of_4_bytes: u16,
    data: u8,
};

fn forward(reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
    while (true) {
        const byte = try reader.takeByte();
        std.log.debug("-> {X:0>2} {c}", .{ byte, byte });
        try writer.writeByte(byte);
        try writer.flush();
    }
}

fn backward(reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
    while (true) {
        const byte = try reader.takeByte();
        std.log.debug("<- {X:0>2} {c}", .{ byte, byte });
        try writer.writeByte(byte);
        try writer.flush();
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const x11_path = "/tmp/.X11-unix/X0";
    const our_path = "/tmp/.X11-unix/X1";
    const x11_addr = try std.Io.net.UnixAddress.init(x11_path);
    const our_addr = try std.Io.net.UnixAddress.init(our_path);

    var server = try our_addr.listen(io, .{});
    defer server.deinit(io);

    var rbuf: [1024]u8 = undefined;
    var wbuf: [10]u8 = undefined;
    var x11_read_buf: [1024]u8 = undefined;
    var x11_write_buf: [1024]u8 = undefined;
    var x11_conn = try x11_addr.connect(io);
    defer x11_conn.close(io);
    var x11_reader = x11_conn.reader(io, &x11_read_buf);
    var x11_writer = x11_conn.writer(io, &x11_write_buf);

    while (true) {
        var connection = try server.accept(io);
        defer connection.close(io);
        std.log.debug("connection: {f}\n", .{connection.socket.address});

        var reader = connection.reader(io, &rbuf);
        var writer = connection.writer(io, &wbuf);
        var future_forward = try io.concurrent(forward, .{ &reader.interface, &x11_writer.interface });
        var future_backward = try io.concurrent(backward, .{ &x11_reader.interface, &writer.interface });
        std.log.debug("listening...\n", .{});
        try future_forward.await(io);
        try future_backward.await(io);
    }
}
