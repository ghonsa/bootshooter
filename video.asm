;***********************************************************
;  Copyright 2005 Greg Honsa
;
;***********************************************************
 include video.inc
 include vcontex.inc
 include vgutl.inc
 extrn	 VCCreate:near					   
_Text SEGMENT PUBLIC USE16	    
  assume CS:_Text, DS:_Text

											  
hellos		db	"Boot Shooter",0

activepage	dw	1
init_vid:
	mov		ax,105h
;
;   --- creae a video context for our request mode ---
;
	call	VCCreate  ; returns VDCONTX ptr in bx
	or		bx,bx
	jz		novid
;
;	--- Mode is set, set in a palette --- 
;
	assume bx:ptr VDCONTX
   	;call	 setPalette332
	mov		ax,0
	call	[bx].setVisiblePage
 				  
	mov		ax,activepage
	call	[bx].setActivePage
   mov		ax,0
	call	[bx].Clear
	
;
;  --- clear screen ---
;
 	mov		ax,0
	call	[bx].Clear
	mov		ax,0
	mov		ax,activepage
	inc		ax
	mov		activepage,ax
	call	[bx].setActivePage

 	mov		ax,0
	call	[bx].clear
;
; --- lets put up a pretty screen 
;
	mov		ax,1		; color index
	mov		cx,4
	mov		dx,4
	mov		di,[bx].vwidth
	sub		di,8
	mov		si,[bx].vheight
	sub		si,8
	call	[bx].fillRect
;
;  --- draw a border ---
;
	mov		ax,15		; color index
	mov		cx,4
	mov		dx,4
	mov		di,[bx].vwidth
	sub		di,8
	mov		si,[bx].vheight
	sub		si,8
	call	[bx].drawRect

	inc		cx
	inc		dx
	sub		si,2
	sub		di,2
	call	[bx].drawRect
	inc		cx
	inc		dx
	sub		si,2
	sub		di,2
	call	[bx].drawRect
	inc		cx
	inc		dx
	sub		si,2
	sub		di,2
	call	[bx].drawRect
	inc		cx
	inc		dx
	sub		si,2
	sub		di,2
	call	[bx].drawRect
	inc		cx
	inc		dx
	sub		si,2
	sub		di,2
	call	[bx].drawRect
	inc		cx
	inc		dx
	sub		si,2
	sub		di,2
	call	[bx].drawRect
	
	inc		cx
	inc		dx

 	mov		ax,14
	mov		cx,[bx].maxx
	shr		cx,1
	sub		cx,70

	;mov		cx,20
	mov		dx,20
	mov		di,1
	mov		si,offset hellos
	call	[bx].drawString


novid:
	ret
;*****************************************************************************
;   setPalette332 - Create a video pallet
;       inputs: BX -> VDCONTX
;		output: nothing - returns video back to origional mode
;*****************************************************************************

setPalette332:
	assume bx:ptr VDCONTX
	push	ax
	push	bx
	push	cx
	push	di

	xor		ax,ax	; red		
	mov		bx,ax	; green
	mov		cx,ax	; blue
	mov		di,offset colorbuff
   assume di:ptr VGACOLOR
rloop:
	cmp		ax,64
	jg		rdone
	mov		bx,0
	mov		cx,0
gloop:
	cmp		bx,64
	jg		gdone
	mov		cx,0
bloop:
	cmp		cx,64
	jg		bdone

	mov		[di].red,ax
	mov		[di].green,bx
	mov		[di].blue,cx
	
	add		di,sizeof VGACOLOR
	add		cx,21
	jmp		bloop	

bdone:
	add		bx,9
	jmp		gloop

gdone:
	add		ax,9
	jmp		rloop
rdone:
	mov		di,offset colorbuff
	mov		cx,256
	mov		bx,0
	call	vgaSetPalette
;
;    vgaSetPalette(0, 256, p);
;}

	pop		di
	pop		cx
	pop		bx
	pop		ax
	ret

colorbuff VGACOLOR 256 dup (<?>)
_Text ENDS
	END  

