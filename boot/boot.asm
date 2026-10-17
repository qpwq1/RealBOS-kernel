[bits 16]
[org 0x7C00]
jmp Boot_init
OS_init_text db 'Starting OS...',0
no_found_stage2 db 'Stage 2 not found',0
start_found_stage2 db 'Loading Stage 2...',0

Boot_init:
    cli
    mov ax,0
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,0x7C00

    ;设置变量与指针
    mov byte [0x0500],dl ;保存传来的驱动器号
    mov word [0x0501],0 ;清零打印的位置指针
    sti

    call Boot_clean_screen ;清屏
    jmp Boot_write_starting_text ;跳转到打印

Boot_clean_screen:
    push ax
    push es
    push bx

    mov ax,0xB800
    mov es,ax
    mov bx,0
.loop:
    mov byte [es:bx],0x20
    mov byte [es:bx+1],0x0F
    add bx,2
    cmp bx,4000
    jnz .loop
.done:
    mov word [0x0501],0
    pop bx
    pop es
    pop ax
    ret

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
    mov word [0x0501],di
    jmp .loop
    
.done:
    pop es
    popa
    ret
    
Boot_write_starting_text:
    mov si,OS_init_text
    mov di,0
    call Boot_print_str

    mov si,start_found_stage2
    mov di,160
    call Boot_print_str
    
    jmp Boot_find
    
Boot_sleep:
    hlt
    jmp Boot_sleep

Boot_write_DAP:
    ;DAP的基地址在0x0000:0x0504
    mov byte [0x0504+0],0x10  ;包大小
    mov byte [0x0504+1],0     ;保留
    mov word [0x0504+2],2     ;扇区数
    mov word [0x0504+4],0x7E00    ;目标偏移
    mov word [0x0504+6],0      ;目标段
    mov dword [0x0504+8],1       ;LBA低32位
    mov dword [0x0504+12],0        ;LBA高32位
    ret

Boot_find:
    call Boot_write_DAP

    mov dl,[0x0500]
    mov si,0x0504
    mov ah,0x42
    int 0x13 ;BIOS扩展读
    jc .error

    mov dx,[0x81FE]
    cmp dx,0x0001 ;识别尾部签名
    jnz .error
    jmp 0x0000:0x7E00

.error:
    mov si,no_found_stage2
    mov di,160
    call Boot_print_str
    jmp Boot_sleep
    
;DAP区
align 4
Boot_DAP:
    

times 0x1BE-($-$$) db 0

;分区表区
;分区条目1
db 0x80                 ;状态：活动
db 0x00, 0x02, 0x00     ;起始CHS：磁头0，扇区2，柱面0
db 0x0B                 ;类型：FAT32(CHS)
db 0xFE, 0xFF, 0xFF     ;结束 CHS：磁头254，扇区63，柱面1023
dd 1                    ;起始 LBA：1
dd 0x0B3F               ;扇区数：2879（按1.44MB算）

;分区条目 2、3、4：全零
times 48 db 0
dw 0xAA55