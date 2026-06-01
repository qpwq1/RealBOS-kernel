[bits 16]
dw 0xAA57
PRINT_CHAR:   ;打印单个字符,AL=打印的字符 bx=在屏幕上的地址 CH=颜色
    push ax
    push bx
    push cx
    push es
    push dx
    
    mov dx,0xB800
    mov es,dx
    mov byte [es:bx],AL
    mov byte [es:bx+1],CH

    pop dx
    pop es
    pop cx
    pop bx
    pop ax
    RET

clean_display:
    push ax
    push cx
    push di
    push es

    mov ax, 0xB800      ; 显存段地址
    mov es, ax          ; ES = 0xB800
    xor di, di          ; DI = 0 (显存偏移)
    mov cx, 2000        ; 80×25 = 2000 个字符
    mov ax, 0x0720      ; AH = 0x07 (属性：灰底黑字)，AL = 0x20 (空格)

    rep stosw           ; 重复写入 2000 次

    pop es
    pop di
    pop cx
    pop ax

times 1022-($-$$) db 0 ; 填充到 1022 字节