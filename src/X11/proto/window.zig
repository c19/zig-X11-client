const std = @import("std");
const Io = std.Io;
const Drawable = @import("./basics.zig").Drawable;
const Window = @import("./basics.zig").Window;
const Pixmap = @import("./basics.zig").Pixmap;
const Font = @import("./basics.zig").Font;
const ColorMap = @import("./basics.zig").ColorMap;
const Cursor = @import("./basics.zig").Cursor;
const VisualID = @import("./basics.zig").VisualID;
const GraphicsContext = @import("./basics.zig").GraphicsContext;
const BackingStore = @import("./basics.zig").BackingStore;
const EventMask = @import("./basics.zig").EventMask;

pub const WindowClass = enum(u16) {
    CopyFromParent = 0,
    InputOutput = 1,
    InputOnly = 2,
};

pub const BackPixmap = enum(u32) {
    None = 0,
    ParentRelative = 1,
};

pub const Gravity = enum(u32) {
    BitForget_WinUnmap = 0,
    NorthWest = 1,
    North = 2,
    NorthEast = 3,
    West = 4,
    Center = 5,
    East = 6,
    SouthWest = 7,
    South = 8,
    SouthEast = 9,
    Static = 10,
};

pub const CreateWindowMask = packed struct(u32) {
    BackPixmap: u1 = 0,
    BackPixel: u1 = 0,
    BorderPixmap: u1 = 0,
    BorderPixel: u1 = 0,
    BitGravity: u1 = 0,
    WinGravity: u1 = 0,
    BackingStore: u1 = 0,
    BackingPlanes: u1 = 0,
    BackingPixel: u1 = 0,
    OverrideRedirect: u1 = 0,
    SaveUnder: u1 = 0,
    EventMask: u1 = 0,
    DontPropagate: u1 = 0,
    Colormap: u1 = 0,
    Cursor: u1 = 0,
    _: u17 = 0,
};

pub const CreateWindowValues = struct {
    BackPixmap: ?Pixmap = null,
    BackPixel: ?u32 = null,
    BorderPixmap: ?Pixmap = null,
    BorderPixel: ?u32 = null,
    BitGravity: ?Gravity = null,
    WinGravity: ?Gravity = null,
    BackingStore: ?BackingStore = null,
    BackingPlanes: ?u32 = null,
    BackingPixel: ?u32 = null,
    OverrideRedirect: ?bool = null,
    SaveUnder: ?bool = null,
    EventMask: ?EventMask = null,
    DontPropagate: ?EventMask = null,
    Colormap: ?ColorMap = null,
    Cursor: ?Cursor = null,
};

