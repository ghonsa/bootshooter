;*****************************************************************************
;  vcontex - video context object
;       Copyright 2005 Greg Honsa
;
;*****************************************************************************
 include vgutl.inc
 include vcontex.inc
 extrn activeWindow:near

_Text SEGMENT PUBLIC USE16
  assume CS:_Text, DS:_Text

 vc VDCONTX <?>
;
;   --- local storage used by rect functions ---
;
xpos		dw	?		
ypos		dw	?
xend		dw	?
yend		dw	?
rctlines	dw	?
rctcolor	dw	?
rctwidth	dw	?
rctheight	dw	?
colmoffset	dw	?						    
rowoffset	dw	?
strtoff		dd	?
strtbnk		dw	?
endoff		dd	?
endbnk		dw	?
rectFunc	dw	0
fntwidth	dw	?
charx		dw	10
chary		dw	10
;*****************************************************************************
;   VCCreate - Create a video context for the requested mode
;       inputs: AX -> Video mode
;		output: BX -> VDCONTX struct
;	
;*****************************************************************************
public VCCreate

VCCreate:
;
;   --- get the VDCONTX struct pointer --- for now just 1 ---
; 		
	push	ax													 
	push	cx
	push	di
	;push	es

	mov		di,offset vc
	assume di:ptr VDCONTX
	mov		[di].currentMode,ax
;
;   --- check video support ---
;
	lea		bx,[di].vbi
	call	vbeGetInfo
	jnz		noevid

   assume bx:ptr VBEINFO

   	mov		al,[bx]
   	cmp		al,'V'
   	jnz		noevid
   							    	    
   	inc		bx
   	mov		al,[bx]
   	cmp		al,'E'
   	jnz		noevid

   	inc		bx
   	mov		al,[bx]
   	cmp		al,'S'
   	jnz		noevid
;
;   -- check version ---
;
	mov		ax,[bx].vbeversion

;
;   --- get info on the mode we want ---
;
	mov		cx,[di].currentMode
	lea		bx,[di].vmi
	call	vbeGetModeInfo
	jnz		noevid

   assume bx:ptr MODEINFO

	mov		ax,[bx].modeattributes
	and		ax,1
	jz		noevid

	mov		al,[bx].bitsperpixel
	cmp		al,8
	jnz		noevid

	mov		ax,[bx].xresolution
	mov		[di].vwidth,ax
	dec		ax
	mov		[di].maxx,ax
	mov		ax,[bx].yresolution
	mov		[di].vheight,ax
	dec		ax
	mov		[di].maxy,ax

	mov	    ax,-1
	mov		[di].currentBank,ax

	xor		ax,ax
	mov		[di].activePage,ax
	mov		[di].activePageOffset,ax
	mov		[di].visiblePage,ax

	mov		ax,[bx].xresolution
	mov		cx,[bx].yresolution
	mul		cx
	inc		dx
	mov		[di].banksPerPage,dx
;
;   --- save the origional mode ---
;
	call	vbeGetMode
	jc		noevid
	mov		[di].origMode,bx
;
;   ---   set the new mode ---
;
    mov		bx,[di].currentMode
	call	vbeSetMode
	jc		noevid

public getfnt
getfnt:

	mov		bx,100h
    mov     ax, 1130h    ; Service to Get Pointer
    int     10h                 ; Call VGA BIOS
	jc		noevid
	mov		fntwidth,cx
	mov		[di].fontSeg,es
	mov		[di].fontOff,bp

;																 
;   --- populate the function pointers ---
;
	mov		ax,offset VCCreate
	mov		[di].Create,ax
	mov		ax,offset VCDestroy
	mov		[di].Destroy,ax
	mov		ax,offset VCClear
	mov		[di].Clear,ax
	mov		ax,offset getNumPages
	mov		[di].getNumPages,ax
	mov		ax,offset setActivePage
	mov		[di].setActivePage,ax
	mov		ax,offset setVisiblePage
	mov		[di].setVisiblePage,ax
	mov		ax,offset pixel
	mov		[di].pixel,ax
	mov		ax,offset fillRect
	mov		[di].fillRect,ax
	mov		ax,offset drawChar 
	mov		[di].drawChar,ax
	mov		ax,offset drawLine 
	mov		[di].drawLine,ax
	mov		ax,offset drawRect
	mov		[di].drawRect,ax
	mov		ax,offset drawString
	mov		[di].drawString,ax
	mov		ax,offset createWindow
	mov		[di].createWindow,ax
	mov		ax,offset createButton
	mov		[di].createButton,ax
	mov		bx,di
	jmp		crtdone


