data segment
io8259a_0 equ 08000h
io8259a_1 equ 08001h
k8255a equ 0f000h
k8255b equ 0f001h
k8255c equ 0f002h
k8255k equ 0f003h
k8253k equ 0e003h
k8253a equ 0e000h
;数码管倒数序列
smg dw 3fh,06h,5bh,4fh,66h,6dh,7dh,07h,7fh,6fh,3fh,06h,5bh,4fh,66h,6dh,7dh,07h,7fh,6fh
;led序列
led1 dw 01101111b,01101111b,01101111b,01101111b,01101111b,01101111b,01101111b,10101111b,11101111b,10101111b,11010111b,11010111b,11010111b,11010111b,11010111b,11010111b,11010111b,11011011b,11011111b,11011011b
;预留数据，只使用了aa作为夜晚的状态存储器
aa dw 0
bb dw 0
cc dw 0
t1 dw 0
t2 dw 0
data ends
code segment
assume cs:code,ds:data
main:	
;初始化
		;数据地址初始化
		mov ax,data
		mov ds,ax
		mov es,ax
		nop
		
		;8255初始化，并行通信
		call init8255
		;8253初始化，外部定时器
		call init8253
		;8259初始化，外部硬件中断
		call init8259
		;中断初始化，分配中断地址
		call wriintver
		
		;初始化状态机地址
		mov si,offset buffer
		mov bl,1
		mov si,seg led1
		mov di,offset led1
		;使能中断
		sti
		nop
;主程序部分，采用中断方式控制，轮偱部分执行空指令
main0:
		nop
		jmp main0
		
init8255	proc near
		mov dx,k8255k
		;配置，a、b、c高位输出，c低位输入
		mov al,10000001b
		out dx,al
		mov dx,k8255a
		;初始化全亮
		mov ax,00000011b
		out dx,ax
		mov dx,k8255b
		mov ax,0f0h
		out dx,ax
		mov dx,k8255c
		mov ax,01111111b
		out dx,ax
		ret
init8255	endp
		
init8253	proc near
		mov dx,k8253k
		;初始化0通道，方式0
		mov al,01000000b
		out dx,al
		mov dx,k8253a
		;高八位和低八位组成定时器响应脉冲数，这里配置1S的定时器，就是等于引入脉冲数
		mov al,84h			;低八位
		out dx,al
		mov al,1eh			;高八位
		out dx,al
		ret
init8253	endp

init8259	proc near
		mov dx,io8259a_0
		;ICW1，上升沿出发，间隔为8，单片工作，写ICW4
		mov al,13h
		out dx,al
		mov dx,io8259a_1
		;ICW2，设置起始地址，08
		mov al,08h
		out dx,al
		;ICW4，完全嵌套方式，缓冲方式/从片，自动EOI，8086方式
		mov al,11
		out dx,al
		;OCW1，使能中断0
		mov al,0feh
		out dx,al
		ret
init8259	endp

wriintver	proc near
		push es
		mov ax,0
		mov es,ax
		mov di,20h
		;写入中断地址
		lea ax,int_0
		stosw
		;写入主程序段地址
		mov ax,cs
		stosw
		pop es
		ret
wriintver	endp

;白天子程序
day		proc near
		;寄存器cx作为指令表循环的伪指针，每次递增2，因为16位数地址为2（作者懒得改了，统一使用16位）
		cmp cx,40
		jnz cx0
		mov cx,0
		cx0:
		
		push si
		push di
		;LED灯部分
		add di,cx
		mov ax,[si:di]
		push dx
		mov dx,k8255a
		out dx,ax
		pop dx
		;数码管部分
		sub di,cx
		sub di,cx
		sub di,2
		mov ax,[si:di]
		push dx
		mov dx,k8255b
		out dx,ax
		pop dx
		mov ax,01111111b
		;数码管使能部分
		push dx
		mov dx,k8255c
		out dx,ax
		pop dx
		
		inc cx
		inc cx
		pop di
		pop si
		ret
day		endp

;夜晚子程序
night		proc near
		;夜晚逻辑是判断是否只有2盏黄灯亮起，亮起就熄灭，不亮就亮
		mov ax,aa
		cmp ax,10111011b
		mov ax,11111111b
		jz jz1
		mov ax,10111011b
		jz1:
		
		push dx
		mov dx,k8255a
		out dx,ax
		pop dx
		mov aa,ax
		ret
night		endp

;中断内的逻辑就是判断白天还是黑夜，选择执行哪一函数
int_0:		push dx
		push ax
		mov dx,k8255c
		in ax,dx
		and ax,1
		push ax
		cmp ax,1
		jnz jnz0
		call day
		jnz0:
		pop ax
		cmp ax,1
		jz jz0
		call night
		jz0:
		pop ax
		pop dx
		iret
		
code ends
end main
