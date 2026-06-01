[bits 16]
[org 0x0000]

dw 0xAA56
start:
    mov ax, 0xb800
    mov es, ax
    mov byte [es:0], 'L'
    mov byte [es:1], 0x0F
    mov byte [es:2], 'O'
    mov byte [es:3], 0x0F
    mov byte [es:4], 'A'
    mov byte [es:5], 0x0F
    mov byte [es:6], 'D'
    mov byte [es:7], 0x0F

    jmp $
times 1024-($-$$) db 0