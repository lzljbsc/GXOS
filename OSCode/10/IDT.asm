DA_32 EQU	4000h;32位
DA_C EQU 98h; 只执行代码段的属性
DA_DRW	EQU 92h;可读写的数据段
DA_DRWA EQU 93h;存在的已访问的可读写的
DA_LDT EQU 82h;省局

SA_TIL EQU	4 ;具体的任务
SA_RPL3 EQU 3

DA_DPL3 EQU 60h

DA_386TSS EQU 89h

%macro Descriptor 3
	dw %2 & 0FFFFh	;段界限1 （2字节）
	dw %1 & 0FFFFh	;段基址1 (2字节）
	db (%1 >> 16) & 0FFh	;段基址2 （1字节）
	dw ((%2 >> 8) & 0F00h) | (%3 &0F0FFh) ;属性1 + 段界限2+属性2 （2字节）
	db (%1 >> 24) & 0FFh	;段基址3
%endmacro


org 0100h 	;因为我们dos下调试程序，那么0100是可用区域
	jmp PM_BEGIN	;跳入到标号为PM_BEGIN的代码段开始推进
	
	
[SECTION .gdt]
;GDT
;								段基址，段界限，属性
PM_GDT:				Descriptor		0,		0,		0
PM_DESC_CODE32:	Descriptor		0,		SegCode32Len -1,DA_C+DA_32
PM_DESC_DATA:		Descriptor		0,		DATALen-1, DA_DRW	
PM_DESC_STACK:		Descriptor		0,		TopOfStack,	DA_DRWA+DA_32
PM_DESC_VIDEO:		Descriptor		0B8000h,	0ffffh, DA_DRW 



;end of definiton gdt
GdtLen equ $ - PM_GDT
GdtPtr dw GdtLen - 1
dd  0 ; GDT 基地址

;GDT 选择子
SelectoerCode32	equ PM_DESC_CODE32 - PM_GDT	
SelectoerDATA	equ PM_DESC_DATA - PM_GDT
SelectoerSTACK	equ PM_DESC_STACK - PM_GDT	
SelectoerVideo	equ PM_DESC_VIDEO - PM_GDT	

;END of [SECTION .gdt]

[SECTION .data1]
ALIGN 32
[BITS 32]
PM_DATA:
PMMessage : db "Potect Mode", 0;
OffsetPMessage equ PMMessage - $$

_SavedIDTR:	dd 0
			dd 0
_SavedIMREG	db 0 ;中断屏蔽寄存器

;保护模式
SavedIDTR	equ _SavedIDTR - $$
SavedIMREG 	equ _SavedIMREG - $$			

DATALen equ $- PM_DATA
;END of [SECTION .data]

;IDT
[SECTION .idt]
ALIGN 32
[BITS 32]
PM_IDT:
%rep 128
	dw NormalHandler	;会定义中断响应函数的地址
	dw SelectoerCode32
	dw 08E00h
	dw((NormalHandler >> 16) & 0FFFFh)
%endrep

IdtLen equ $ - PM_IDT
IdtPtr dw IdtLen - 1
	dd 0
;End of idt



;全局的堆栈段
[SECTION .gs]
ALIGN 32
[BITS 32]
PM_STACK:
	times 512 db 0
TopOfStack equ $ - PM_STACK -1
;END of STACK	

[SECTION .s16]
[BITS 16]
PM_BEGIN:
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov sp,0100h
	
	;初始化32位的代码段
	xor eax,eax
	mov ax,cs
	shl eax,4
	add eax,PM_SEG_CODE32
	mov word[PM_DESC_CODE32+2],ax
	shr eax,16
	mov byte [PM_DESC_CODE32+4],al
	mov byte [PM_DESC_CODE32+7],ah
	
	
	;初始化32位的数据段
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,PM_DATA
	mov word[PM_DESC_DATA+2],ax
	shr eax,16
	mov byte [PM_DESC_DATA+4],al
	mov byte [PM_DESC_DATA+7],ah
	
	;初始化32位的stack段
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,PM_STACK
	mov word[PM_DESC_STACK+2],ax
	shr eax,16
	mov byte [PM_DESC_STACK+4],al
	mov byte [PM_DESC_STACK+7],ah
	
		
	
	;加载GDTR
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,PM_GDT
	mov dword [GdtPtr +2 ],eax
	
	; load IDT
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,PM_IDT
	mov dword [IdtPtr+2],eax
	
	sidt [_SavedIDTR]
	
	in al,21h
	mov [_SavedIMREG],al

	lgdt [GdtPtr]
	
	lidt [IdtPtr]
	
	;A20
	;cli
	
	in al,92h
	or al,00000010b
	out 92h,al
	
	;切换到保护模式
	mov eax,cr0
	or eax,1
	mov cr0,eax
	
	jmp dword SelectoerCode32:0



[SECTION .s32]	;32位的代码段
[BITS 32]
PM_SEG_CODE32 :
	mov ax,SelectoerDATA	;通过数据段的选择子放入ds寄存器，就可以用段+偏移进行寻址
	mov ds,ax
	
	
	mov es,ax
	
	mov ax,SelectoerVideo
	mov gs,ax
	
	mov ax,SelectoerSTACK
	mov ss,ax
	mov esp,TopOfStack
	
	call Init8259A
		
	
	jmp $

; Init8259A ---------------------------------------------------------------------------------------------
Init8259A:
	mov	al, 011h
	out	020h, al	; 主8259, ICW1.
	call	io_delay

	out	0A0h, al	; 从8259, ICW1.
	call	io_delay

	mov	al, 020h	; IRQ0 对应中断向量 0x20
	out	021h, al	; 主8259, ICW2.
	call	io_delay

	mov	al, 028h	; IRQ8 对应中断向量 0x28
	out	0A1h, al	; 从8259, ICW2.
	call	io_delay

	mov	al, 004h	; IR2 对应从8259
	out	021h, al	; 主8259, ICW3.
	call	io_delay

	mov	al, 002h	; 对应主8259的 IR2
	out	0A1h, al	; 从8259, ICW3.
	call	io_delay

	mov	al, 001h
	out	021h, al	; 主8259, ICW4.
	call	io_delay

	out	0A1h, al	; 从8259, ICW4.
	call	io_delay

	mov	al, 11111110b	; 仅仅开启定时器中断
	
	out	021h, al	; 主8259, OCW1.
	call	io_delay

	mov	al, 11111111b	; 屏蔽从8259所有中断
	out	0A1h, al	; 从8259, OCW1.
	call	io_delay

	ret
; Init8259A ---------------------------------------------------------------------------------------------



io_delay:
	nop
	nop
	nop
	nop
	ret	
;-------------------------
_NormalHandler:
NormalHandler equ _NormalHandler - $$
	mov ah, 0Ch
	mov al, 'X'
	mov [gs:((80 * 1 + 70)*2)],ax
	jmp $
	iretd
;-------------------------


;-------------------------
SegCode32Len equ $ - PM_SEG_CODE32




