#include "textflag.h"

TEXT ·Outb(SB),NOSPLIT,$0
	MOVW port+0(FP), DX
	MOVB val+2(FP), AX
	BYTE $0xee
	RET

TEXT ·Inb(SB),NOSPLIT,$0
	MOVW port+0(FP), DX
	BYTE $0xec
	MOVB AX, ret+0(FP)
	RET

TEXT ·Outw(SB),NOSPLIT,$0
	MOVW port+0(FP), DX
	MOVW val+2(FP), AX
	BYTE $0x66 
	BYTE $0xef
	RET

TEXT ·Inw(SB),NOSPLIT,$0
	MOVW port+0(FP), DX
	BYTE $0x66  
	BYTE $0xed
	MOVW AX, ret+0(FP)
	RET

TEXT ·Outl(SB),NOSPLIT,$0
	MOVW port+0(FP), DX
	MOVL val+2(FP), AX
	BYTE $0xef
	RET

TEXT ·Inl(SB),NOSPLIT,$0
	MOVW port+0(FP), DX
	BYTE $0xed
	MOVL AX, ret+0(FP)
	RET
