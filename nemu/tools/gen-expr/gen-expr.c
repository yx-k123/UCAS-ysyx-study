/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>

// this should be enough
static char buf[65536] = {};
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";

static int buf_pos = 0;

static inline int choose(int n) {
    return rand() % n;
}

static void gen_expr(int depth) {
    if (depth == 0) {
        buf_pos += sprintf(buf + buf_pos, "%uu", choose(100) + 1);
        return;
    }
    int type = choose(3);

    if (type == 0) {
        buf_pos += sprintf(buf + buf_pos, "%uu", choose(100) + 1);
    } 
    else if (type == 1) {
        buf_pos += sprintf(buf + buf_pos, "(");
        gen_expr(depth - 1);
        buf_pos += sprintf(buf + buf_pos, ")");
    } 
    else { // type == 2
        gen_expr(depth - 1);
        char op = "+-*/"[choose(4)];
        buf_pos += sprintf(buf + buf_pos, " %c ", op);
        
        if (op == '/') {
            buf_pos += sprintf(buf + buf_pos, "%uu", choose(99) + 1);
        } else {
            gen_expr(depth - 1);
        }
    }
}

static void gen_rand_expr() {
    buf_pos = 0;
    buf[0] = '\0'; 

    gen_expr(5); 
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i;
  for (i = 0; i < loop; i ++) {
    gen_rand_expr();

    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc /tmp/.code.c -o /tmp/.expr");
    if (ret != 0) continue;

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    ret = fscanf(fp, "%d", &result);
    pclose(fp);

    printf("%u %s\n", result, buf);
  }
  return 0;
}
