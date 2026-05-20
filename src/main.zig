const std = @import("std");
const Io = std.Io;

const proto = @import("X11/proto/root.zig");
const SetupReplyStatus = proto.setup.SetupReplyStatus;
const SetupSuccess = proto.setup.SetupSuccess;
const CreateGraphicsContext = proto.graphics_context.CreateGraphicsContext;
const CreateWindow = proto.window.CreateWindow;
const ChangeProperty = proto.window.ChangeProperty;
const WindowName = proto.window.WindowName;
const SizeHints = proto.window.SizeHints;
const MapWindow = proto.window.MapWindow;
const ResourceIDState = @import("X11/proto/xid.zig").ResourceIDState;

pub fn main(init: std.process.Init) !u8 {
    const io = init.io;
    const path = "/tmp/.X11-unix/X0";
    const addr: Io.net.UnixAddress = try .init(path);
    var conn = try addr.connect(io);
    defer conn.close(io);

    // align(4) as the requirment of X11 protocol.
    // this saves us from coping the bytes around.
    var read_buf: [64 * 1024]u8 align(4) = undefined;
    var write_buf: [64 * 1024]u8 align(4) = undefined;
    var reader = conn.reader(io, &read_buf);
    var writer = conn.writer(io, &write_buf);

    const req: proto.setup.SetupRequest = .{};
    const setup_req_bytes: [@sizeOf(proto.setup.SetupRequest)]u8 = @bitCast(req);
    try writer.interface.writeAll(&setup_req_bytes);
    try writer.interface.flush();

    // X11 handles
    var xid: ResourceIDState = undefined;
    var graphics_context: proto.basics.Window = undefined;
    var window: proto.basics.Window = undefined;

    const status: SetupReplyStatus = @enumFromInt(try reader.interface.peekByte());

    switch (status) {
        .Success => {
            const setup: *const SetupSuccess = try .from_reader(&reader.interface);
            var screens = try setup.screens();
            const root = (try screens.next()).?;
            const screen = root.root;
            const visual = root.root_visual;
            const white = root.white_pixel;
            xid = .init(setup);
            graphics_context = xid.next_id();
            window = xid.next_id();

            _ = try CreateGraphicsContext.to_writer(
                &writer.interface,
                graphics_context,
                .{ .Window = screen },
                .{ .Foreground = 0, .GraphicsExposures = false },
            );

            _ = try CreateWindow.init_with_writer(&writer.interface, .{
                .parent = screen,
                .window = window,
                .visual = visual,
            }, .{
                .BackPixel = white,
                .EventMask = .{ .Exposure = 1, .ResizeRedirect = 1 },
            });

            _ = try ChangeProperty.init_with_writer(&writer.interface, window, WindowName{ .name = "Zig X11 Client" });
            _ = try ChangeProperty.init_with_writer(&writer.interface, window, SizeHints{ .min_width = 800, .min_height = 600, .flags = .{ .P_MIN_SIZE = 1 } });

            _ = try writer.interface.writeStruct(MapWindow{ .window = window }, .little);
            try writer.interface.flush();

            try io.sleep(.fromSeconds(100), .real);
        },
        .Failed => {
            const setup: *const proto.setup.SetupFailed = try .from_slice(@alignCast(reader.interface.buffered()));
            std.debug.print("{any}\n", .{setup});
            std.debug.print("reason: {s}\n", .{try setup.reason()});
            return 1;
        },
        .Authenticate => {
            const setup: *const proto.setup.SetupAuthenticate = try .from_slice(@alignCast(reader.interface.buffered()));
            std.debug.print("{any}\n", .{setup});
            std.debug.print("reason: {s}\n", .{try setup.reason()});
            return 2;
        },
    }
    return 0;
}