pub const CreateWindow = extern struct {
    opcode: u8 = 1,
    pad_1: u8 = 0,
    length: u16 = 0,
    window: Window,
    parent: Window,
    x: i16 = 0,
    y: i16 = 0,
    width: u16 = 800,
    height: u16 = 600,
    border_width: u16 = 10,
    class: WindowClass = .InputOutput,
    visual: VisualID,
    value_mask: CreateWindowMask = .{},
    pub fn init_with_writer(io: *Io.Writer, value: @This(), values: CreateWindowValues) !*@This() {
        const length = len(values);
        const slice: []align(4) u8 = @alignCast(try io.writableSlice(length));
        return init(slice, value, values);
    }
    fn len(values: CreateWindowValues) u16 {
        var mask_count: u16 = 0;
        {
            inline for (@typeInfo(CreateWindowValues).@"struct".fields) |field| {
                if (@field(values, field.name) != null)
                    mask_count += 1;
            }
        }
        return @sizeOf(@This()) + @sizeOf(u32) * mask_count;
    }
    pub fn init(buffer: []align(4) u8, value: @This(), values: CreateWindowValues) !*@This() {
        const length = len(values);
        if (buffer.len < length) return error.BufferTooSmall;
        var one: *@This() = @ptrCast(buffer.ptr);
        one.opcode = 1;
        one.pad_1 = 0;
        one.length = length / 4;
        one.window = value.window;
        one.parent = value.parent;
        one.x = value.x;
        one.y = value.y;
        one.width = value.width;
        one.height = value.height;
        one.border_width = value.border_width;
        one.class = value.class;
        one.visual = value.visual;
        var value_mask: CreateWindowMask = .{};
        var slice: []u8 = buffer[@sizeOf(@This())..];
        inline for (@typeInfo(CreateWindowValues).@"struct".fields) |field| {
            if (@field(values, field.name)) |val| {
                @field(value_mask, field.name) = 1;
                const casted: u32 = switch (@TypeOf(val)) {
                    bool => @intFromBool(val),
                    else => if (@typeInfo(@TypeOf(val)) == .@"enum") @intFromEnum(val) else @bitCast(val),
                };
                std.mem.writeInt(u32, slice.ptr[0..4], casted, .little);
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

test "CreateWindow" {
    var buf: [40]u8 align(4) = undefined;
    const create: *CreateWindow = try .init(&buf, .{
        .width = 800,
        .height = 600,
        .window = 0x08000001,
        .parent = 0x01EB,
        .border_width = 10,
        .class = .InputOutput,
        .visual = 0x21,
    }, .{
        .BackPixel = 0xFFFFFF,
        .EventMask = .{ .Exposure = 1, .ResizeRedirect = 1 },
    });
    std.debug.print("{any}\n", .{create});
    for (buf) |byte| {
        std.debug.print("{X:0>2}\n", .{byte});
    }
}

pub const PropMode = enum(u8) {
    Replace = 0,
    Prepend = 1,
    Append = 2,
};

pub const Atom = enum(u32) {
    None_Any = 0,
    PRIMARY = 1,
    SECONDARY = 2,
    ARC = 3,
    ATOM = 4,
    BITMAP = 5,
    CARDINAL = 6,
    COLORMAP = 7,
    CURSOR = 8,
    CUT_BUFFER0 = 9,
    CUT_BUFFER1 = 10,
    CUT_BUFFER2 = 11,
    CUT_BUFFER3 = 12,
    CUT_BUFFER4 = 13,
    CUT_BUFFER5 = 14,
    CUT_BUFFER6 = 15,
    CUT_BUFFER7 = 16,
    DRAWABLE = 17,
    FONT = 18,
    INTEGER = 19,
    PIXMAP = 20,
    POINT = 21,
    RECTANGLE = 22,
    RESOURCE_MANAGER = 23,
    RGB_COLOR_MAP = 24,
    RGB_BEST_MAP = 25,
    RGB_BLUE_MAP = 26,
    RGB_DEFAULT_MAP = 27,
    RGB_GRAY_MAP = 28,
    RGB_GREEN_MAP = 29,
    RGB_RED_MAP = 30,
    STRING = 31,
    VISUALID = 32,
    WINDOW = 33,
    WM_COMMAND = 34,
    WM_HINTS = 35,
    WM_CLIENT_MACHINE = 36,
    WM_ICON_NAME = 37,
    WM_ICON_SIZE = 38,
    WM_NAME = 39,
    WM_NORMAL_HINTS = 40,
    WM_SIZE_HINTS = 41,
    WM_ZOOM_HINTS = 42,
    MIN_SPACE = 43,
    NORM_SPACE = 44,
    MAX_SPACE = 45,
    END_SPACE = 46,
    SUPERSCRIPT_X = 47,
    SUPERSCRIPT_Y = 48,
    SUBSCRIPT_X = 49,
    SUBSCRIPT_Y = 50,
    UNDERLINE_POSITION = 51,
    UNDERLINE_THICKNESS = 52,
    STRIKEOUT_ASCENT = 53,
    STRIKEOUT_DESCENT = 54,
    ITALIC_ANGLE = 55,
    X_HEIGHT = 56,
    QUAD_WIDTH = 57,
    WEIGHT = 58,
    POINT_SIZE = 59,
    RESOLUTION = 60,
    COPYRIGHT = 61,
    NOTICE = 62,
    FONT_NAME = 63,
    FAMILY_NAME = 64,
    FULL_NAME = 65,
    CAP_HEIGHT = 66,
    WM_CLASS = 67,
    WM_TRANSIENT_FOR = 68,
};

pub const SizeHintsFlags = packed struct(u32) {
    US_POSITION: u1 = 0,
    US_SIZE: u1 = 0,
    P_POSITION: u1 = 0,
    P_SIZE: u1 = 0,
    P_MIN_SIZE: u1 = 0,
    P_MAX_SIZE: u1 = 0,
    P_RESIZE_INC: u1 = 0,
    P_ASPECT: u1 = 0,
    BASE_SIZE: u1 = 0,
    P_WIN_GRAVITY: u1 = 0,
    _: u22 = 0,
};

pub const SizeHints = extern struct {
    const property: Atom = .WM_NORMAL_HINTS;
    const type_: Atom = .WM_SIZE_HINTS;
    const format: BitLength = .bit_32;
    flags: SizeHintsFlags = .{},
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 0,
    height: i32 = 0,
    min_width: i32 = 0,
    min_height: i32 = 0,
    max_width: i32 = 0,
    max_height: i32 = 0,
    width_inc: i32 = 0,
    height_inc: i32 = 0,
    min_aspect_num: i32 = 0,
    min_aspect_den: i32 = 0,
    max_aspect_num: i32 = 0,
    max_aspect_den: i32 = 0,
    base_width: i32 = 0,
    base_height: i32 = 0,
    win_gravity: u32 = 0,
};

pub const WindowName = struct {
    const property: Atom = .WM_NAME;
    const type_: Atom = .STRING;
    const format: BitLength = .bit_8;
    name: []const u8,
};

pub const BitLength = enum(u8) {
    bit_8 = 8,
    bit_16 = 16,
    bit_32 = 32,
};

pub const ChangeProperty = extern struct {
    opcode: u8 = 18,
    pad_1: u8 = 0,
    length: u16 = 0,
    window: Window,
    property: Atom,
    type: Atom,
    format: BitLength,
    pad_2: [3]u8 = .{ 0, 0, 0 },
    data_len: u32 = 0,
    pub fn init_with_writer(io: *Io.Writer, window: Window, value: anytype) !*@This() {
        _, const length = try len(value);
        const slice: []align(4) u8 = @alignCast(try io.writableSlice(length));
        return init(slice, window, value);
    }
    fn len(value: anytype) !struct { u16, u16 } {
        const data_len: u16 = res: switch (@TypeOf(value)) {
            WindowName => {
                if (value.name.len > std.math.maxInt(u16)) return error.OverFlow;
                break :res @intCast(value.name.len);
            },
            SizeHints => {
                break :res @sizeOf(SizeHints);
            },
            else => @panic("unimplemented"),
        };

        const total_bytes: u16 = std.mem.alignForward(u16, @sizeOf(@This()) + data_len, 4);
        return .{ data_len, total_bytes };
    }
    pub fn init(buffer: []align(4) u8, window: Window, value: anytype) !*@This() {
        const data_len, const total_bytes = try len(value);
        if (total_bytes > buffer.len) return error.OverFlow;

        var one: *@This() = @ptrCast(buffer.ptr);
        one.opcode = 18;
        one.pad_1 = 0;
        one.length = total_bytes / 4;
        one.window = window;
        one.property = @TypeOf(value).property;
        one.type = @TypeOf(value).type_;
        one.format = @TypeOf(value).format;
        one.pad_2 = .{ 0, 0, 0 };

        switch (@TypeOf(value)) {
            WindowName => {
                one.data_len = data_len;
                const slice: []u8 = buffer[@sizeOf(@This()) .. @sizeOf(@This()) + value.name.len];
                const trailing: []u8 = buffer[@sizeOf(@This()) + value.name.len .. total_bytes];
                @memcpy(slice, value.name);
                @memset(trailing, 0);
            },
            SizeHints => {
                one.data_len = data_len / 4;
                const slice: []u8 = buffer[@sizeOf(@This()) .. @sizeOf(@This()) + @sizeOf(SizeHints)];
                const bytes: [@sizeOf(SizeHints)]u8 = @bitCast(value);
                @memcpy(slice, &bytes);
            },
            else => @panic("unimplemented"),
        }
        return one;
    }
    pub fn size(self: *const @This()) u16 {
        return self.length * 4;
    }
};

test "ChangeProperty_WindowName" {
    var buf: [40]u8 align(4) = undefined;
    const change: *ChangeProperty = try .init(&buf, 0x05C00001, WindowName{ .name = "Viewer Vulkan" });
    _ = change;
    const expected: [40]u8 = .{ 0x12, 0x00, 0x0A, 0x00, 0x01, 0x00, 0xC0, 0x05, 0x27, 0x00, 0x00, 0x00, 0x1F, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x0D, 0x00, 0x00, 0x00, 0x56, 0x69, 0x65, 0x77, 0x65, 0x72, 0x20, 0x56, 0x75, 0x6C, 0x6B, 0x61, 0x6E, 0x00, 0x00, 0x00 };
    try std.testing.expectEqualSlices(u8, &expected, &buf);
}

test "ChangeProperty_SizeHints" {
    var buf: [96]u8 align(4) = undefined;
    const change: *ChangeProperty = try .init(&buf, 0x05C00001, SizeHints{
        .flags = .{ .P_MIN_SIZE = 1 },
        .min_width = 800,
        .min_height = 600,
    });
    _ = change;
    const expected: [96]u8 = .{
        0x12, // opcode ChangeProperty
        0x00,
        0x18, // length
        0x00,
        0x01, // window
        0x00,
        0xC0,
        0x05,
        0x28, // property
        0x00,
        0x00,
        0x00,
        0x29, // type
        0x00,
        0x00,
        0x00,
        0x20, // format
        0x00,
        0x00,
        0x00,
        0x12, // data_len
        0x00,
        0x00,
        0x00,
        0x10, // data
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x20,
        0x03,
        0x00,
        0x00,
        0x58,
        0x02,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
    };
    try std.testing.expectEqualSlices(u8, &expected, &buf);
}

pub const MapWindow = extern struct {
    opcode: u8 = 8,
    pad: u8 = 0,
    length: u16 = @sizeOf(@This()) / 4,
    window: Window,
};

test "MapWindow" {
    const map_window: MapWindow = .{ .window = 0x05C00001 };
    const bytes: *const [@sizeOf(MapWindow)]u8 = @ptrCast(&map_window);
    const expected: [8]u8 = .{
        0x08, // opcode MapWindow
        0x00,
        0x02, // length
        0x00,
        0x01, // window
        0x00,
        0xC0,
        0x05,
    };
    try std.testing.expectEqualSlices(u8, &expected, bytes);
}
