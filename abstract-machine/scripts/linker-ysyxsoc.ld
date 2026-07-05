ENTRY(_start)

MEMORY {
  mrom (rx)  : ORIGIN = _mrom_start, LENGTH = _mrom_size
  sram (rwx) : ORIGIN = _sram_start, LENGTH = _sram_size
}

PHDRS {
  text PT_LOAD;
  data PT_LOAD;
}

SECTIONS {
  . = ORIGIN(mrom);

  .text : ALIGN(4) {
    *(entry)
    *(.text*)
  } > mrom :text

  .rodata : ALIGN(4) {
    *(.rodata*)
    *(.srodata*)
  } > mrom :text

  .data : ALIGN(4) {
    _data_start = .;
    *(.data*)
    *(.sdata*)
    _data_end = ALIGN(4);
  } > sram AT> mrom :data

  _data_load_start = LOADADDR(.data);
  _data_load_end = LOADADDR(.data) + SIZEOF(.data);

  .bss (NOLOAD) : ALIGN(4) {
    _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    _bss_end = ALIGN(4);
  } > sram :data

  _heap_start = ALIGN(8);
  _heap_end = ORIGIN(sram) + LENGTH(sram) - _stack_size;

  _stack_top = ORIGIN(sram) + LENGTH(sram);
  _stack_pointer = _stack_top;
  _stack_bottom = _heap_end;

  end = _bss_end;
  _end = _bss_end;

  ASSERT(_heap_start <= _heap_end, "SRAM overflow: insufficient space for heap and stack")
}