noevid:
	xor		bx,bx
crtdone:

	;pop		es
	pop		di
	pop		cx
	pop		ax
	ret

;*****************************************************************************
;   VCDestroy - Create a video context for the requested mode
;       inputs: BX -> VDCONTX struct
;		output: nothing - returns video back to origional mode
;*****************************************************************************
VCDestroy:
		push	ax
		push	di
		mov		di,bx
	assume di:ptr VDCONTX
		mov		bx,[di].origMode
		call	vbeSetMode
		pop		di
		pop		ax
		ret
;*****************************************************************************
;   VCClear - Clears and fills the video with a color
;       inputs: AX = color
;				BX -> VDCONTX struct
;		output: nothing - 
;*****************************************************************************
public VCClear
VCClear:
	assume bx:ptr VDCONTX
	push	ax
	push	bx
	push	cx
	push	dx
	push	es

	mov		dx,ax		; save color
;    for (i = 0; i < banksPerPage; i++)
	mov		cx,0
vcclp:
;    {
;        currentBank = i + activePageOffset;
	
	mov		ax,[bx].activePageOffset
	add		ax,cx
	mov		[bx].currentBank,ax
;        vbeSetBankAAddr(i + activePageOffset);
	push	bx

	mov		bx,0
    call	vbeSetBankAddr    
	
	push	cx
;        memset(MK_FP(0xa000, 0), color, 0x8000);
	mov		bx,dx			; get color
	mov		dx,0a000h
	mov		es,dx
	xor		di,di
	mov		cx,8000h
	call	memset
;        memset(MK_FP(0xa000, 0x8000), color, 0x8000);
	;mov		bx,dx			; get color
	mov		dx,0a000h
	mov		es,dx
	mov		di,8000h    
	mov		cx,8000h
	call	memset
	mov		dx,bx
	pop		cx
	pop		bx
		
	inc		cx
	cmp		cx,[bx].banksPerPage
	jl		vcclp
;    }
	pop		es
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	ret
;*****************************************************************************
;   setActivePage - 
;       inputs: AX = page
;				BX -> VDCONTX struct
;		output: ax = page if ok else -1 
;*****************************************************************************
setActivePage:
	push	bx
	push	cx
	push	dx
	assume bx:ptr VDCONTX
	
	cmp		ax,0
	jl		badpage
	mov		cx,ax
	call	getNumPages
	cmp		ax,cx
	jge		badpage

   	mov		[bx].activePage,cx
   	mov		ax,[bx].banksPerPage
   	mul		cx
   	mov		[bx].activePageOffset,ax
	mov		ax,cx
	jmp		sapout
badpage:
	mov		ax,-1
sapout:
	pop		dx
	pop		cx
	pop		bx
	ret

;*****************************************************************************
;   setVisiblePage - 
;       inputs: AX = page
;               BX -> VDCONTX struct
;		returns 0 if ok 
;*****************************************************************************
svpline	dw	?
svppixel	dw	?

setVisiblePage:
		push	ax
		push	bx
		push	cx
		push	dx		

;    int16 pixel, line;
;    int32 address;
;
;    if (page < 0 || page >= getNumPages())
;    {
;        error = badPage;
;        return;
;    }
		cmp		ax,0
		jl		svpbadpage
		mov		cx,ax
		call	getNumPages
		cmp		ax,cx
		jge		svpbadpage
;    visiblePage = page;
		mov		[bx].visiblePage,cx
;    address = ((int32)banksPerPage * (int32)page) << 16;
		mov		ax,[bx].banksPerPage
		mul		cx
		mov		dx,ax
		xor		ax,ax
