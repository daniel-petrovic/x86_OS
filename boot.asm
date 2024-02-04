;;;;;;;;;;;
; Start MBR
;;;;;;;;;;;
; We are in REAL mode here, using CS,DS,ES,SS segment registers for addressing
ORG 0x7c00  ; ORG=0x7c00 needed (instead of 0) for set gdt entries correctly further below
BITS 16

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

;jmp 0x7c0:start
; Start BPB (BIOS Parameter Block)
; see https://wiki.osdev.org/FAT
jmp 0:start
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
    mov ax, 0x0       ; for CS, DS segments
    mov ds, ax          ; set data segment
    mov es, ax          ; set extra segment
    mov ss, ax
    mov sp, 0x7c00
    sti                 ; set interrupt flag -> enable interrupts
    ; The segment registers are now set

    mov si, message
    call print_message

.load_protected: ; Switch to protected mode: https://wiki.osdev.org/Protected_Mode
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 0x1         ; Set PE (Protection Enable Bit)
    mov cr0, eax
    jmp CODE_SEG:load32

; Global Descriptor Table (GDT): https://wiki.osdev.org/Global_Descriptor_Table
gdt_start:
gdt_null: ; Null GDT Entry - required
    dd 0x0
    dd 0x0

; offset 0x8 - code segment
gdt_code:       ; CS should point to this       
    dw 0xffff   ; Segment limit first 0-15 bits
    dw 0        ; Base first 0-15 bits
    dw 0        ; Base 16-23 bits
                ;                    Pr  Privl  S   Ex  DC  RW  A                               
    db 0x9a     ; Access byte 0x9a = 1    0 0   1   1   0   1   0
    db 11001111b ; High 4 bit flags and the low 4 bit flags

; offset 0x10 - data segment
gdt_data:       ; DS,SS,ES,FS,GS    
    dw 0xffff   ; Segment limit first 0-15 bits
    dw 0        ; Base first 0-15 bits
    dw 0        ; Base 16-23 bits
                ;                    Pr  Privl  S   Ex  DC  RW  A                               
    db 0x92     ; Access byte 0x9a = 1    0 0   1   0   0   1   0
    db 11001111b ; High 4 bit flags and the low 4 bit flags

gdt_end:
gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

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

[BITS 32]
load32:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x00200000
    mov esp, ebp
    jmp $

times 510 - ($ - $$) db 0

; Boot sector signature
db 0x55
db 0xAA
;;;;;;;;;;;
; End MBR
;;;;;;;;;;;

buffer:
