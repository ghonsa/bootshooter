;*****************************************************************************
;  vgutl - video utility routines
;       Copyright 2005 Greg Honsa
;
;*****************************************************************************
 include video.inc

_Text SEGMENT PUBLIC USE16
  assume CS:_Text, DS:_Text

;*****************************************************************************
;
;  input di ->vgaColor buffer
;		 cx = count
;        bx = start index
;*****************************************************************************
public vgaSetPalette
vgaSetPalette:
	push	ax
	push	bx
	push	cx								     
	push	dx
	push	si
; 
;   --- check params ---
;
	mov		ax,di
	or		ax,ax
	jz		badparm
	cmp		bx,0
	jl		badparm
	mov		ax,bx
	add		ax,cx
	cmp		cx,256
	jg		badparm
;
;   --- wait for vertical retrace
;
	call	waitRetrace

	mov		dx,03c8h
	mov		ax,bx
	out		dx,al		; set start
	call	iowait	 

	mov		dx,3c9h
	mov		si,di		; get pointer to color buff
setpalloop:
   assume si:ptr VGACOLOR

	mov		ax,[si].red
	out		dx,al
	call	iowait	 

	mov		ax,[si].green
	out		dx,al
	call	iowait	 

	mov		ax,[si].blue
	out		dx,al
	call	iowait	 

	add		si,sizeof VGACOLOR
	loop	setpalloop

badparm:
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	ret

iowait:
	push	ax
	push	cx
	mov		cx,500
iwlp:
	mov		ax,1
	loop	iwlp
	pop		cx
	pop		ax
	ret
;*****************************************************************************
; vbeGetMode
;	output: bx = mde
;
;*****************************************************************************
public vbeGetMode
vbeGetMode:	
	push	ax
	mov		ax,4f03h
	int		10h
	cmp		ax,04fh
	pop		ax
	ret
;*****************************************************************************
; vbeSetMode - set video mode
;    input: BX = mode
;*****************************************************************************
public vbeSetMode
vbeSetMode:
		push	ax
		mov		ax,4f02h
		int		10h
		cmp		ax,04fh
		pop		ax
		ret
;*****************************************************************************
;  vbeGetInfo
;     inputs: BX -> VBEINFO
;
;
;*****************************************************************************
public vbeGetInfo
vbeGetInfo:
	push	ax
	push	di
	mov		di,bx
	mov		ax,4f00h
	int		10h
	cmp		ax,04fh
	pop		di
	pop		ax
	ret
;*****************************************************************************
;  vbeGetModeInfo 
;     input:  BX -> MODEINFO
;             CX = mode
;
;*****************************************************************************
public vbeGetModeInfo
vbeGetModeInfo:
	push	ax
	push	di
	mov		di,bx
   	mov 	ax,4F01h
	int		10h
	cmp		ax,04fh
	pop		di
	pop		ax
	ret
;*****************************************************************************
;  vbeSetBankAddr
;  	 inputs: AX = bank adr
;			 BX = 0 if bank A, 1 if bank B
;	 returns zero if ok
;*****************************************************************************
public vbeSetBankAddr
vbeSetBankAddr:
	push	ax
	push	bx
	push	dx

	mov		dx,ax
	mov		ax,4f05h
	int		10h
	cmp		ax,04fh

	pop		dx
	pop		bx
	pop		ax
	ret		
;*****************************************************************************
;  waitRetrace
;  	 inputs: nothing
;	 returns: nothing
;*****************************************************************************
public waitRetrace
waitRetrace:
	push	ax
	push	dx
rtloop:
	mov		dx,3dah
	in		al,dx
	and		al,8
	jnz		got_retrace
	push	ax
	pop		ax
	jmp		rtloop
got_retrace:
	pop		dx
	pop		ax
	ret

;*****************************************************************************
;  waitBlankEnd
;  	 inputs: nothing
;	 returns: nothing
;*****************************************************************************
public waitBlankEnd
waitBlankEnd:
	push	ax
	push	dx
blkloop:
	mov		dx,3dah
	in		al,dx
	and		al,9
	jz		got_blank
	push	ax
	pop		ax
	jmp		blkloop
got_blank:
	pop		dx
	pop		ax
	ret

;*****************************************************************************
;  vbeSetDisplayStart
;  	 inputs: AX = pixel
;            BX = line
;	 returns: 
;*****************************************************************************
public vbeSetDisplayStart
vbeSetDisplayStart:
	push	ax
	push	bx
	push	cx
	push	dx
	
	mov		dx,bx
	mov		cx,ax
	mov		bx,0
	mov		ax,4f07h
	int		10h
	cmp		ax,004fh
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	ret
;*****************************************************************************
;  memset
;  	 inputs: ES:DI mem pointer
;			 BX = fill value
;            CX = count
;	 returns zero if ok
;*****************************************************************************
public memset
memset:
	push	ax
	push	bx
	push	cx
	push	es
	push	di

	mov		ax,bx
	rep stosb

	pop		di
	pop		es
	pop		cx											   
	pop		bx
	pop		ax
	ret

if 0
;*****************************************************************************
;  Bitlt
;  	 inputs: SS:SP -> parameters:
;			 sorc x, sorc y
;			 dest x, dest y
;            size x, size y
;            operation ( copy, and, or, xor)
;	 returns zero if ok
;*****************************************************************************
;
;  --- input parameters ---
;
bltXsrc		EQU	[bp+4]
bltYsrc		EQU	[bp+6]
bltXdst		EQU	[bp+8]
bltYdst		EQU	[bp+10]
bltXsiz		EQU	[bp+12]
bltYsiz		EQU	[bp+14]
bltFnct		EQU	[bp+16]
bltXsrc		EQU	[bp+4]
;
;   --- tmp local storage --- 
;
YIncr		EQU	WORD PTR [bp-2]
FirstMask	EQU	WORD PTR [bp-4]
InFirst		EQU	WORD PTR [bp-6]
LastMask	EQU	WORD PTR [bp-8]
ReadPlane 	EQU	WORD PTR [bp-10]
LowMask		EQU	WORD PTR [bp-12]
UpMask		EQU	WORD PTR [bp-14]
SrcAddr		EQU	WORD PTR [bp-16]
DstAddr		EQU	WORD PTR [bp-18]
BlockDX		EQU	WORD PTR [bp-20]
BlockDY		EQU	WORD PTR [bp-22]


BitBlt:
		push	bp
		mov		bp,sp			; set up stack pointers
		sub		sp,24

		push	ds
		push	es
		push	di
		push	si

		mov
endif


_Text ENDS
	END	
