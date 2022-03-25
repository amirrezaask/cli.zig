const std = @import("std");
const print = std.debug.print;

const Args = [][]const u8;
const Flags = std.StringHashMap([]const u8);

const Parsed = struct {
    allocator: std.mem.Allocator,
    args: Args,
    flags: Flags,
    // calls deinit on internal HashMap holding flags and array holding arguments.
    pub fn deinit(self: *Parsed) void {
        self.flags.deinit();
        self.allocator.free(self.args);
    }
    pub fn get_flag(self: Parsed, name: []const u8) ?[]const u8 {
        return self.flags.get(name);
    }
    pub fn get_nth_arg(self: Parsed, n: usize) []const u8 {
        return self.args[n];
    }
    pub fn get_args(self: Parsed) [][]const u8 {
        return self.args;
    }
    pub fn get_flags(self: Parsed) ![][2][]const u8 {
        var tuples = std.ArrayList([2][]const u8).init(self.allocator);
        print("{}", .{self.flags.count()});
        var iter = self.flags.keyIterator();
        while (iter.next()) |key| {
            try tuples.append([2][]const u8{ key.*, self.flags.get(key.*).? });
        }

        return tuples.items;
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

fn parse_arguments(allocator: std.mem.Allocator, arguments: [][]const u8) !Parsed {
    var args = std.ArrayList([]const u8).init(allocator);
    var flags = Flags.init(allocator);
    var i: usize = 0;
    while (i < arguments.len) : (i += 1) {
        const arg = arguments[i];
        if (is_flag(arg)) |is_flag_val| {
            switch (is_flag_val) {
                .single_dash => {
                    try flags.put(arg[1..], arguments[i + 1]);
                    i += 1;
                    continue;
                },
                .double_dash => {
                    try flags.put(arg[2..], arguments[i + 1]);
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

pub fn parse(
    allocator: std.mem.Allocator,
) !Parsed {
    var argv = std.ArrayList([]const u8).init(allocator);
    var i: usize = 0;

    while (i < std.os.argv.len) : (i += 1) {
        try argv.append(std.mem.span(std.os.argv[i]));
    }
    return parse_arguments(
        allocator,
        argv.items,
    );
}

test "cli.argument should be added to args array when parsed" {
    const a = std.testing.allocator;
    var args = std.ArrayList([]const u8).init(a);
    defer args.deinit();
    try args.append("a");
    var parsed = try parse_arguments(a, args.items);
    defer parsed.deinit();
    try std.testing.expectEqualStrings("a", parsed.get_nth_arg(0));
}
test "cli.single dash flag should be added to flags map" {
    const a = std.testing.allocator;
    var args = std.ArrayList([]const u8).init(a);
    defer args.deinit();
    try args.append("-b");
    try args.append("b");
    var parsed = try parse_arguments(a, args.items);
    defer parsed.deinit();
    try std.testing.expectEqualStrings("b", parsed.get_flag("b").?);
}

test "cli.double dash flag should be added to flags map" {
    const a = std.testing.allocator;
    var args = std.ArrayList([]const u8).init(a);
    defer args.deinit();
    try args.append("--b");
    try args.append("b");
    var parsed = try parse_arguments(a, args.items);
    defer parsed.deinit();
    try std.testing.expectEqualStrings("b", parsed.get_flag("b").?);
}

test "cli.mixed flags" {
    const a = std.testing.allocator;
    var args = std.ArrayList([]const u8).init(a);
    defer args.deinit();
    try args.append("--b");
    try args.append("b");
    try args.append("-c");
    try args.append("b");
    var parsed = try parse_arguments(a, args.items);
    defer parsed.deinit();
    try std.testing.expectEqualStrings("b", parsed.get_flag("b").?);
    try std.testing.expectEqualStrings("b", parsed.get_flag("c").?);
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
    var parsed = try parse_arguments(a, args.items);
    defer parsed.deinit();
    try std.testing.expectEqualStrings("b", parsed.get_flag("b").?);
    try std.testing.expectEqualStrings("b", parsed.get_flag("c").?);
    try std.testing.expectEqualStrings("a", parsed.get_nth_arg(0));
}
