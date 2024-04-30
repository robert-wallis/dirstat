# dirstat a cli directory information tool
```bash
$ dirstat --help
usage:  dirstat [-k][-v][-a][-d] [path [path ...]]
        -k --key        sort by key
                        key is sorted by alphabetically unless -d is used
        -v --value      sort by Value
                        value is the default sort
                        value is sorted by largest to smallest unless -a is used
        -a --key-asc --value-asc        sort by value acending, lowest to highest
        -d --value-desc --value-desc    sort by value descending, highest to lowest
        -b --bytes      output just bytes, 1048576 is shown instead of 1M
```

## Example
```bash
$ dirstat
path: .

kind:
608     file
343     directory

bytes by kind:
394M    file
50K     directory

extension:
114     .o
86      .txt
14      .sample
8       .zig
1       .zon
1       .gitignore
1       .1
1       .yml
1       .md
1       .2
1       .json

bytes by extension:
246M    .o
76K     .txt
25K     .sample
24K     .zig
3K      .zon
509B    .md
70B     .yml
51B     .json
41B     .1
41B     .2
20B     .gitignore
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