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
PM_DESC_TEST:		Descriptor		0200000h,0ffffh,	DA_DRW
PM_DESC_VIDEO:		Descriptor		0B8000h,	0ffffh, DA_DRW + DA_DPL3

LABEL_DESC_LDT:		Descriptor		0,	LDTLen -1, DA_LDT

PM_DESC_CODE_DEST:	Descriptor		0,	SegCodeDestLen -1,DA_C+DA_32

PM_DESC_CODE_RING3: Descriptor		0,	SegCodeRing3Len-1,DA_C+DA_32 + DA_DPL3
PM_DESC_STACK3:		Descriptor		0,		TopOfStack3,	DA_DRWA+DA_32+DA_DPL3
PM_DESC_TSS:		Descriptor      0, TSSLen -1,DA_386TSS


PM_CALL_GATE_TEST:
dw 00000h
dw SelectoerCodeDest
dw 0ec00h
dw 00000h
;end of definiton gdt
GdtLen equ $ - PM_GDT
GdtPtr dw GdtLen - 1
dd  0 ; GDT 基地址

;GDT 选择子
SelectoerCode32	equ PM_DESC_CODE32 - PM_GDT	
SelectoerDATA	equ PM_DESC_DATA - PM_GDT
SelectoerSTACK	equ PM_DESC_STACK - PM_GDT	
SelectoerTEST	equ PM_DESC_TEST - PM_GDT
SelectoerVideo	equ PM_DESC_VIDEO - PM_GDT	
SelectoerLDT	equ LABEL_DESC_LDT - PM_GDT	

SelectoerCodeDest equ PM_DESC_CODE_DEST - PM_GDT
SelectorCallGateTest equ PM_CALL_GATE_TEST - PM_GDT + SA_RPL3
		
SelctorCodeRing3 equ PM_DESC_CODE_RING3 - PM_GDT + SA_RPL3
SelctorStack3 equ PM_DESC_STACK3 - PM_GDT + SA_RPL3
SelctorTSS equ 		PM_DESC_TSS - PM_GDT
		
;END of [SECTION .gdt]

[SECTION .data1]
ALIGN 32
[BITS 32]
PM_DATA:
PMMessage : db "Potect Mode", 0;
OffsetPMessage equ PMMessage - $$
DATALen equ $- PM_DATA
;END of [SECTION .data]

;全局的堆栈段
[SECTION .gs]
ALIGN 32
[BITS 32]
PM_STACK:
	times 512 db 0
TopOfStack equ $ - PM_STACK -1
;END of STACK	


;ring3的堆栈段
[SECTION .s3]
ALIGN 32
[BITS 32]
PM_STACK3:
	times 512 db 0
TopOfStack3 equ $ - PM_STACK3 -1
;END of STACK	

;全局的堆栈段
[SECTION .tss]
ALIGN 32
[BITS 32]
PM_TSS:
	DD	0			; Back
		DD	TopOfStack 		; 0 级堆栈
		DD	SelectoerSTACK		; 
		DD	0			; 1 级堆栈
		DD	0			; 
		DD	0			; 2 级堆栈
		DD	0			; 
		DD	0			; CR3
		DD	0			; EIP
		DD	0			; EFLAGS
		DD	0			; EAX
		DD	0			; ECX
		DD	0			; EDX
		DD	0			; EBX
		DD	0			; ESP
		DD	0			; EBP
		DD	0			; ESI
		DD	0			; EDI
		DD	0			; ES
		DD	0			; CS
		DD	0			; SS
		DD	0			; DS
		DD	0			; FS
		DD	0			; GS
		DD	0			; LDT
		DW	0			; 调试陷阱标志
		DW	$- PM_TSS+2 	; I/O位图基址
		DB	0ffh			; I/O位图结束标志
