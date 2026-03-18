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

#include "sdb.h"

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
WP* new_wp() {
  if (free_ == NULL) {
    printf("No free watchpoint\n");
    assert(0);
    return NULL;
  }
  WP *wp = free_;
  free_ = free_->next;
  wp->next = head;
  head = wp;
  wp->valid = 1;
  wp->hit_count = 0;
  return wp;
}

void free_wp(WP *wp) {
  if (wp == NULL) {
    printf("Invalid watchpoint\n");
    return;
  }

  if (head == wp) {
    head = wp->next;
  } else {
    WP *curr = head;
    while (curr != NULL && curr->next != wp) {
      curr = curr->next;
    }
    if (curr != NULL) {
      curr->next = wp->next;
    }
  }

  wp->valid = 0;
  wp->next = free_;
  free_ = wp;
}

bool check_watchpoint() {
  WP *curr = head;
  bool changed = false;
  while (curr != NULL) {
    bool success;
    word_t new_val = expr(curr->expr, &success);
    if (success && new_val != curr->value) {
      printf("Hardware watchpoint %d: %s\n", curr->NO, curr->expr);
      printf("Old value = " FMT_WORD "\n", curr->value);
      printf("New value = " FMT_WORD "\n", new_val);
      curr->value = new_val;
      curr->hit_count++;
      changed = true;
    }
    curr = curr->next;
  }
  return changed;
}

void wp_display() {
  if (head == NULL) {
    printf("No watchpoints.\n");
    return;
  }
  printf("Num\tWhat\t\tValue\t\tHit Count\tExpression\n");
  WP *curr = head;
  while (curr != NULL) {
    printf("%d\twatchpoint\t" FMT_WORD "\t%d\t\t%s\n", curr->NO, curr->value, curr->hit_count, curr->expr);
    curr = curr->next;
  }
}

bool delete_wp(int no) {
  WP *curr = head;
  while (curr != NULL) {
    if (curr->NO == no) {
      free_wp(curr);
      return true;
    }
    curr = curr->next;
  }
  return false;
}
