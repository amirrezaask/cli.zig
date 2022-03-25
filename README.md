# cli.zig
Library to parse and use command line flags


## Usage
```zig
const cli = @import("cli")


pub fn main() !void {
    const flags = try cli.parse()
}

```