;    line = address / (int32)modeInfo.width;
;    pixel = address % (int32)modeInfo.width;
		lea		bx,[bx].vmi
		assume bx:ptr MODEINFO
		mov		cx,[bx].xresolution

		push	dx
		push	ax
		div		cx
		;mov		line,ax
		;mov		pixel,dx

;    while(inp(0x3da) & 0x09);    // wait for blanking to end
		call	waitBlankEnd
;    vbeSetDisplayStart(pixel, line);
		mov		bx,ax
		mov		ax,dx
		call	vbeSetDisplayStart
		pop		ax
		pop		dx
;    while(!(inp(0x3da) & 0x08));    // wait for vertical retrace
		call	waitRetrace
		mov		al,0
		or		al,al
		jmp		svpdone
svpbadpage:
		mov		al,1
		or		al,al
svpdone:
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		ret

;*****************************************************************************
;   pixel - 
;       inputs: AX = color
;				BX -> VDCONTX struct
;				CX = x loc
;               DX = y loc
;		output: ax = page if ok else -1 
;*****************************************************************************
public pixel
pixel:
		push	bx
		push	es
		push	di
		push	cx
				
	assume bx:ptr VDCONTX
    ;int32 offset;
    ;int16 bank;
    ;uint8 *address;
	;//
    ;// first clip to the mode width and height
    ;//
    ;if (x < 0 || x > maxx || y < 0 || y > maxy)
    ;{
    ;    return;
    ;}
		cmp		cx,0
		jb		pixbad
		cmp		cx,[bx].maxx
		jz		pixbad
		cmp		dx,0
		jb		pixbad
		cmp		dx,[bx].maxy
		jz		pixbad
    ;//
    ;// compute the pixel address and then convert
    ;// it into a bank number and an offset.
    ;// finally generate a pointer into the
    ;// video page
    ;//
		push	ax
		push	dx
		;offset = ((int32)y * (int32)modeInfo.width) + (int32)x;
		mov		ax,[bx].vwidth
		mul		dx
		add		ax,cx
		jnc		pixnc
		inc		dx
pixnc:
    ;bank = (offset >> 16) + activePageOffset;
    	add		dx,[bx].activePageOffset ; dx = bank
    ;address = (uint8 *) MK_FP(0xa000, (int)(offset & 0xffffL));
		mov		cx,0a000h
		mov		es,cx		; es:di address
		mov		di,ax
    ;//
    ;// select the video page if we need to
    ;//
    ;if (bank != currentBank)
		cmp		dx,[bx].currentBank
		jz		pixbnkok
    ;{
    ;    currentBank = bank;
    ;    vbeSetBankAAddr(currentBank);
    ;}
		push	bx
		mov		[bx].currentBank,dx
		mov		ax,dx
		mov		bx,0				     
		call	vbeSetBankAddr
		pop		bx
 
 pixbnkok:
 	;
    ;//
    ;// write the pixel
    ;//
    ;*address = (uint8)color;
		pop		dx
		pop		ax
		stosb
pixbad:

		pop		cx
		pop		di
		pop		es
		pop		bx
		ret
;}

;*****************************************************************************
;   drawLine - 
;       inputs: AX = color
;				BX -> VDCONTX struct
;				CX = x start loc
;               DX = y start loc
;				DI = x end 
;				SI = yend 
;		output: ax = 0 success 
;*****************************************************************************
drawLine:
		push	cx
		push	dx
	assume	bx:ptr VDCONTX
		cmp		cx,di
		jnz		dl_not_single
		cmp		dx,si
		jnz		dl_not_single
		call	pixel
		jmp		dl_done
dl_not_single:
		cmp		cx,di
		jnz		dl_ckHorz
; -- verticle line --

vertlp:
		call	pixel
		inc		dx
		cmp		dx,si
		jnz		vertlp
		jmp		dl_done	  

dl_ckHorz:
		cmp		dx,si
		jnz		dl_done
horzlp:
		call	pixel
		inc		cx
		cmp		cx,di
		jnz		horzlp

dl_done:
		pop		dx
		pop		cx
		ret

