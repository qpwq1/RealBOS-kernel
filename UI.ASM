[BITS 16]
[ORG 0x7C00]

start:
    ; BIOS 输出测试
    mov ah, 0x0E
    mov al, 'X'
    int 0x10
    
    ; 无限循环
    jmp $

times 510 - ($ - $$) db 0
dw 0xAA55