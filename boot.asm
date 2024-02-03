;;;;;;;;;;;
; Start MBR
;;;;;;;;;;;
ORG 0x7c00
BITS 16

start:
	mov si, message
	call print_message
	jmp $

print_message:
	mov bx, 0
.loop:
	lodsb
	cmp al, 0
	je .done
	call print_char
	jmp .loop
.done:
	ret

print_char:
	mov ah, 0eh
	int 0x10
	ret

message db 'Starting barebone x86 OS ...', 0

times 510 - ($ - $$) db 0

; Boot sector signature
db 0x55
db 0xAA
;;;;;;;;;;;
; End MBR
;;;;;;;;;;;
