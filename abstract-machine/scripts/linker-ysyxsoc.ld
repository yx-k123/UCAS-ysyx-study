ENTRY(_start)

MEMORY {
  flash (rx) : ORIGIN = _flash_start, LENGTH = _flash_size
  sram (rwx) : ORIGIN = _sram_start, LENGTH = _sram_size
}

PHDRS {
  text PT_LOAD;
  data PT_LOAD;
}

SECTIONS {
  . = ORIGIN(flash);

  .text : ALIGN(4) {
    *(entry)
    *(.text*)
  } > flash :text

  .rodata : ALIGN(4) {
    *(.rodata*)
    *(.srodata*)
  } > flash :text

  .ramtext : ALIGN(4) {
    _ram_image_start = .;
    *(.ramtext*)
    _ramtext_end = ALIGN(4);
  } > sram AT> flash :data

  .data : ALIGN(4) {
    _data_start = .;
    *(.data*)
    *(.sdata*)
    _data_end = ALIGN(4);
    _ram_image_end = .;
  } > sram AT> flash :data

  _ram_image_load_start = LOADADDR(.ramtext);
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
