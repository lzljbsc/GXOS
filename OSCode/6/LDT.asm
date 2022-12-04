DA_32   EQU     4000h   ;32位
DA_C    EQU     98h     ;只执行代码段的属性
DA_DRW  EQU     92h     ;可读写的数据段
DA_DRWA EQU     93h     ;存在的已访问的可读写的
DA_LDT  EQU     82h     ;LDT

SA_TIL  EQU     4       ;LDT段选择子的 TI 为,表示选择的是 LDT

%macro Descriptor 3
    dw  %2 & 0FFFFh                         ;段界限1 （2字节）
    dw  %1 & 0FFFFh                         ;段基址1 (2字节）
    db  (%1 >> 16) & 0FFh                   ;段基址2 （1字节）
    dw  ((%2 >> 8) & 0F00h) | (%3 &0F0FFh)  ;属性1 + 段界限2+属性2 （2字节）
    db  (%1 >> 24) & 0FFh                   ;段基址3
%endmacro


org 0100h     ;因为我们dos下调试程序，那么0100是可用区域
    jmp PM_BEGIN    ;跳入到标号为PM_BEGIN的代码段开始推进
    
    
[SECTION .gdt]
;GDT
;                                  段基址，            段界限，          属性
PM_GDT:             Descriptor          0,                  0,              0
PM_DESC_CODE32:     Descriptor          0,     SegCode32Len-1,     DA_C+DA_32
PM_DESC_DATA:       Descriptor          0,          DATALen-1,         DA_DRW    
PM_DESC_STACK:      Descriptor          0,         TopOfStack,  DA_DRWA+DA_32
PM_DESC_TEST:       Descriptor   0200000h,             0ffffh,         DA_DRW
PM_DESC_VIDEO:      Descriptor    0B8000h,             0ffffh,         DA_DRW

LABEL_DESC_LDT:     Descriptor          0,          LDTLen -1,         DA_LDT
;end of definiton gdt

GdtLen  equ     $ - PM_GDT
GdtPtr  dw      GdtLen - 1
        dd      0        ; GDT 基地址，程序中设置

;GDT 选择子
;之所以可以直接使用段描述符地址减GDT起始地址,是因为段描述符正好是8个字节
;而且GDT的段选择子的格式正好的低三位可以为0, 也就是 0x08对其的
SelectoerCode32     equ     PM_DESC_CODE32  - PM_GDT    
SelectoerDATA       equ     PM_DESC_DATA    - PM_GDT
SelectoerSTACK      equ     PM_DESC_STACK   - PM_GDT    
SelectoerTEST       equ     PM_DESC_TEST    - PM_GDT
SelectoerVideo      equ     PM_DESC_VIDEO   - PM_GDT   
SelectoerLDT        equ     LABEL_DESC_LDT  - PM_GDT            
;END of [SECTION .gdt]

[SECTION .data]
ALIGN 32
[BITS 32]
PM_DATA:
PMMessage:      db  "Potect Mode", 0;
OffsetPMessage  equ PMMessage - $$
DATALen         equ $- PM_DATA
;END of [SECTION .data]

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
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0100h
    
    ;初始化32位的代码段
    xor eax, eax
    mov ax,  cs
    shl eax, 4
    add eax, PM_SEG_CODE32
    mov word[PM_DESC_CODE32+2], ax
    shr eax, 16
    mov byte [PM_DESC_CODE32+4], al
    mov byte [PM_DESC_CODE32+7], ah
    
    
    ;初始化32位的数据段
    xor eax, eax
    mov ax,  ds
    shl eax, 4
    add eax, PM_DATA
    mov word[PM_DESC_DATA+2], ax
    shr eax, 16
    mov byte [PM_DESC_DATA+4], al
    mov byte [PM_DESC_DATA+7], ah
    
    ;初始化32位的stack段
    xor eax, eax
    mov ax,  ds
    shl eax, 4
    add eax, PM_STACK
    mov word[PM_DESC_STACK+2], ax
    shr eax, 16
    mov byte [PM_DESC_STACK+4], al
    mov byte [PM_DESC_STACK+7], ah
    
    ;初始化32位的LDT,得把省局注册到全国
    xor eax, eax
    mov ax,  ds
    shl eax, 4
    add eax, LABEL_LDT
    mov word[LABEL_DESC_LDT+2], ax
    shr eax, 16
    mov byte [LABEL_DESC_LDT+4], al
    mov byte [LABEL_DESC_LDT+7], ah

    ;根据GDT,把LDT管理的具体公司初始化
    xor eax, eax
    mov ax,  ds
    shl eax, 4
    add eax, LABEL_CODE_A
    mov word[LABEL_LDT_DESC_CODEA+2], ax
    shr eax, 16
    mov byte [LABEL_LDT_DESC_CODEA +4], al
    mov byte [LABEL_LDT_DESC_CODEA +7], ah

    ;加载GDTR
    xor eax, eax
    mov ax,  ds
    shl eax, 4
    add eax, PM_GDT
    mov dword [GdtPtr +2 ], eax
    lgdt [GdtPtr]

    cli
    
    ;A20
    in al,  92h
    or al,  00000010b
    out 92h, al
    
    ;切换到保护模式
    mov eax, cr0
    or  eax, 1
    mov cr0, eax
    
    jmp dword SelectoerCode32:0


[SECTION .s32]    ;32位的代码段
[BITS 32]
PM_SEG_CODE32:
    mov ax,  SelectoerDATA    ;通过数据段的选择子放入ds寄存器，就可以用段+偏移进行寻址
    mov ds,  ax
    
    mov ax,  SelectoerTEST    ;通过测试段的选择子放入es寄存器，就可以用段+偏移进行寻址
    mov es,  ax
    
    mov ax,  SelectoerVideo
    mov gs,  ax
    
    mov ax,  SelectoerSTACK
    mov ss,  ax
    mov esp, TopOfStack
    
    mov ah,  0Ch
    xor esi, esi
    xor edi, edi
    mov esi, OffsetPMessage
    mov edi, (80 * 10 + 0) * 2
    cld
    
.1:
    lodsb
    test al,  al
    jz .2
    mov [gs:edi], ax
    add edi,  2
    jmp .1
    
.2: ;显示完毕

    ;Load LDT
    mov ax,  SelectoerLDT    ;    SelectoerLDT=> GDT
    lldt ax
    jmp SelectoerLDTCodeA:0

SegCode32Len equ $ - PM_SEG_CODE32


;LDT
[SECTION .ldt]
ALIGN 32
LABEL_LDT:
;                                          段基址，           段界限，             属性
LABEL_LDT_DESC_CODEA:       Descriptor          0,        CodeALen-1,        DA_C+DA_32

LDTLen equ $ - LABEL_LDT
;选择子
SelectoerLDTCodeA       equ     LABEL_LDT_DESC_CODEA - LABEL_LDT + SA_TIL

[SECTION .la]
ALIGN 32
[BITS 32]
LABEL_CODE_A:
    mov ax,  SelectoerVideo
    mov gs,  ax
    mov edi, (80 * 5 + 0) * 2
    mov ah,  0Ch
    mov al,  'D'
    mov [gs:edi], ax

    jmp $
CodeALen  equ $ - LABEL_CODE_A
;END of 任务段