;*****************************************************************************
;   createWindow - 
;       inputs: SI ->GWIND struct
;				BX -> VDCONTX struct
;		output: ax = 0 success 
;*****************************************************************************
createWindow:
	push	ax
	push	cx
	push	dx
	push	di
	push	bp

	assume si:ptr GWIND
	mov		cx,[si].xorg
	mov		ax,[si].xsiz
	add		ax,cx
	mov		[si].xend,ax	

	mov		dx,[si].yorg
	mov		ax,[si].ysiz
	add		ax,dx
	mov		[si].yend,ax	
	
	mov		di,[si].xsiz

	mov		ax,[si].bcolor

	push	si
	mov		si,[si].ysiz
	call	[bx].fillRect
	pop		si	

; -- hilite the box	top --
	mov		cx,[si].xorg
	mov		dx,[si].yorg
	mov		di,[si].xsiz
	add		di,cx
	mov		bp,2
	mov		ax,16

	push	si
	mov		si,dx
cwlp1:
	call	[bx].drawLine
	inc		dx
	inc		si
	dec		bp
	jnz		cwlp1
	pop		si

; -- hilite the left side -
	mov		cx,[si].xorg
	mov		dx,[si].yorg
	mov		di,cx
	mov		bp,2
	mov		ax,16

	push	si
	mov		si,[si].ysiz
	add		si,dx
cwlp2:
	call	[bx].drawLine
	inc		cx
	inc		di
	dec		bp
	jnz		cwlp2
	pop		si

; -- hilite the bottom
	mov		bp,1
	mov		ax,15
	mov		cx,[si].xorg
	add		cx,3
	mov		dx,[si].yorg								   
	add		dx,[si].ysiz							

	mov		di,[si].xsiz
	add		di,cx
	sub		di,3

	push	si
	mov		si,dx
cwlp3:
	call	[bx].drawLine
	dec		dx
	dec		si
	dec		bp
	jnz		cwlp3
	pop		si

; -- hilite the right side --
	mov		cx,[si].xorg
	add		cx,[si].xsiz	
	mov		dx,[si].yorg
	mov		di,cx
	mov		bp,1
	mov		ax,15

	push	si
	mov		si,[si].ysiz
	add		si,dx
	inc si
cwlp4:
	call	[bx].drawLine
	dec		cx
	dec		di
	dec		bp
	jnz		cwlp4
	pop		si


	pop		bp
	pop		di
	pop		dx
	pop		cx
	pop		ax
	ret
;*****************************************************************************
;   createButton - 
;       inputs: SI ->GWIND struct
;				BX -> VDCONTX struct
;		output: ax = 0 success 
;*****************************************************************************
createbutton:
	push	ax
	push	cx
	push	dx
	push	di
	push	bp

	assume si:ptr GWIND
	mov		cx,[si].xorg
	mov		ax,[si].xsiz
	add		ax,cx
	mov		[si].xend,ax	

	mov		dx,[si].yorg
	mov		ax,[si].ysiz
	add		ax,dx
	mov		[si].yend,ax	
	
	mov		di,[si].xsiz

	mov		ax,[si].bcolor

	push	si
	mov		si,[si].ysiz
	call	[bx].fillRect
	pop		si	

; -- hilite the box	top --
	mov		cx,[si].xorg
	mov		dx,[si].yorg
	mov		di,[si].xsiz
	add		di,cx
	mov		bp,2
	mov		ax,15

	push	si
	mov		si,dx
cblp1:
	call	[bx].drawLine
	inc		dx
	inc		si
	dec		bp
	jnz		cblp1
	pop		si

; -- hilite the left side -
	mov		cx,[si].xorg
	mov		dx,[si].yorg
	mov		di,cx
	mov		bp,2
	mov		ax,15

	push	si
	mov		si,[si].ysiz
	add		si,dx
cblp2:
	call	[bx].drawLine
	inc		cx
	inc		di
	dec		bp
	jnz		cblp2
	pop		si

; -- hilite the bottom
	mov		bp,2
	mov		ax,16
	mov		cx,[si].xorg
	add		cx,3
	mov		dx,[si].yorg								   
	add		dx,[si].ysiz							

	mov		di,[si].xsiz
	add		di,cx
	sub		di,3

	push	si
	mov		si,dx
