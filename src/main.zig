const std = @import("std");

pub const Args = [][]const u8;
pub const Flags = std.AutoHashMap([]u8, []u8);

pub const Parsed = struct {
    args: Args,
    flags: Flags,
};


fn parse(aruguments: [][]u8) !Parsed {
    
}
