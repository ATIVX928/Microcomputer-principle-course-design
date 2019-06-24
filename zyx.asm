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
;预留数据
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
		mov ax,data
		mov ds,ax
		mov es,ax
		nop
		
		call init8255
		call init8253
		call init8259
		call wriintver
		mov si,offset buffer
		mov bl,1
		mov si,seg led1
		mov di,offset led1
		sti
		nop
main0:
		jmp main0
		
init8255	proc near
		mov dx,k8255k
		mov al,10000001b
		out dx,al
		mov dx,k8255a
		mov ax,00000011b
		out dx,ax
		mov dx,k8255b
		mov ax,0f0h
		out dx,ax
		mov dx,k8255c
		mov ax,01111111b
		out dx,ax
init8255	endp
		
init8253	proc near
		mov dx,k8253k
		mov al,01000000b
		out dx,al
		mov dx,k8253a
		mov al,84h			;低八位
		out dx,al
		mov al,1eh			;高八位
		out dx,al
init8253	endp

init8259	proc near
		mov dx,io8259a_0
		mov al,13h
		out dx,al
		mov dx,io8259a_1
		mov al,08h
		out dx,al
		mov al,11
		out dx,al
		mov al,0feh
		out dx,al
		ret
init8259	endp

wriintver	proc near
		push es
		mov ax,0
		mov es,ax
		mov di,20h
		lea ax,int_0
		stosw
		mov ax,cs
		stosw
		pop es
		ret
wriintver	endp

day		proc near
		cmp cx,40
		jnz cx0
		mov cx,0
		cx0:
		push si
		push di
		add di,cx
		mov ax,[si:di]
		push dx
		mov dx,k8255a
		out dx,ax
		pop dx
		sub di,cx
		sub di,cx
		sub di,2
		mov ax,[si:di]
		push dx
		mov dx,k8255b
		out dx,ax
		pop dx
		mov ax,01111111b
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

night		proc near
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
