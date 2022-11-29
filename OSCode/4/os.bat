
..\..\nasm2\nasm.exe    p1.asm       -o      ..\..\Image\p1.bin
..\..\tools\dd.exe      if=..\..\Image\p1.bin      of=..\..\Image\gxos.vhd     bs=512  count=1 seek=0

pause
