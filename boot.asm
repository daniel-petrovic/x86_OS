;;;;;;;;;;;
; Start MBR
;;;;;;;;;;;
; We are in REAL mode here, using CS,DS,ES,SS segment registers for addressing
ORG 0
BITS 16

;jmp 0x7c0:start
; Start BPB (BIOS Parameter Block)
; see https://wiki.osdev.org/FAT
jmp short start
nop
times 36 db 0 ; 36 = 32(==last offset) + 4(size on offset 32), see BPB description
; End BPB

handle_interrupt_0:
	mov ah, 0eh
	mov al, 'A'
	mov bx, 0x00
	int 0x10
	iret

handle_interrupt_1:
	mov ah, 0eh
	mov al, 'V'
	mov bx, 0x00
	int 0x10
	iret

start:
	;;;;;;;;;;;;
	; RAM
	;;;;;;;;;;;;
    ;.
    ;.
    ;.
    ;code, data are loaded upwards
    ;.
    ;.
    ;.
    ;
    ;0x7c00             -> BIOS will load bootloader at this address == DS*16 == ES*16, so set DS=ES=0x7c0
    ; SP growing downwards, so set SP = 0x7c00
    ;.
    ;.
    ;use for stack area, so set SS=0x00, so [SS:SP] = SS*16 + SP = 0x00 + SP
    ;.
    ;.
    ;.
    ;0x00 = SS -> here the IVT (Interrupt Vector Table will be loaded) (see IVT: https://wiki.osdev.org/IVT)

    cli                 ; clear interrupt flag -> disables interrupts
    mov ax, 0x7c0       ; for CS, DS segments
    mov ds, ax          ; set data segment
    mov es, ax          ; set extra segment

    mov ax, 0x00        ; for SS segment
    mov ss, ax
    mov sp, 0x7c00
    sti                 ; set interrupt flag -> enable interrupts
    ; The segment registers are now set

	mov word[ss:0x00], handle_interrupt_0 ; write interrupt(0) offset
	mov word[ss:0x02], 0x7c0				 ; write interrupt(0) segment

	mov word[ss:0x04], handle_interrupt_1	; write interrupt(1) offset
	mov word[ss:0x06], 0x7c0

	int 0	; trigger interrupt(0)
	int 1	; trigger interrupt(1)
	
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
    mov ah, 0eh     ; Int 0x10/AH=0Eh : VIDEO - TELETYPE OUTPUT
    int 0x10        ; https://web.archive.org/web/20191126123843/http://www.ctyme.com/intr/rb-0106.htm
    ret

message db 'Starting barebone x86 OS in real mode ...', 0

times 510 - ($ - $$) db 0

; Boot sector signature
db 0x55
db 0xAA
;;;;;;;;;;;
; End MBR
;;;;;;;;;;;
