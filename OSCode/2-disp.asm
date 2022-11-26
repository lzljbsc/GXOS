mov ax,0xb800       ; 设置段寄存器指向文本模式的显示缓冲区
mov es,ax

; 向显示缓冲区写入显示字符及KRGB控制字符
mov byte[es: 0x00], 'G'
mov byte[es: 0x01], 0x05
mov byte[es: 0x02], 'X'
mov byte[es: 0x03], 0x96
jmp $

times 510 - ($-$$) db 0
db 0x55,0xaa
;dw 0xaa55
