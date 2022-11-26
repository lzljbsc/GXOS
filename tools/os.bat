:: OS源文件
set oscode=os.asm

..\nasm2\nasm.exe  ..\OSCode\%oscode%  -o  ..\Image\boot.bin
.\dd.exe  if=..\Image\boot.bin  of=..\Image\gxos.vhd  bs=512  count=1

pause
