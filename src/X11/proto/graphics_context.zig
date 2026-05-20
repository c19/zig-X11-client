const std = @import("std");
const Io = std.Io;
const Drawable = @import("./basics.zig").Drawable;
const Pixmap = @import("./basics.zig").Pixmap;
const Font = @import("./basics.zig").Font;
const GraphicsContext = @import("./basics.zig").GraphicsContext;

pub const Function = enum(u32) {
    clear = 0,
    @"and" = 1,
    andReverse = 2,
    copy = 3,
    andInverted = 4,
    noop = 5,
    xor = 6,
    @"or" = 7,
    nor = 8,
    equiv = 9,
    invert = 10,
    orReverse = 11,
    copyInverted = 12,
    orInverted = 13,
    nand = 14,
    set = 15,
};

pub const LineStyle = enum(u32) {
    Solid = 0,
    OnOffDash = 1,
    DoubleDash = 2,
};

pub const CapStyle = enum(u32) {
    NotLast = 0,
    Butt = 1,
    Round = 2,
    Projecting = 3,
};

pub const JoinStyle = enum(u32) {
    Miter = 0,
    Round = 1,
    Bevel = 2,
};

pub const FillStyle = enum(u32) {
    Solid = 0,
    Tiled = 1,
    Stippled = 2,
    OpaqueStippled = 3,
};

pub const FillRule = enum(u32) {
    EvenOdd = 0,
    Winding = 1,
};

pub const SubwindowMode = enum(u32) {
    ClipByChildren = 0,
    IncludeInferiors = 1,
};

pub const ArcMode = enum(u32) {
    Chord = 0,
    PieSlice = 1,
};

pub const GraphicsContextMask = packed struct(u32) {
    Function: u1 = 0,
    PlaneMask: u1 = 0,
    Foreground: u1 = 0,
    Background: u1 = 0,
    LineWidth: u1 = 0,
    LineStyle: u1 = 0,
    CapStyle: u1 = 0,
    JoinStyle: u1 = 0,
    FillStyle: u1 = 0,
    FillRule: u1 = 0,
    Tile: u1 = 0,
    Stipple: u1 = 0,
    TileStippleOriginX: u1 = 0,
    TileStippleOriginY: u1 = 0,
    Font: u1 = 0,
    SubwindowMode: u1 = 0,
    GraphicsExposures: u1 = 0,
    ClipOriginX: u1 = 0,
    ClipOriginY: u1 = 0,
    ClipMask: u1 = 0,
    DashOffset: u1 = 0,
    DashList: u1 = 0,
    ArcMode: u1 = 0,
    _: u9 = 0,
};

pub const GraphicsContextValues = struct {
    Function: ?Function = null,
    PlaneMask: ?u32 = null,
    Foreground: ?u32 = null,
    Background: ?u32 = null,
    LineWidth: ?u32 = null,
    LineStyle: ?LineStyle = null,
    CapStyle: ?CapStyle = null,
    JoinStyle: ?JoinStyle = null,
    FillStyle: ?FillStyle = null,
    FillRule: ?FillRule = null,
    Tile: ?Pixmap = null,
    Stipple: ?Pixmap = null,
    TileStippleOriginX: ?i32 = null,
    TileStippleOriginY: ?i32 = null,
    Font: ?Font = null,
    SubwindowMode: ?SubwindowMode = null,
    GraphicsExposures: ?bool = null,
    ClipOriginX: ?i32 = null,
    ClipOriginY: ?i32 = null,
    ClipMask: ?Pixmap = null,
    DashOffset: ?u32 = null,
    DashList: ?u32 = null,
    ArcMode: ?ArcMode = null,
};

pub const CreateGraphicsContext = extern struct {
    opcode: u8 = 55,
    pad_1: u8 = 0,
    length: u16,
    graphics_context: GraphicsContext,
    drawable: Drawable,
    value_mask: GraphicsContextMask,
    pub fn to_writer(writer: *Io.Writer, graphics_context: GraphicsContext, drawable: Drawable, values: GraphicsContextValues) !*@This() {
        const length = len(values);
        const slice: []align(4) u8 = @alignCast(try writer.writableSlice(length));
        return to_slice(slice, graphics_context, drawable, values);
    }
    fn len(values: GraphicsContextValues) u16 {
        var mask_count: u16 = 0;
        {
            inline for (@typeInfo(GraphicsContextValues).@"struct".fields) |field| {
                if (@field(values, field.name) != null)
                    mask_count += 1;
            }
        }
        return @sizeOf(@This()) + @sizeOf(u32) * mask_count;
    }
    pub fn to_slice(buffer: []align(4) u8, graphics_context: GraphicsContext, drawable: Drawable, values: GraphicsContextValues) !*@This() {
        const length = len(values);
        if (buffer.len < length) return error.BufferTooSmall;
        var one: *@This() = @ptrCast(buffer.ptr);
        one.opcode = 55;
        one.pad_1 = 0;
        one.length = length / 4;
        one.graphics_context = graphics_context;
        one.drawable = drawable;
        var value_mask: GraphicsContextMask = .{};
        var slice: []u8 = buffer[@sizeOf(@This())..];
        inline for (@typeInfo(GraphicsContextValues).@"struct".fields) |field| {
            if (@field(values, field.name)) |value| {
                @field(value_mask, field.name) = 1;
                switch (@TypeOf(value)) {
                    bool => {
                        const casted: u32 = @intFromBool(value);
                        std.mem.writeInt(u32, slice.ptr[0..4], casted, .little);
                    },
                    else => {
                        if (@typeInfo(@TypeOf(value)) == .@"enum") {
                            const casted: u32 = @intFromEnum(value);
                            std.mem.writeInt(u32, slice.ptr[0..4], casted, .little);
                        } else {
                            std.mem.writeInt(@TypeOf(value), slice.ptr[0..4], value, .little);
                        }
                    },
                }
                slice = slice[4..];
            }
        }
        one.value_mask = value_mask;
        return one;
    }
    pub fn size(self: *const @This()) u16 {
        return self.length * 4;
    }
};

test "CreateGraphicsContext" {
    var buf: [24]u8 align(4) = undefined;
    const create: *CreateGraphicsContext = try .to_slice(&buf, 0x05C00000, .{ .Window = 0x01EB }, .{ .Foreground = 0, .GraphicsExposures = false });
    _ = create;
    const expected: [24]u8 = .{ 0x37, 0x00, 0x06, 0x00, 0x00, 0x00, 0xC0, 0x05, 0xEB, 0x01, 0x00, 0x00, 0x04, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
    try std.testing.expectEqualSlices(u8, &expected, &buf);
}
