
..\..\nasm2\nasm.exe    hello.asm       -o      ..\..\Image\hello.bin
..\..\tools\dd.exe      if=..\..\Image\hello.bin      of=..\..\Image\gxos.vhd     bs=512  count=1 seek=0

pause