cblp3:
	call	[bx].drawLine
	dec		dx
	dec		si
	dec		bp
	jnz		cblp3
	pop		si

; -- hilite the right side --
	mov		cx,[si].xorg
	add		cx,[si].xsiz	
	mov		dx,[si].yorg
	mov		di,cx
	mov		bp,2
	mov		ax,16

	push	si
	mov		si,[si].ysiz
	add		si,dx
	inc si
cblp4:
	call	[bx].drawLine
	dec		cx
	dec		di
	dec		bp
	jnz		cblp4
	pop		si


	pop		bp
	pop		di
	pop		dx
	pop		cx
	pop		ax
	ret

;*****************************************************************************
;   drawRect - 
;       inputs: AX = color
;				BX -> VDCONTX struct
;				CX = x loc
;               DX = y loc
;				DI = width
;				SI = height
;		output: ax = 0 success 
;*****************************************************************************
public drawRect
drawRect:
		push	ax
		push	cx
		push	dx
;
;   --- save parameters ---
;
		mov		rctcolor,ax
		mov		xpos,cx			; x position
		mov		ypos,dx			; y position
		add		cx,di			; calc end x
		mov		xend,cx
		add		dx,si			; and end y
		mov		yend,dx
		mov		rctwidth,di		; widths
		mov		rctheight,si
;
;   --- draw top horizontal line ---
;		
		mov		cx,xpos
		mov		dx,ypos
		mov		ax,rctcolor
toplp:
		call	pixel
		inc		cx
		cmp		cx,xend
		jnz		toplp
		dec		cx
;		
;   --- right side ---
;
rightlp:
		call	pixel
		inc		dx
		cmp		dx,yend
		jnz		rightlp
		dec		dx
;
;   --- bottom ---
;
bottomlp:
		call	pixel
		dec		cx
		cmp		cx,xpos
		jnb		bottomlp
		inc		cx
		dec		dx
leftlp:
		call	pixel
		dec		dx
		cmp		dx,ypos
		jnb		leftlp
		pop		dx
		pop		cx
		pop		ax
		ret
;*****************************************************************************
;   fillRect - 
;       inputs: AX = color
;				BX -> VDCONTX struct
;				CX = x loc
;               DX = y loc
;				DI = width
;				SI = height
;		output: ax = 0 success 
;*****************************************************************************
public fillRect
fillRect:
assume bx:ptr VDCONTX
		push	ax
		mov		rctcolor,ax
		mov		ax,offset fillr
		call	processRect
		pop		ax
		ret


