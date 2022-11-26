
LOADER_BASE_ADDR        equ 0x900
section loader vstart=LOADER_BASE_ADDR

; 设置段指向文本模式显示缓冲区
mov ax, 0xb800
mov es, ax

; 向显示缓冲区写入显示字符及KRGB控制字符
mov byte[es: 0x08], 'O'
mov byte[es: 0x09], 0x07
mov byte[es: 0x0A], 'K'
mov byte[es: 0x0B], 0x06

jmp $

