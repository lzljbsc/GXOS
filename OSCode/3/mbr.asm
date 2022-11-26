; 将第二个扇区的内容加载进内存 0x9000处
; mbr.asm   loader.asm
; 0         1
; 0x9000 是内存中空闲的一段

LOADER_BASE_ADDR        equ 0x900
LOADER_START_SECTOR     equ 0x02    ; 以 LBA方式, loader程序在第二个扇区

SECTION MBR vstart=0x7c00
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00
    mov ax, 0xb800
    mov gs, ax

; 利用 BIOS 10号中断 0x06 的功能清屏
; AH = 0x06
; AL = 0    全部清除
; BH = 上卷行的属性
; (CL, CH) 左上角 x, y
; (DL, DH) 右下角 x, y
    mov ax, 0600h
    mov bx, 0700h
    mov cx, 0
    mov dx, 184fh ; (80, 25)
    int 10h

; 输出提示信息 MBR
    mov byte [gs: 0x00], 'M'
    mov byte [gs: 0x01], 0xA4
    mov byte [gs: 0x02], 'B'
    mov byte [gs: 0x03], 0xA4
    mov byte [gs: 0x04], 'R'
    mov byte [gs: 0x05], 0xA4

    mov eax, LOADER_START_SECTOR    ; LBA 读入的扇区
    mov bx, LOADER_BASE_ADDR        ; 存放的内存地址
    mov cx, 1                       ; 读入的扇区数量
    call rd_disk
    
    jmp LOADER_BASE_ADDR            ; 跳转到指定内存地址

rd_disk:
    mov esi, eax    ; 备份 eax
    mov di, cx      ; 备份 cx
    
; 设置硬盘读写参数
    mov dx, 0x01f2
    mov al, cl
    out dx, al
    mov eax, esi

; LBA 的地址存放在 0x01f3 - 0x01f6
    ; 7-0  0x01f3
    mov dx, 0x01f3
    out dx, al
    ; 15-8 0x01f4
    mov cl, 8
    shr eax, cl
    mov dx, 0x01f4
    out dx, al
    ; 23-16 0x01f5
    shr eax, cl
    mov dx, 0x01f5
    out dx, al
    ; 27-24 0x01f6
    shr eax, cl
    and al, 0x0f
    or  al, 0xe0        ; 7-4位 1110 LBA模式
    mov dx, 0x01f6
    out dx, al
    
; 向 0x01f7写入读命令
    mov dx, 0x01f7 
    mov al, 0x20
    out dx, al
    
; 检测硬盘状态
.not_ready:
    nop 
    in  al, dx
    and al, 0x88        ; bit4 为1, 表示可以传输, bit7 为1, 表示硬盘忙
    cmp al, 0x08
    jnz .not_ready      ; 硬盘忙时一直等待

; 进行读数据
    mov ax, di 
    mov dx, 256
    mul dx
    mov cx, ax
    mov dx, 0x01f0
.go_on:
    in  ax, dx 
    mov [bx], ax
    add bx, 2
    loop .go_on
    ret


times 510 - ($ - $$) db 0
db 0x55, 0xaa






