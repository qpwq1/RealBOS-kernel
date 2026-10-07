[bits 16]
[org 0x7C00]
jmp Boot_init
OS_init_text db 'Starting OS...',0
no_find_stage2 db 'Stage2 is not find',0

Boot_init:
    cli
    mov ax,0
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,0x7C00
    sti
    
    mov [0x0500],dl ;保存传来的驱动器号
    jmp Boot_write_starting_text ;跳转

Boot_print_str: ;si=string_pointer di=offset
    pusha
    push es
    mov ax,0xB800
    mov es,ax
   
.loop:
    mov dl,[si]
    cmp dl,0
    jz .done
    mov byte [es:di],dl
    mov byte [es:di+1],0x0F
    inc si
    add di,2
    jmp .loop
    
.done:
    pop es
    popa
    ret
    
Boot_write_starting_text:
    mov si,OS_init_text
    mov di,0
    call Boot_print_str
    
    jmp Boot_find
    
Boot_sleep:
    hlt
    jmp Boot_sleep

Boot_find:
    mov dl,[0x0500]
    mov si,Boot_DAP
    mov ah,0x42
    int 0x13 ;BIOS扩展读
    jc .error

    mov dx,[0x7E00]
    cmp dx,0x4F53 ;识别头部签名
    jnz .error

    mov dx,[0x81FE]
    cmp dx,0x4F53 ;识别尾部签名
    jnz .error
    jmp 0x0000:0x7E00

.error:
    mov si,no_find_stage2
    mov di,160
    call Boot_print_str
    jmp Boot_sleep
    
;DAP区
align 4
Boot_DAP:
    db 0x10  ;包大小
    db 0     ;保留
    dw 2     ;扇区数
    dw 0x7E00    ;目标偏移
    dw 0      ;目标段
    dd 1       ;LBA低32位
    dd 0        ;LBA高32位

times 510-($ - $$) db 0 ;填充512个字节
dw 0xAA55
