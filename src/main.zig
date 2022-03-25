const std = @import("std");
const print = std.debug.print;

pub const Args = [][]const u8;
pub const Flags = std.StringHashMap([]const u8);

pub const Parsed = struct {
    allocator: std.mem.Allocator,
    args: Args,
    flags: Flags,
    pub fn deinit(self: *Parsed) void {
        self.flags.deinit();
        self.allocator.free(self.args);
    }
};
const FlagType = enum {
    single_dash,
    double_dash,
};
fn is_flag(arg: []const u8) ?FlagType {
    if (arg[0] == '-' and arg[1] == '-') return FlagType.double_dash;
    if (arg[0] == '-' and arg[1] != '-') return FlagType.single_dash;
    return null;
}

fn parse(allocator: std.mem.Allocator, aruguments: [][]const u8) !Parsed {
    var args = std.ArrayList([]const u8).init(allocator);
    var flags = Flags.init(allocator);
    var i: usize = 0;
    while (i < aruguments.len) : (i += 1) {
        const arg = aruguments[i];
        if (is_flag(arg)) |is_flag_val| {
            switch (is_flag_val) {
                .single_dash => {
                    try flags.put(arg[1..], aruguments[i + 1]);
                    i += 1;
                    continue;
                },
                .double_dash => {
                    try flags.put(arg[2..], aruguments[i + 1]);
                    i += 1;
                    continue;
                },
            }
        } else {
            try args.append(arg);
        }
    }
    return Parsed{
        .allocator = allocator,
        .args = args.items,
        .flags = flags,
    };
}

test "cli.argument should be added to args array when parsed" {
    const a = std.testing.allocator;
    var args = std.ArrayList([]const u8).init(a);
    defer args.deinit();
    try args.append("a");
    var parsed = try parse(a, args.items);
    defer parsed.deinit();
    try std.testing.expectEqualStrings("a", parsed.args[0]);
}
test "cli.single dash flag should be added to flags map" {
    const a = std.testing.allocator;
    var args = std.ArrayList([]const u8).init(a);
    defer args.deinit();
    try args.append("-b");
    try args.append("b");
    var parsed = try parse(a, args.items);
    defer parsed.deinit();
    try std.testing.expectEqualStrings("b", parsed.flags.get("b").?);
}

test "cli.double dash flag should be added to flags map" {
    const a = std.testing.allocator;
    var args = std.ArrayList([]const u8).init(a);
    defer args.deinit();
    try args.append("--b");
    try args.append("b");
    var parsed = try parse(a, args.items);
    defer parsed.deinit();
    try std.testing.expectEqualStrings("b", parsed.flags.get("b").?);
}

test "cli.mixed flags" {
    const a = std.testing.allocator;
    var args = std.ArrayList([]const u8).init(a);
    defer args.deinit();
    try args.append("--b");
    try args.append("b");
    try args.append("-c");
    try args.append("b");
    var parsed = try parse(a, args.items);
    defer parsed.deinit();
    try std.testing.expectEqualStrings("b", parsed.flags.get("b").?);
    try std.testing.expectEqualStrings("b", parsed.flags.get("c").?);
}

test "cli.mixed flags and args" {
    const a = std.testing.allocator;
    var args = std.ArrayList([]const u8).init(a);
    defer args.deinit();
    try args.append("a");
    try args.append("--b");
    try args.append("b");
    try args.append("-c");
    try args.append("b");
    var parsed = try parse(a, args.items);
    defer parsed.deinit();
    try std.testing.expectEqualStrings("b", parsed.flags.get("b").?);
    try std.testing.expectEqualStrings("b", parsed.flags.get("c").?);
    try std.testing.expectEqualStrings("a", parsed.args[0]);
}
