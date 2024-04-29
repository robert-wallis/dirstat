# dirstat a cli directory information tool
```bash
$ dirstat
 directory: 71
      file: 109
```

# Build
```bash
$ zig build
```
Zig's advanced build system sets up all the dependencies.

# Goals
* quickly get simple stats about what's taking space in the folder

# Non-Goals
* become a DSL like `awk`, dirstat should get theoretically 80% of what an average user needs, more than that they should write their own script or tool


Copyright (C) 2024 Robert A. Wallis, all rights reserved. [License](./LICENSE)