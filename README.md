# cli.zig
Library to parse and use command line flags


## Usage
```zig
const cli = @import("cli")


pub fn main() !void {
    const parsed = try cli.parse()
    // get a flag
    const flag_value = parsed.get_flag("flag");

    // get an argument
    const argument = parsed.get_nth_arg(1);
}

```
