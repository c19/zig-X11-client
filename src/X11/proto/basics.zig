const std = @import("std");

// Also known as xid
pub const ResourceID = u32;
pub const Window = ResourceID;
pub const Pixmap = ResourceID;
pub const GraphicsContext = ResourceID;

pub const Drawable = extern union {
    Window: Window,
    Pixmap: Pixmap,
};
