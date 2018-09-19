;*****************************************************************************
;  Utils - Disk Info utility routines
;   
; 
;  Copyright, 2005 Greg Honsa
;*****************************************************************************
include pte.inc

 _Text SEGMENT PUBLIC USE16
  assume CS:_Text, DS:_Text

   
public LBA2CHS
;*****************************************************************************
;* LBA2CHS LBA to Cylinder Head Sector translation
;*
;*     cylinder = LBA / (heads_per_cylinder * sectors_per_track)
;*        temp = LBA % (heads_per_cylinder * sectors_per_track)
;*        head = temp / sectors_per_track
;*      sector = temp % sectors_per_track + 1
;*
;*      inputs:	EDX:EAX = LBA  
;*				BX -> DriveInfo
;*
;*	    outputs: CX = cylinder
;*               DH	= Head
;*         		 DL = Sector
;*					
;*****************************************************************************
LBA2CHS:
		assume bx:ptr DriveInfo 

	.386
		
		push	ecx
		push	eax

		xor		ecx,ecx
		xor		ax,ax
		mov		al,[bx].DIHeads
		inc		ax					; DIHeads is max head number from 0
		mov		cl,[bx].DISectors
		mul		cl
		mov		cx,ax
	
		pop		eax
		push	eax
		div		ecx
		; right now eax = cylinder, edx = temp from above
		mov		lbc,ax
		xor		eax,eax
		mov		al,[bx].DIHeads; of less then number of sectors, head =0
		cmp		edx,eax
		jg		calcHead
		mov		al,0
		mov		lbh,al
		mov		lbs,dl
		jmp		l2cok
calcHead:
		mov		eax,edx
		xor 	edx,edx
		xor		ecx,ecx
		mov		cl,[bx].DISectors
		div		ecx
		mov		lbh,al
		inc 	dx
		mov		lbs,dl
l2cok:
		pop		eax
		pop		ecx
		mov		cx,lbc
		cmp		cx,3feh
		jng		l2cout
		mov		cx,3feh
l2cout:
		mov		dh,lbh
		mov		dl,lbs
		ret		

lbc	dw	0
lbh	db	0
lbs	db	0

lbah	dd	0
lbal	dd	0

public CHS2LBA 
;*****************************************************************************
;* CHS2LBA
;* LBA = ( (cylinder * heads_per_cylinder + heads ) * sectors_per_track ) + sector - 1
;*
;*       inputs: BX -> DriveInfo
;*               CX = cylinder
;*               DH	= Head
;*         		 DL = Sector
;*
;*        outputs: EAX:EDX = LBA
;*****************************************************************************

CHS2LBA:
.386
		assume bx:ptr DriveInfo
		mov		lbc,cx
		mov		lbh,dh
		mov		lbs,dl
		xor		eax,eax
		mov		edx,eax
		mov		al,[bx].DIHeads
		mul		cx
		xor 	ecx,ecx
		mov		cl,lbh
		add		eax,ecx
		jnc		chs1
		inc		edx
chs1:
		mov		cl,[bx].DISectors
		mul		ecx
		xor		ecx,ecx
		mov		cl,lbh
		dec		cl
		add		eax,ecx
		jnc		chs2
		inc		edx
chs2:
.286
		ret

 
		
_Text ENDS
	END	
