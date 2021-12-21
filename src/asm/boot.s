section .multiboot2
MAGIC equ 0xe85250d6
ARCH equ 0x0    

header_start:
	dd 0xe85250d6                                             ; multiboot2 magic
	dd 0                                                      ; architecture (i386)
	dd header_end - header_start                              ; header length
	dd (1 << 32) - (0xe85250d6 + (header_end - header_start)) ; checksum

;align 8
;framebuffer_tag_start:
;	dw 5    ; type
;	dw 0    ; flags
;	dd 20   ; size 
;	dd 80   ; width
;	dd 25   ; height
;	dd 0    ; bpp
	
align 8
framebuffer_tag_end:
	dw 0    ; type
	dw 0    ; flags
	dw 8    ; size
header_end:

section .bss
align 4

stack_bottom:
	resb 16384 	; 16 KiB
stack_top:

g0_ptr:	        resd 1 
tcb_ptr:        resd 1 

section .text
bits 32
align 4

G_STACK_LO equ 0x0
G_STACK_HI equ 0x4
G_STACKGUARD0 equ 0x8

err_unsupported_bootloader db '[nugo-rt0] error: kernel not loaded by multiboot-compliant bootloader', 0

global _rt0_entry
_rt0_entry:
	cmp eax, 0x36d76289
	jne unsupported_bootloader

	mov esp, stack_top

	call _rt0_enable_sse

 	call _rt0_load_gdt

	extern runtime.g0
	mov dword [runtime.g0 + G_STACK_LO], stack_bottom
	mov dword [runtime.g0 + G_STACK_HI], stack_top
	mov dword [runtime.g0 + G_STACKGUARD0], stack_bottom
	mov dword [g0_ptr], runtime.g0

	extern main.main
	push ebx
	push eax
	call main.main

halt:
	cli
	hlt

unsupported_bootloader:
	mov edi, err_unsupported_bootloader
	call write_string
	jmp halt
.end:

write_string:
	push eax
	push ebx

	mov ebx,0xb8000
	mov ah, 0x4F
next_char:
	mov al, byte[edi]
	test al, al
	jz done

	mov word [ebx], ax
	add ebx, 2
	inc edi
	jmp next_char

done:
	pop ebx
	pop eax
	ret

_rt0_load_gdt:
	push eax
	push ebx

	mov eax, tcb_ptr
	mov [tcb_ptr], eax
	mov ebx, gdt0_gs_seg
	mov [ebx+2], al
	mov [ebx+3], ah
	shr eax, 16
	mov [ebx+4], al

	lgdt [gdt0_desc]

	jmp CS_SEG:update_descriptors
update_descriptors:
	mov ax, DS_SEG
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov ss, ax
	mov ax, GS_SEG
	mov gs, ax

	pop ebx
	pop eax
	ret

%include "gdt.inc"

align 2
gdt0:

gdt0_nil_seg: GDT_ENTRY_32 0x00, 0x0, 0x0, 0x0				                    ; null descriptor
gdt0_cs_seg:  GDT_ENTRY_32 0x00, 0xFFFFF, SEG_EXEC | SEG_R, SEG_GRAN_4K_PAGE    ; code descriptor
gdt0_ds_seg:  GDT_ENTRY_32 0x00, 0xFFFFF, SEG_NOEXEC | SEG_W, SEG_GRAN_4K_PAGE  ; data descriptor
gdt0_gs_seg:  GDT_ENTRY_32 0x00, 0xFFFFF, SEG_NOEXEC | SEG_W, SEG_GRAN_BYTE     ; TLS descriptor (required in order to use go segmented stacks)

gdt0_desc:
	dw gdt0_desc - gdt0 - 1
	dd gdt0

NULL_SEG equ gdt0_nil_seg - gdt0
CS_SEG   equ gdt0_cs_seg - gdt0
DS_SEG   equ gdt0_ds_seg - gdt0
GS_SEG   equ gdt0_gs_seg - gdt0

_rt0_enable_sse:
	push eax

	mov eax, 0x1
	cpuid
	test edx, 1<<25
	jz .no_sse

	mov eax, cr0
	and ax, 0xFFFB
	or ax, 0x2
	mov cr0, eax
	mov eax, cr4
	or ax, 3 << 9
	mov cr4, eax

	pop eax
	ret
.no_sse:
	cli
	hlt

; cgo stubs
global x_cgo_callers
global x_cgo_init
global x_cgo_mmap
global x_cgo_munmap
global x_cgo_notify_runtime_init_done
global x_cgo_sigaction
global x_cgo_thread_start
global x_cgo_setenv
global x_cgo_unsetenv
global _cgo_yield

x_cgo_callers:
x_cgo_init:
x_cgo_mmap:
x_cgo_munmap:
x_cgo_notify_runtime_init_done:
x_cgo_sigaction:
x_cgo_thread_start:
x_cgo_setenv:
x_cgo_unsetenv:
_cgo_yield:
	ret
