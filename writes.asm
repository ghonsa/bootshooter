
.286
;***********************************************************
;  Copyright 2005 Greg Honsa
;
;***********************************************************
 include pte.inc
public WriteSectExt


_Text SEGMENT PUBLIC USE16
  assume CS:_Text, DS:_Text
;******************************************************************************
;*    WriteSectExt - ES:DI -> transfer bufer
;*				 EDX:EAX = LBA
;*				 CL = drive
;*
;******************************************************************************

WriteSectExt:
		push	bx					; Save regs
.386
		push	edx
		push	eax
.286
		mov		bx,offset AdrPkt	; get packet address
	assume bx:ptr ExtBiosDiskAddrPkt
		mov		al,16
		mov		[bx].EBDAPSz,al		; set packet size
		xor		ax,ax
		mov		[bx].EBDAPres1,al	; zero out reserved
		mov		[bx].EBDAPres2,al
		mov		al,1				
		mov		[bx].EBDAPBlocks,al	; always 1 block (sector)

		push	es
		pop		ax					; Set pointer of transfer buffer
		mov		[bx].EBDAPHighPtr,ax
		mov		[bx].EBDAPLowPtr,di
		cli
.386
		xor		eax,eax
		mov		[bx].EBDAPFlatAdr1,eax	; Zero out flat addr
		mov		[bx].EBDAPFlatAdr2,eax
	
		pop		eax
		mov		[bx].EBDAPLBAhigh,edx	; set the LBA
		mov		[bx].EBDAPLBAlow,eax
.286 		
		mov		si,bx					; do the extended read
		mov		dl,cl
		mov		ax,4300h
		int		13h
.386
		pop		edx
.286	
		pop		bx
	
	
		ret 

;******************************************************************************
;*    WriteSect - ES:DI -> transfer bufer
;*				 
;*				 DL = drive
;*				 DH = head
;*               CL = sector
;*				 BX = cylinder
;*
;******************************************************************************
public WriteSectStd
WriteSectStd:
		push	dx
		push	cx
		push	bx

		mov		ch,bl		; cylinder low 8 bits

		mov		al,bh		; upper 2 bits of cylinder
		shl		al,6
		or		cl,al
		
		mov		ax,301h
		mov		bx,di
		int		13h
		pop		bx
		pop		cx
		pop		dx
		ret	


AdrPkt	ExtBiosDiskAddrPkt <?>


_Text ENDS
	END	
