[org 0x7E00]
jmp stage2_init
Failed_to_enable_A20 db 'Error: Failed to enable A20.',0
A20_is_open db 'A20 gate enabled.',0
e820_not_found db 'E820 not found.',0


stage2_init:
    cli
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,0x7E00 ;覆盖原来的boot.asm（已经执行过，可废弃）
    sti

    mov word [0x0501],320
    jmp stage2_openA20_BIOS

stage2_print_str: ;si=string_pointer di=offset
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
    mov [0x0501],di
    jmp .loop
    
.done:
    pop es
    popa
    ret

    
stage2_openA20_BIOS:
    mov ax,0x2401 ;设置中断号
    int 0x15 ;先尝试使用BIOS的方法打开A20地址线

    ;初步判断BIOS中的标志
    jc stage2_A20not_open
    cmp ah,0
    jnz stage2_A20not_open

    call stage2_check_A20
    jnc stage2_A20is_open

    jmp stage2_A20not_open

stage2_A20is_open:
    mov si,A20_is_open
    mov di,[0x0501]
    call stage2_print_str

    jmp stage2_load_e820

stage2_A20not_open:
    mov si,Failed_to_enable_A20
    mov di,[0x0501]
    call stage2_print_str

    jmp halt


stage2_check_A20: ;CF=0(开了)，CF=1（没开）
    push ds
    push es
    push ax
    push bx

    cli                       ;检测期间关中断

    mov ax,0
    mov ds,ax                ;DS=0(访问0x000000)
    mov ax,0xFFFF
    mov es,ax                ;ES=FFFF(访问0x100000)

    ;保存原值
    mov al,[ds:0x0000]
    mov bl,[es:0x0010]

    ;写测试值
    mov byte [ds:0x0000],0x00
    mov byte [es:0x0010],0xFF

    ;读回0x100000
    mov ah,[es:0x0010]

    ;恢复原值
    mov byte [es:0x0010],bl
    mov byte [ds:0x0000],al

    cmp ah,0xFF

    pop bx
    pop ax
    pop es
    pop ds

    sti
    ret

halt:
    hlt
    jmp halt

stage2_load_e820:
    ;设置共享DAP：DAP的基地址在0x0000:0x0504
    mov byte [0x0504+0],0x10  ;包大小
    mov byte [0x0504+1],0     ;保留
    mov word [0x0504+2],1     ;扇区数
    mov word [0x0504+4],0x8200    ;目标偏移
    mov word [0x0504+6],0      ;目标段
    mov dword [0x0504+8],3       ;LBA低32位
    mov dword [0x0504+12],0        ;LBA高32位

    ;开始查找
    mov dl,[0x0500]
    mov si,0x0504 ;设置DAP地址为共享DAP的地址
    mov ah,0x42
    int 0x13 ;BIOS扩展读
    jc .error

    mov dx,[0x83FE]
    cmp dx,0x0002 ;识别尾部签名
    jnz .error
    jmp 0x0000:0x8200

.error:
    mov si,e820_not_found
    mov di,480
    call stage2_print_str

    jmp halt

times 1022-($-$$) db 0
dw 0x0001 ;尾部签名