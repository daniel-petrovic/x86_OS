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

    mov si, message
    call print_message

	; load next sector (sector == 2)
	; BIOS Int 0x13/AH=02h : DISK - READ SECTORS INTO MEMORY: https://web.archive.org/web/20191111094211/http://www.ctyme.com/intr/rb-0607.htm
	;AH = 02h
	;AL = number of sectors to read (must be nonzero)
	;CH = low eight bits of cylinder number
	;CL = sector number 1-63 (bits 0-5)
	;high two bits of cylinder (bits 6-7, hard disk only)
	;DH = head number
	;DL = drive number (bit 7 set for hard disk)
	;ES:BX -> data buffer

	;Return:
	;CF set on error
	;if AH = 11h (corrected ECC error), AL = burst length
	;CF clear if successful
	;AH = status (see #00234)
	;AL = number of sectors transferred (only valid if CF set for some
	;BIOSes)
	mov ah, 02h
	mov al, 1		; number of sectors to read
	mov ch, 0		; low eight bits of cylinder number
	mov cl, 2		; sector number 
	mov dh, 0		; head number
	; dl == drive number is already set by the BIOS
	mov bx, buffer
	int 0x13
	jc error
	mov si, buffer	; try print out the buffer we loaded
	call print_message
    jmp $

error:
	mov si, error_message
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
error_message db 'Failed to load sector', 0

times 510 - ($ - $$) db 0

; Boot sector signature
db 0x55
db 0xAA
;;;;;;;;;;;
; End MBR
;;;;;;;;;;;

buffer:
