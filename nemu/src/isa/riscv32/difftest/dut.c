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

#include <isa.h>
#include <cpu/difftest.h>
#include "../local-include/reg.h"

static bool check_gpr(const CPU_state *ref_r) {
  int gpr_count = MUXDEF(CONFIG_RVE, 16, 32);
  for (int i = 0; i < gpr_count; i++) {
    if (ref_r->gpr[i] != cpu.gpr[i]) {
      Log("Mismatch at %s: ref = " FMT_WORD ", dut = " FMT_WORD,
          reg_name(i), ref_r->gpr[i], cpu.gpr[i]);
      return false;
    }
  }
  return true;
}

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  if (ref_r->pc != pc) {
    Log("Mismatch at pc: ref = " FMT_WORD ", dut = " FMT_WORD, ref_r->pc, pc);
    return false;
  }
  return check_gpr(ref_r);
}

void isa_difftest_attach() {
}
