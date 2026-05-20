const proto = @import("root.zig");

// just don't generate too many ids, ok?
pub const ResourceIDState = struct {
    // resource_id_base: u32,
    // resource_id_mask: u32,
    next: u32,
    pub fn init(setup: *const proto.setup.SetupSuccess) @This() {
        return .{
            // .resource_id_base = setup.resource_id_base,
            // .resource_id_mask = setup.resource_id_mask,
            .next = setup.resource_id_base,
        };
    }
    pub fn next_id(self: *@This()) u32 {
        const id = self.next;
        self.next += 1;
        return id;
    }
};
