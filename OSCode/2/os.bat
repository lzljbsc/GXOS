
..\..\nasm2\nasm.exe    disp.asm       -o      ..\..\Image\disp.bin
..\..\tools\dd.exe      if=..\..\Image\disp.bin      of=..\..\Image\gxos.vhd     bs=512  count=1 seek=0

pause
