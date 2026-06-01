[BITS 16]
[ORG 0x7C00]
jmp START

clean_screen_bios:
    ;依次保存寄存器
    push ax
    push cx
    push dx
    push bx

    ;使用BIOS终端快速清屏
    mov ax, 0x0600      ; AH=0x06(滚动屏幕), AL=0(清空)
    mov cx, 0           ; 左上角 (0,0)
    mov dx, 0x184F      ; 右下角 (24,79) 25行×80列
    mov bh, 0x00        ; 颜色属性（灰底黑字）
    int 0x10

    ;将寄存器状态保存并返回
    pop bx
    pop dx
    pop cx
    pop ax
    ret

printstart:  ;si放指针，bl放颜色，di放地址
    ;全部压入栈
    push si
    push bx
    push di
    push dx ;虽然不是参数但是需要用到它
    push es ;和dx一样

    mov dx,0xB800 ;把DX设置为文本模式开始
    mov es, dx ;设置附加段寄存器

.printloop:
    mov cl,[si] ;把字符存入cl寄存器（CX低8位）
    cmp cl,0 ;判断CL=0？
    jz .printend ;为0就跳转

    mov byte [es:di],cl
    mov byte [es:di+1],bl
    inc si ;指针变为下一个字符地址
    add di,2 ;计数器+2
    jmp .printloop
.printend:
    ;依次保存
    pop es
    pop dx
    pop di
    pop bx
    pop si
    ret
;---------------------------------------------------------------------

START:
    cli                   ; 禁用中断
	xor ax, ax            ; AX = 0
	mov ds, ax            ; DS = 0
	mov es, ax            ; ES = 0 (稍后设置)
	mov ss, ax            ; SS = 0
	mov sp, 0x7C00        ; SP = 0x7C00 (堆栈指针)
    mov [DriverNum], dl ;保存数字
	sti                   ; 启用中断
	cld				   ; 清除方向标志，确保字符串操作从低地址向高地址进行

    ;清屏
    call clean_screen_bios

    ;把BIOS传来的驱动器号转换为ASCII并保存
    mov al,dl ;把AL设置为DL以方便转换
    add al,'0'
    mov [Driver],al

    ;显示启动消息
    mov si,STARTBOOTMSG
    mov bl,0x0F
    mov di,0
    call printstart


    ;渲染传来的驱动器号和提示文本
    ;第一步：渲染提示文本
    mov si,Driver_STR
    ;mov bl,0x0F，但是实际前面已经设置，无需再改
    mov di,160
    call printstart
    ;第二步：渲染驱动器号
    mov si,Driver
    ;mov bl,0x0F，但是实际前面已经设置，无需再改
    mov di,182
    call printstart

    ;跳转到查找
    jmp find
    jmp hlts ;停机

find: ;开始查找
    ;先保存寄存器
    pusha

    ;读取扇区初始化
    mov ah, 0x08        ; 读取驱动器参数
    mov dl, [DriverNum]    ; 驱动器号
    int 0x13 ;BIOS中断
    jc not_find ;错误则跳转

    mov ax,0 ;LBA扇区号
    mov si, dap ;设置指针
    mov word [si + 4],0x1000    ; 目标偏移
    mov [si + 6],0x0000    ; 目标段
    mov [si + 8],ax    ;重置 LBA 低16位
    mov word [si + 10],0 ;重置LBA 高16位

startfind:
    add ax,1
    mov word [si+8],ax
    mov word [si+10],0

    mov ah,0x42
    mov dl,[DriverNum]
    int 0x13
    jc not_find

    ; 临时：直接跳转，不检查签名
    jmp is_find

    ; push es
    ; mov ax, 0x1000
    ; mov es, ax
    ; cmp word [es:0], 0xAA56
    ; pop es
    ; jz is_find
    ; jnz startfind

    ret ;返回

is_find:
    popa
    jmp 0x1000:0x0000

not_find:
    mov si,ERR_STR
    mov bl,0x10
    mov di,480
    call printstart

    jmp hlts

hlts:
    hlt                   ; 停止 CPU，等待下一次中断
    jmp hlts              ; 无限循环，防止继续执行未知代码

dap:
    db 0x10        ; 1字节：结构体大小 (16字节)
    db 0           ; 1字节：保留，必须是0
    dw 1           ; 2字节：要读取的扇区数
    dw 0x1000      ; 2字节：目标地址偏移
    dw 0x0000      ; 2字节：目标地址段
    dq 0           ; 8字节：起始LBA扇区号
     
Driver db 0,0  ;存储 BIOS 传来的驱动器号
DriverNum db 0
STARTBOOTMSG DB "Boot is starting...",0  ; 启动消息字符串，以 0 结束
Driver_STR db "Boot media",58,0 ;显示引导媒体信息的字符串，以 0 结束
LOAD_STR db "loading...",0 ;加载信息，以0结尾
ERR_STR db "Not Find the Kernel",0 ;错误信息
times 510 - ($ - $$) db 0
dw 0xAA55 ; 引导扇区的签名