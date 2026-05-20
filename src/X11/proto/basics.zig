const std = @import("std");

// Also known as xid
pub const ResourceID = u32;
pub const Window = ResourceID;
pub const Pixmap = ResourceID;
pub const Font = ResourceID;
pub const GraphicsContext = ResourceID;
pub const ColorMap = ResourceID;
pub const Cursor = ResourceID;

pub const VisualID = u32;

pub const Drawable = extern union {
    Window: Window,
    Pixmap: Pixmap,
};

pub const Format = extern struct {
    depth: u8,
    bits_per_pixel: u8,
    scanline_pad: u8,
    pad_1: [5]u8,
};

pub const VisualType = extern struct {
    visual_id: u32,
    class: VisualClass,
    bits_per_rgb_value: u8,
    colormap_entries: u16,
    red_mask: u32,
    green_mask: u32,
    blue_mask: u32,
    pad_1: [4]u8,
};

pub const EventMask = packed struct(u32) {
    KeyPress: u1 = 0,
    KeyRelease: u1 = 0,
    ButtonPress: u1 = 0,
    ButtonRelease: u1 = 0,
    EnterWindow: u1 = 0,
    LeaveWindow: u1 = 0,
    PointerMotion: u1 = 0,
    PointerMotionHint: u1 = 0,
    Button1Motion: u1 = 0,
    Button2Motion: u1 = 0,
    Button3Motion: u1 = 0,
    Button4Motion: u1 = 0,
    Button5Motion: u1 = 0,
    ButtonMotion: u1 = 0,
    KeymapState: u1 = 0,
    Exposure: u1 = 0,
    VisibilityChange: u1 = 0,
    StructureNotify: u1 = 0,
    ResizeRedirect: u1 = 0,
    SubstructureNotify: u1 = 0,
    SubstructureRedirect: u1 = 0,
    FocusChange: u1 = 0,
    PropertyChange: u1 = 0,
    ColorMapChange: u1 = 0,
    OwnerGrabButton: u1 = 0,
    _: u7 = 0,
};

pub const BackingStore = enum(u8) {
    NotUseful = 0,
    WhenMapped = 1,
    Always = 2,
};

pub const VisualClass = enum(u8) {
    StaticGray = 0,
    GrayScale = 1,
    StaticColor = 2,
    PseudoColor = 3,
    TrueColor = 4,
    DirectColor = 5,
};

pub const ImageOrder = enum(u8) {
    LSBFirst = 0,
    MSBFirst = 1,
};