TSSLen equ $ - PM_TSS -1
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
	
	;初始化32位的LDT,得把省局注册到全国
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,LABEL_LDT					;//to do 
	mov word[LABEL_DESC_LDT+2],ax
	shr eax,16
	mov byte [LABEL_DESC_LDT+4],al
	mov byte [LABEL_DESC_LDT+7],ah
	
	
	
	;根据GDT,把LDT管理的具体公司初始化,得把省局注册到全国
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax, LABEL_CODE_A					;//to do 
	mov word[LABEL_LDT_DESC_CODEA+2],ax
	shr eax,16
	mov byte [LABEL_LDT_DESC_CODEA +4],al
	mov byte [LABEL_LDT_DESC_CODEA +7],ah
	
	
	;为调用门的运行，我们将目标代码段跳转
	xor eax,eax
	mov ax,cs
	shl eax,4
	add eax, PM_SEG_CODE_DEST					;//to do 
	mov word[PM_DESC_CODE_DEST+2],ax
	shr eax,16
	mov byte [PM_DESC_CODE_DEST+4],al
	mov byte [PM_DESC_CODE_DEST+7],ah
	
	
	;初始化Ring3
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax, PM_CODE_RING3				;//to do 
	mov word[PM_DESC_CODE_RING3+2],ax
	shr eax,16
	mov byte [PM_DESC_CODE_RING3+4],al
	mov byte [PM_DESC_CODE_RING3+7],ah
	
	;初始化TSS
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax, PM_TSS			;//to do 
	mov word[PM_DESC_TSS+2],ax
	shr eax,16
	mov byte [PM_DESC_TSS+4],al
	mov byte [PM_DESC_TSS+7],ah
	
	
	
	
	;加载GDTR
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,PM_GDT
	mov dword [GdtPtr +2 ],eax
	lgdt [GdtPtr]
	
	;A20
	cli
	
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
	
	mov ax,SelectoerTEST	;通过测试段的选择子放入es寄存器，就可以用段+偏移进行寻址
	mov es,ax
	
	mov ax,SelectoerVideo
	mov gs,ax
	
	mov ax,SelectoerSTACK
	mov ss,ax
	mov esp,TopOfStack
	
	mov ah,0Ch
	xor esi,esi
	xor edi,edi
	mov esi,OffsetPMessage
	mov edi,(80*10 +0) *2
	cld
	
.1:
	lodsb
	test al,al
	jz .2
	mov [gs:edi],ax
	add edi,2
	jmp .1
	
.2: ;显示完毕

	;Load LDT
	
	;mov ax,SelectoerLDT	;	SelectoerLDT=> GDT
	;lldt ax
	;jmp SelectoerLDTCodeA:0
	
	;------------gate 1
	;call SelectorCallGateTest:0
	;jmp $
	;------------end of gate 1
	
	;beging gate 2:有级别转换
	;load TSS
	mov ax, SelctorTSS
	ltr ax
	
	push SelctorStack3
	push TopOfStack3
	push SelctorCodeRing3
	push 0
	retf
	

SegCode32Len equ $ - PM_SEG_CODE32


;LDT
[SECTION .ldt]
ALIGN 32
LABEL_LDT:
;									段基址，段界限，		属性
LABEL_LDT_DESC_CODEA:	Descriptor		0,		CodeALen-1,		DA_C+DA_32

LDTLen	equ $ - LABEL_LDT
;选择子
SelectoerLDTCodeA	equ LABEL_LDT_DESC_CODEA - LABEL_LDT + SA_TIL

[SECTION .la]
ALIGN 32
[BITS 32]
LABEL_CODE_A:
	
	mov  ax,SelectoerVideo
	mov gs,ax
	mov edi, (80*5 +0) *2
	mov ah, 0Ch
	mov al, 'D'
	mov [gs:edi],ax
	
	
	jmp $
CodeALen  equ $ - LABEL_CODE_A
;END of 任务段

[SECTION .sdest]
ALIGN 32
[BITS 32]
PM_SEG_CODE_DEST:
	mov  ax,SelectoerVideo
	mov gs,ax
	mov edi, (80*18 +0) *2
	mov ah, 0Ch
	mov al, 'G'
	mov [gs:edi],ax
	
	;Load LDT
	mov ax, SelectoerLDT
	lldt ax
	jmp SelectoerLDTCodeA:0
	
	;retf
	
SegCodeDestLen equ $ - PM_SEG_CODE_DEST
;END of 调用门

;ring 3
[SECTION .ring3]
ALIGN 32
[BITS 32]
PM_CODE_RING3:
	mov  ax,SelectoerVideo
	mov gs,ax
	mov edi, (80*12 +0) *2
	mov ah, 0Ch
	mov al, '3'
	mov [gs:edi],ax
	
	call SelectorCallGateTest:0 ;用调用门完成特权级切换
	jmp $
	
SegCodeRing3Len equ $ - PM_CODE_RING3
;END of 调用门