;*****************************************************************************
;   fillr -  callback
;       inputs: ES:DI -> video memory
;				BX -> VDCONTX struct
;				CX = width
;				DX = column offset (
;				AX = row offset
;		output:  
;*****************************************************************************


fillr:
 ;            memset(address, color, width);
 ;            address += modeInfo.width;
		push	ax
 		push	bx
 		push	cx
 		push	es
		push	di
	
 		mov		bx,rctcolor
	
 		call	memset

		pop		di
		pop		es
 		pop		cx
 		pop		bx
		pop		ax
		ret

;*****************************************************************************
;   drawString - 
;       inputs: AX = color ( 0-256)
;				BX -> VDCONTX struct
;				CX = xloc	 0 use last location
;				DX = yloc	 0
;				DI = bkcolor
;				SI = null terminated string
;		output:  
;*****************************************************************************
drawString:
	push	ax
	push	cx
	push	dx
	push	di
	push	ds
	push	si
	xchg	al,ah
	or		dx,dx
	jnz		charloop
	or		cx,cx
	jnz		charloop
	mov		cx,0
	mov		dx,0
charloop:
	lodsb
	or		al,al
	jz		chardone
	call	[bx].drawChar
	;mov		cx,charx
	;mov		dx,chary

	jmp		charloop

chardone:
 	pop		si
	pop		ds
	pop		di
	pop		dx
	pop		cx
	pop		ax
	ret

;*****************************************************************************
;   drawChar - 
;       inputs: AL = char
;				AH = color ( 0-256)
;				BX -> VDCONTX struct
;				CX = xloc
;				DX = yloc
;				DI = bkcolor
;		output:  
;*****************************************************************************
vchar		db	?
cchar		db	?
bclr		db	?
cfontseg	dw	?
cfontoff	dw	?

.386
	assume bx:ptr VDCONTX
public drawChar
drawChar:
		push	ax
		;push	cx
		;push	dx
		push	si
		push	di
		push	es

		mov		si,word ptr activeWindow
		assume si:ptr GWIND
		push	ax
		mov		ax,[si].bcolor
		mov		bclr,al
		mov		ax,[si].ccolor
		mov		cchar,al
		pop		ax

		or		dx,dx
		jnz		dc1
		or		cx,cx
		jnz		dc1
		mov		cx,[si].currx
		mov		dx,[si].curry
dc1:

		cmp		al,0dh
		jnz		dcCklf
		mov		cx,[si].xorg
		add		cx,4
		jmp		chdone
dcCklf:
		cmp		al,0ah
		jnz		dc2
		add		dx,16
		jmp		chdone

dc2:
		cmp		cx,[si].xend
		jb		dc3
		mov		cx,[si].xorg
		add		cx,4
		add		dx,16
dc3:		
		mov		[si].currx,cx
		mov		vchar,al
		mov		ax,di
		mov		bclr,al
;
;		--- get pointer to font ---
;
		mov		al,vchar
		xor		ah,ah

		push	dx
	   	mul		fntwidth
		pop		dx
		add		ax,[bx].fontOff
		mov		cfontoff,ax
fonst:	
	
		mov		ax,[bx].fontSeg
		mov		cfontseg,ax
		xor		ah,ah
		mov	   	di,8

		push	si
		mov		si,fntwidth
		mov		ax,offset charr
		call	processRect
		pop		si

		mov		cx,[si].currx
		add		cx,7
		cmp		cx,[si].xend
		jb		chdone
		mov		cx,[si].xorg
		add		cx,4
		add		dx,16
chdone:
		mov		[si].currx,cx
		mov		[si].curry,dx
		
		pop		es
		pop		di
		pop		si
		;pop		dx
		;pop		cx
		pop		ax
		ret
;*****************************************************************************
;   charr -  callback
;       inputs: ES:DI -> video memory
;				BX -> VDCONTX struct
;				CX = width
;				DX = column offset 
;				AX = row offset
;		output:  
;*****************************************************************************
charr:
		push	ax
		push	bx
		push	cx
		push	dx
		push	di
		
		push	es
		push	si
	   	mov		es,cfontseg
		mov		si,cfontoff
	   	mov		bx,ax
		mov		al,es:[si][bx]	   ; get the current row of dots

		pop		si
		pop		es
	   
		clc
chrloop:		
		mov		bl,bclr 
		rcl		al,1
		jnc		stbk
		mov		bl,cchar
stbk:		
		push	ax
		mov		al,bl
		stosb
		pop		ax
		loop	chrloop

		;mov		ax,cfontoff
		;add		ax,8
		;mov		cfontoff,ax

		pop		di
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		ret

;*****************************************************************************
;   processRect - 
;       inputs: AX = callback ptr 
;				BX -> VDCONTX struct
;				CX = x loc
;               DX = y loc
;				DI = width
;				SI = height
;		output: ax = 0 success 
;
;		notes: The callback	function is passed the screen memory address,
;              width, row, col offset ( 0 unless clipped) 
;*****************************************************************************
processRect:
		push	ax
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	es
assume bx:ptr VDCONTX
;
;   --- save callback, start position and calc end position ---
;
		mov		rectFunc,ax
		mov		xpos,cx			; x position
		mov		ypos,dx			; y position
		add		cx,di			; calc end x
		dec		cx
		mov		xend,cx
		add		dx,si			; and end y
		dec		dx
		mov		yend,dx
		mov		rctwidth,di		; widths
		mov		rctheight,si
		xor		ax,ax
		mov		colmoffset,ax
		mov		rowoffset,ax
;
;   --- clip to the screen ---
;
		mov		ax,xpos
		cmp		ax,0			; check for starting x off screen
		jge		fr1
		sub		ax,0
		mov		colmoffset,ax	; set offset
		mov		xpos,0	
fr1:
		mov		ax,xend			; or off the end
		cmp		ax,[bx].maxx
		jle		fr2
		mov		ax,[bx].maxx
		mov		xend,ax
fr2:
		mov		ax,ypos			; check for y starting off screen
		cmp		ax,0
		jge		fr3
		sub		ax,0
		mov		rowoffset,ax	; set offset
		mov		ypos,0	
fr3:
		mov		ax,yend			; or off the end
		cmp		ax,[bx].maxy
		jle		fr4
		mov		ax,[bx].maxy
		mov		yend,ax
fr4:
		mov		ax,yend			; check if anything left to display
		cmp		ax,ypos
		jl		norect
	
		mov		ax,xend
		cmp		ax,xpos
		jg		havrect
norect:
		jmp		rectdone
;
;   --- somthing to display ---
; 
havrect:
  	 	mov		ax,xend		 	; calc width
		sub		ax,xpos
		mov		di,ax
		mov		rctwidth,ax		
;
;    --- compute the start and end pages ---
;    
		mov		ax,[bx].vwidth
		mov		dx,ypos
		mov		cx,xpos
		mul		dx
		add		ax,cx
		jnc		rrct2
		inc		dx
rrct2:
		mov		word ptr strtoff,ax
		mov		word ptr strtoff+2,dx
		; startBank = (offset >> 16) + activePageOffset;
    	add		dx,[bx].activePageOffset ; dx = bank
		mov		strtbnk,dx
		; endOffset = ((int32)y2 * (int32)modeInfo.width) + (int32)x2;
		mov		ax,[bx].vwidth
		mov		dx,yend
		mov		cx,xend
		mul		dx
		add		ax,cx
		jnc		rrct3
		inc		dx
rrct3:
		mov		word ptr endoff,ax
		mov		word ptr endoff+2,dx
		; endBank = (endOffset >> 16) + activePageOffset;
    	add		dx,[bx].activePageOffset ; dx = bank
		mov		endbnk,dx
;   
;    --- select the video page if we need to
;    
		mov		dx,strtbnk				; check current bank
		cmp		dx,[bx].currentBank
		jz		rctbnkok

		push	bx						; set the bank we need
		mov		[bx].currentBank,dx
		mov		ax,dx
		mov		bx,0				     
		call	vbeSetBankAddr
		pop		bx
rctbnkok:
;
;   --- check if all in one bank ---
;
		mov		ax,strtbnk
		cmp		ax,endbnk
		jnz		multibnk	
;
;   --- one bank, do it in one pass ---
;
		push	es
		mov		di,word ptr strtoff		
		mov		dx,0a000h
		mov		es,dx			;
		mov		cx,ypos
		mov		ax,0
srctlp:		
 		push	cx
 		mov		cx,rctwidth
;       inputs: ES:DI -> video memory
;				BX -> VDCONTX struct
;				CX = width
;               DX = Column offset
		mov		dx,0
		call	rectFunc
		inc		ax
 		pop		cx
 		inc		cx
 		cmp		cx,yend
		jg		sbfl1

		add		di,[bx].vwidth
 		jmp		srctlp
		inc		ax
sbfl1:
		pop		es
		jmp		rectdone

;    }
;    else
multibnk:
;    {
;        //
;        // the rectangle spans more than one page
;        // do as much as you can in each page
;        //
;        height = y2 - y1 + 1;
		mov		cx,yend
		sub		cx,ypos
		inc		cx
		mov		ax,0
		mov		currRow,ax
;        while (height > 0)
mltbklp:
		cmp		cx,0
		jg		mbkok
		jmp		rectdone
startoff	dd		?
currRow		dw	?
mbkok:
;        {
;            uint32 start;
;
;            //
;            // how many scan lines of the rectangle
;            // fit on this page?
;            // 
;            lines = (0x10000L - offset) / modeInfo.width;
			.386
			 mov		eax,10000h
			 mov		ecx,strtoff
	   		 sub		eax,ecx
			.286
			 mov		dx,0				 
			 mov		cx,[bx].vwidth
			 div		cx
			 ;    ax = lines
;            lines = min(lines, height);
			 cmp		ax,rctheight
			 jl			mbbk2
			 mov		ax,rctheight
mbbk2:
;            height -= lines;
			cmp		ax,0
			jbe		spanline
			 mov		cx,ax
			 mov		ax,rctheight
			 sub		ax,cx
			 mov		rctheight,ax
				; cx has lines
;            for (i = 0; i < lines; i++)
				push		es
				mov			ax,0a000h
				mov			es,ax
mbfllp1:
				push		cx
				mov			di,word ptr strtoff
				mov			cx,rctwidth
				mov			dx,0
				mov			ax,currRow
				call		rectFunc
				pop			cx
;                offset += modeInfo.width;
				add			di,[bx].vwidth
				mov			word ptr strtoff,di
				inc			currRow
				loop		mbfllp1
				pop			es
;            }
;            //
;            // handle the case where a scan line crosses
;            // a page boundry
;            //
spanline:
				mov		ax,rctheight
				cmp		ax,0
				jb		span1

				dec		ax
				mov		rctheight,ax
;                start = 0x10000L - offset;
			 .386
			 	mov		eax,10000h
			 	mov		ecx,strtoff
				sub		eax,ecx
				mov		startoff,eax
			  .286
;                if (start >= width)
				cmp		ax,rctwidth
				jb		othbk
;                {
;                    memset((uint8 *) MK_FP(0xa000, (uint16) offset),
;                          color,
;                           width);
			  
				push		cx
				push		es
				mov			dx,0a000h
				mov			es,dx
				mov			dx,0
				mov			ax,currRow
				mov			di,word ptr strtoff
				mov			cx,rctwidth
				call		rectFunc
				pop			es
				pop			cx
			  
;                    currentBank++;
;                    vbeSetBankAAddr(currentBank);
				mov		dx,[bx].currentBank
				inc		dx
				push	bx
				mov		[bx].currentBank,dx
				mov		ax,dx
				mov		bx,0				     
				call	vbeSetBankAddr
				pop		bx
				jmp		span1

;                }
othbk:
;                else
;                {
;                    memset((uint8 *) MK_FP(0xa000, (uint16) offset),
;                           color,
;                           start);
;    

				
				push		cx
				push		es
				mov			dx,0a000h
				mov			es,dx
				mov			dx,0
				mov			ax,currRow
				mov			di,word ptr strtoff
				mov			cx,word ptr startoff
				call		rectFunc

				pop			es
				pop			cx
			  
;                    currentBank++;
;                    vbeSetBankAAddr(currentBank);
				mov		dx,[bx].currentBank
				inc		dx
				push	bx
				mov		[bx].currentBank,dx
				mov		ax,dx
				mov		bx,0				     
				call	vbeSetBankAddr
				pop		bx
;
;                    memset((uint8 *) MK_FP(0xa000, (uint16) 0),
;                           color,
;                           width - start);
				push		cx
				push		es
				mov			dx,0a000h
				mov			es,dx
				mov			di,0
				mov			cx,rctwidth
				mov			dx,word ptr startoff
				sub			cx,dx
				mov			ax,currRow
				call		rectFunc
				
				pop			es
				pop			cx
				

;                }
;            }
span1:
			 mov		cx,rctheight
;            offset += modeInfo.width;
;            offset &= 0xffffL;
			 mov		ax,word ptr strtoff
			 add		ax,[bx].vwidth
			 mov		word ptr strtoff,ax
			 inc		currRow
			 jmp	   mltbklp
;        }
;    }
rectdone:

		pop		es
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		ret

 

;*****************************************************************************
;   getNumPages - 
;       inputs: BX -> VDCONTX struct
;		output: number of pages - 
;*****************************************************************************
getNumPages:
	push	bx
	assume bx:ptr VDCONTX
	
	lea		bx,[bx].vmi
	assume bx:ptr MODEINFO
	mov		ah,0
	mov		al,[bx].numberofimagepages
	inc		ax
	pop		bx
	ret

_Text ENDS
	END	
