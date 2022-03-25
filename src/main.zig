const std = @import("std");

pub const Args = [][]const u8;
pub const Flags = std.AutoHashMap([]u8, []u8);

pub const Parsed = struct {
    args: Args,
    flags: Flags,
};
const FlagType = enum {
    single_dash,
    double_dash,
};
fn is_flag(arg: []u8) ?FlagType {
    if (arg[0] == '-' and arg[1] == '-') return FlagType.double_dash;
    if (arg[0] == '-' and arg[1] != '-') return FlagType.single_dash;
    return null;
}

fn parse(allocator: std.mem.Allocator, aruguments: [][]u8) !Parsed {
    var args = std.ArrayList([]u8).init(allocator);
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
        .args = args.items,
        .flags = flags,
    };
}

test "sample" {
    const a = std.testing.allocator;
    const parsed = try parse(a, &[_][]u8{ "a", "--b", "b", "-c", "c" });
    std.testing.expectEqualStrings("b", parsed.flags.get("b").?);
}
