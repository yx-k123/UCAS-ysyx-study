# about mtrace and ftrace

use this for mtrace
```sh
grep -n "MTRACE:" build/nemu-log.txt
```
use this for ftrace
```sh
grep -n "call \\[\\|ret \\[" build/nemu-log.txt
```