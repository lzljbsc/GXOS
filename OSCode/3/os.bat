
..\..\nasm2\nasm.exe    mbr.asm       -o      ..\..\Image\mbr.bin
..\..\nasm2\nasm.exe    loader.asm    -o      ..\..\Image\loader.bin
..\..\tools\dd.exe      if=..\..\Image\mbr.bin      of=..\..\Image\gxos.vhd     bs=512  count=1 seek=0
..\..\tools\dd.exe      if=..\..\Image\loader.bin   of=..\..\Image\gxos.vhd     bs=512  count=1 seek=1

pause
