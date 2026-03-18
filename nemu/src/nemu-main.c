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

#include <common.h>
/* for expr() */
#include "monitor/sdb/sdb.h"
#include <stdio.h>
#include <stdlib.h>

// #define TEST_EXPR

void init_monitor(int, char *[]);
void am_init_monitor();
void engine_start();
int is_exit_status_bad();

int main(int argc, char *argv[]) {
  /* Initialize the monitor. */
#ifdef CONFIG_TARGET_AM
  am_init_monitor();
#else
  init_monitor(argc, argv);
#endif

#ifdef TEST_EXPR
  /* Try reading test expressions from tools/gen-expr/build/input. */
  FILE *fp = fopen("tools/gen-expr/build/input", "r");
  if (fp) {
    char *line = NULL;
    size_t len = 0;
    while (getline(&line, &len, fp) != -1) {
      char *p = line;
      while (*p == ' ' || *p == '\t') p++;
      if (*p == '\0' || *p == '\n') continue;

      char *sep = strchr(p, ' ');
      if (!sep) continue;
      *sep = '\0';
      unsigned long long expected = strtoull(p, NULL, 10);
      char *expr_src = sep + 1;
      char *nl = strchr(expr_src, '\n');
      if (nl) *nl = '\0';

      /* strip 'u' suffixes which expr() doesn't accept */
      char buf[1024];
      int bi = 0;
      for (int i = 0; expr_src[i] && bi < (int)sizeof(buf) - 1; i++) {
        if (expr_src[i] == 'u') continue;
        buf[bi++] = expr_src[i];
      }
      buf[bi] = '\0';

      bool ok = false;
      word_t val = expr(buf, &ok);
      unsigned long long got = (unsigned long long)val;
      if (!ok) {
        printf("expr parse failed: %s\n", buf);
        free(line);
        fclose(fp);
        return 1;
      }
      if (got != expected) {
        printf("mismatch: expected %llu, got %llu, expr=%s\n", expected, got, buf);
        free(line);
        fclose(fp);
        return 1;
      }
    }
    free(line);
    fclose(fp);
  }
#endif

  /* Start engine. */
  engine_start();

  return is_exit_status_bad();
}
