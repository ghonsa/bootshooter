;***********************************************************
;  DispUtl - DisplY UTILITIES
;        
;  Copyright, 2005 Greg Honsa
;***********************************************************
 include pte.inc
 include video.inc
 include vgutl.inc
 include vcontex.inc
  
_Text SEGMENT PUBLIC USE16
  assume CS:_Text, DS:_Text

public printChar
public printHexNibble
public printHexByte
public printHexDWord
public printHexWord
public println
public print_size
public showZero
public init_vid

.286
 extrn	 VCCreate:near					   
hellos		db	"Boot Shooter",0dh,0ah,0

public vidcontext 
vidcontext	dw	0

public desktop
public gwDrives
public gwSector
public gwCommand

desktop	GWIND	<>
gwDrives	GWIND <>
gwCommand	GWIND <>
gwSector	GWIND <>
gbCreatePart GWIND <>
gbBoot GWIND <>
gbQuit GWIND <>
gbView GWIND <>
gbZap GWIND <>


public	activeWindow
activeWindow dw ?


gwtest2	GWIND	<>



sCommands	db	0dh,0ah
			db	" 'sd 0'      = Show Drive - drive  ",0dh,0ah
			db	" 'ss 0 123 ' = Show Sector - drive, lsector",0dh,0ah
			db	" 'b 0 0'     = Boot partition - drive partition",0dh,0ah
			db  " 'cp 0 23 6' = Create Partition - drive,size,type",0dh,0ah
			db	" 'dp 0 1'    = Delete Partition - drive, partition",0dh,0ah
			db	" 'zd 0'      = Zap Drive - drive",0dh,0ah
			db  " 'zp 0 1'    = Zap Partition - drive , partition ",0

activepage	dw	1
lbuff	db 4 dup (?)

;*****************************************************************************
;
; ini_vid
;
;*****************************************************************************

init_vid:
	push	es
	mov		ax,105h
;
;   --- creae a video context for our request mode ---
;
	push	es
	call	VCCreate  ; returns VDCONTX ptr in bx
	pop		es

	or		bx,bx
	jz		novid
	mov		vidcontext,bx
;
;	--- Mode is set, set in a palette --- 
;
	assume bx:ptr VDCONTX
   	;call	 setPalette332

	mov		ax,activepage
	inc		ax
	mov		activepage,ax
	call	[bx].setActivePage

 	mov		ax,7
	call	[bx].clear

	mov		si,offset desktop

	assume si:ptr GWIND
	mov		[si].xorg,3
	mov		[si].yorg,3
	mov		ax,[bx].vwidth
	sub		ax,3
	mov		[si].xsiz,ax
	mov		ax,[bx].vheight
	sub		ax,8
	mov		[si].ysiz,ax
	mov		[si].bcolor,1
	mov		[si].ccolor,14
	call	[bx].createWindow
	mov		word ptr activeWindow,si

	mov		ax,14
	mov		cx,[bx].maxx
	shr		cx,1
	sub		cx,70
	mov		dx,24
	mov		di,1
	mov		si,offset hellos
	call 	[bx].drawString

	mov		ax,14
	mov		cx,40
	mov		dx,[bx].maxy
	sub		dx,232
	mov		di,1
	mov		si,offset sCommands
	call 	[bx].drawString
;
;   make some buttons ...
;
; create partition button
	mov		si,offset gbCreatePart

	assume si:ptr GWIND
	mov		ax,20
	mov		[si].xorg,ax
	add		ax,15
	mov		[si].currx,ax

	mov		ax,[bx].maxy
	sub		ax,50
	mov		[si].yorg,ax
	add		ax,5
	mov		[si].curry,ax
	mov		ax,100
	mov		[si].xsiz,ax
	mov		ax,24
	mov		[si].ysiz,ax
	mov		[si].bcolor,1
	mov		[si].ccolor,14
	mov		word ptr activeWindow,si

	call	[bx].createButton
	mov		cx,0
	mov		dx,0
	mov		si,offset creats
 	call 	[bx].drawString
;	
;  --- boot button
;
	mov		si,offset gbBoot

	assume si:ptr GWIND
	mov		ax,150
	mov		[si].xorg,ax
	add		ax,15
	mov		[si].currx,ax

	mov		ax,[bx].maxy
	sub		ax,50
	mov		[si].yorg,ax
	add		ax,5
	mov		[si].curry,ax

	mov		ax,100
	mov		[si].xsiz,ax
	mov		ax,24
	mov		[si].ysiz,ax
	mov		[si].bcolor,1
	mov		[si].ccolor,14
	mov		word ptr activeWindow,si

	call	[bx].createButton
	mov		cx,0
	mov		dx,0
	mov		si,offset boots
	call 	[bx].drawString
;
;	--- quit button 
;

	mov		si,offset gbQuit

	assume si:ptr GWIND
	mov		ax,280
	mov		[si].xorg,ax
	add		ax,15
	mov		[si].currx,ax

	mov		ax,[bx].maxy
	sub		ax,50
	mov		[si].yorg,ax
	add		ax,5
	mov		[si].curry,ax

	mov		ax,100
	mov		[si].xsiz,ax
	mov		ax,24
	mov		[si].ysiz,ax
	mov		[si].bcolor,1
	mov		[si].ccolor,14
	mov		word ptr activeWindow,si

	call	[bx].createButton
	mov		cx,0
	mov		dx,0
	mov		si,offset quits
	call 	[bx].drawString
;
;   --- view button
;
	mov		si,offset gbView

	assume si:ptr GWIND
	mov		ax,410
	mov		[si].xorg,ax
	add		ax,15
	mov		[si].currx,ax

	mov		ax,[bx].maxy
	sub		ax,50
	mov		[si].yorg,ax
	add		ax,5
	mov		[si].curry,ax

	mov		ax,100
	mov		[si].xsiz,ax
	mov		ax,24
	mov		[si].ysiz,ax
	mov		[si].bcolor,1
	mov		[si].ccolor,14
	mov		word ptr activeWindow,si

	call	[bx].createButton
	mov		cx,0
	mov		dx,0
	mov		si,offset views
	call 	[bx].drawString

;
;   --- zap button
;
	mov		si,offset gbZap

	assume si:ptr GWIND
	mov		ax,540
	mov		[si].xorg,ax
	add		ax,15
	mov		[si].currx,ax

	mov		ax,[bx].maxy
	sub		ax,50
	mov		[si].yorg,ax
	add		ax,5
	mov		[si].curry,ax

	mov		ax,100
	mov		[si].xsiz,ax
	mov		ax,24
	mov		[si].ysiz,ax
	mov		[si].bcolor,1
	mov		[si].ccolor,14
	mov		word ptr activeWindow,si

	call	[bx].createButton
	mov		cx,0
	mov		dx,0
	mov		si,offset zaps
	call 	[bx].drawString
;
;  --- turn mouse on ...
;
	mov	ah,0c2h
	mov	al,0
	mov	bh,1
	int 15h


novid:
	pop		es
	ret
creats db "Create",0
boots  db "Boot ",0
quits	db "Quit",0
views	db "View",0
zaps	db	"Zap",0
;*****************************************************************************
;  kill_vid
;
;
;
;*****************************************************************************

public kill_vid
kill_vid:
	push	bx
	mov		bx,vidcontext
	assume bx:ptr VDCONTX

	call	[bx].Destroy
	pop		bx
	ret



;*****************************************************************************
; init_command
;
;
;*****************************************************************************
public init_command
init_command:
		push	ax
		push	bx
		push	si

		mov		bx,word ptr vidcontext	
		assume  bx:ptr VDCONTX

		mov		si,offset gwCommand
		assume  si:ptr GWIND
		
		mov		[si].xorg,20
		mov		ax,[bx].maxy
		sub		ax,100
		mov		[si].yorg,ax
		add		ax,5
		mov		[si].curry,ax
		mov		ax,[bx].maxx
		sub		ax,40
		mov		[si].xsiz,ax
		mov		[si].ysiz,40
		mov		[si].bcolor,80
		mov		[si].ccolor,0
		mov		[si].currx,25

		call	[bx].createWindow
		mov		word ptr activeWindow,si

		pop		si
		pop		bx
		pop		ax
		ret




;*****************************************************************************
; init_sector
;
;
;*****************************************************************************
public init_sector
init_sector:
		push	ax
		push	bx
		push	si

		mov		bx,word ptr vidcontext	
		assume  bx:ptr VDCONTX

		mov		si,offset gwSector
		assume  si:ptr GWIND
		mov		ax,[bx].vwidth
		shr		ax,1
		sub		ax,30
			
		mov		[si].xorg,ax
		add		ax,4
		mov		[si].currx,ax

		mov		ax,[bx].vwidth
		shr		ax,1
		sub		ax,20
		mov		[si].xsiz,ax
		
		mov		[si].yorg,60
	
		mov		[si].curry,65
		mov		[si].ysiz,520

		mov		[si].bcolor,80
		mov		[si].ccolor,0

		call	[bx].createWindow
		mov		word ptr activeWindow,si

		pop		si
		pop		bx
		pop		ax
		ret

;*****************************************************************************
;   setPalette332 - Create a video pallet
;       
;		output: nothing - returns video back to origional mode
;*****************************************************************************

setPalette332:
	push	ax
   	push	bx
	push	cx
	push	di
	mov		bx,vidcontext
	assume bx:ptr VDCONTX

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
assume di:nothing
showZero:
	push	cx
	mov		cl,0h
	mov		bSkipZero,cl
	pop		cx
	ret

;**********************************************************
;  printChar al = char
;
;**********************************************************
 printChar:
 	push	ax
	push	bx

 	mov		bx,vidcontext
	assume bx:ptr VDCONTX
	or		bx,bx
	jz		bioschar
	
	push	cx
	push	dx
	push	di
	
	mov		cx,0
	mov		dx,cx
	mov		ah,1
	mov		di,80
	call	[bx].drawChar
	
	pop		di
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	ret

bioschar:
 	mov		ah,0eh
	int		10h
	pop		bx
	pop		ax
	ret
assume bx:nothing
;**********************************************************
; printHexNibble al contains vale
;
printHexNibble:
	push	ax
	and		al,0fh
	cmp		al,9
	jg		alphab
	or		al,al
	jnz		showval
	cmp		bSkipZero,55h
	jz		phnout
showval:
	mov		bSkipZero,0
	add		al,30h
	call	printChar
	jmp		phnout
alphab:
	mov		bSkipZero,0
	add		al,37h
	call	printChar
phnout:
	pop	ax
	ret
;**********************************************************
; printHexByte al contains byte
;
printHexByte:
	push	bx
	mov		bx,ax
	shr		al,4
	call	printHexNibble
	mov		al,bl
	call	printHexNibble
	pop		bx
	ret
	
	
printHexWord:
	push	bx
	push	ax
	shr		ax,8
	call	printHexByte
	pop		ax
	call	printHexByte
	pop		bx
	ret

printHexDWord:
	push	bx
.386
	push	eax
	shr		eax,16
.286
	call	printHexWord
.386
	pop		eax
.286
	call	printHexWord
	pop		bx
	ret

;**********************************************************
;  println ds:si -> null terminated string
;
;**********************************************************
println:
	push	ax
	push	ds
	push	si
	push	cx
	push	dx
	mov		cx,0
	mov		dx,0
charloop:
	lodsb
	or		al,al
	jz		chardone
	call	printChar
	jmp		charloop
chardone:
	pop	dx
	pop	cx
 	pop	si
	pop	ds
	pop	ax
	ret

;******************************************************************************
;  print_size EAX = value cx = number of digits
;
; 	simple loop starts to divide the value by 1,000,000,000	, prints the result 
; , divides the divison by 10 and loops back to work the remainder.
;******************************************************************************
print_size:

	cli
.386
	push	eax
	
	push	edx
	push	ebx
;.286
	push 	cx
	push	di
	;mov		cx,10
	mov		di, offset sNumBuff
;.386
	xor		ebx,ebx
	mov		ebx,1000000000
ps_loop:
	xor		edx,edx
	div	   	ebx				   	; divide by power of 10
	or		eax,eax
	jnz		not0			   	; check for leading "0"
	cmp 	di,	offset sNumBuff
	jz		skip0

not0:							
	add		al,30h				; convert to ascii ( simple numeric conversion)
	mov		[di],al				; save ascii in buffer
	inc 	di
skip0:
.386
	push	edx					; hold on to the remainder while we move down to
	mov		edx,0				; the next power of 10
	mov		eax,ebx
	mov		ebx,10
	div		ebx
	mov		ebx,eax
	pop		eax
	cmp		ebx,0
;.286	
	loopne	ps_loop
								; all done add the null terminator
	mov		cl,0
	mov		[di],cl
	mov		si,offset sNumBuff	; and display the number
	sti
	call	println
	 
	pop		di
	pop		cx
;.386
	pop		ebx
	pop		edx
	pop		eax
.286	
	ret

;******************************************************************************
;*  display buffer es:si -> buffer
;*
;*
;******************************************************************************
public displayBuffer
displayBuffer:
		push	ax
		push	cx
		push	bx
		push	es
		;//push	si
		mov		bl,16
nextline:
		mov		cx,16
		push	si
dbloop:
		lodsb

		call  	printHexByte				
		mov		al,' '
		call	printChar
		loop	dbloop
		pop		si
		mov		al,' '
		call	printChar
		mov		al,' '
		call	printChar
		mov		al,' '
		call	printChar
		mov		al,' '
		call	printChar
		
		mov		cx,16
dbloop1:
		lodsb
		cmp		al,20h
		jnb		cok1
		mov		al,'.'
		jmp		cok2
cok1:
		cmp		al,7fh
		jb		cok2
		mov		al,'.'
cok2:				
		call  	printChar				
		loop	dbloop1
		mov		al,0dh
		call	printChar
		mov		al,0ah
		call	printChar
		
		dec		bl
		jnz		nextline

		;//pop	si
		pop	es
		pop	bx
		pop	cx
		pop	ax
		ret

public	bSkipZero

bSkipZero		db	0				; flag used to skip leading 0's

sNumBuff	db 16 dup (0)
public GetChar

GetChar:
		mov		ah,0			; Get key entry
		int		16h
		ret
;******************************************************************************
;*  GetLine - loops reading the keyboard until a cr is entered
;*			returns si > line bufer, cx=count
;*
;******************************************************************************
sgline	db	"GetLine",0dh,0ah,0
public GetLine
GetLine:
		push	ax
		push	di
		push	dx
		push	bx

		mov		di,bx
		xor		bx,bx
		mov		dx,bx
					 
next_char:
		mov		ah,0			; Get key entry
		int		16h
		cmp		al,0dh			; check end of line
		jz		line_done
		cmp		al,8			; check delete
		jz		del_char
		cmp		al,7fh
		jge		bad_char			; check out of range
		cmp		al,20h
		jb		bad_char
		
		inc		dx
		cmp		dx,cx
		jl		ok_char
		dec		cx
		jmp		bad_char	  
ok_char:
		stosb					; store it
		call	printChar
		jmp		next_char

bad_char:
		jmp		next_char

del_char:

		jmp		next_char
line_done:
		mov		al,0
		stosb	
		
		pop		bx
		pop		dx	
		pop		di
		pop		ax
		ret

;******************************************************************************
;*  ascii2hex - 
;*                  si -> input buffer
;*			returns EDX:EAX = value
;*
;******************************************************************************
rsltbuffl	dd	 0
rsltbuffh	dd	0
public ascii2hex

ascii2hex:			; si-> ascii string returns hex value
		cli
.386
		push	ebx
		xor		eax,eax
		mov		rsltbuffl,eax
		mov		rsltbuffh,eax
.286
		call	getStringSize	; returns size in cx
convloop:
		push	cx				; save size while we get the div
		dec		cx
.386		
		
		mov		eax,1
.286
		or		cx,cx
		jz		mloopdone
.386					
dlp:
		mov		ebx,10			; get the multipler
		mul		ebx
.286
		loop	dlp
mloopdone:
		pop		cx
.386		
		push	edx
		push	eax						; edx:eax has multiplier		

		xor		eax,eax
		mov		edx,eax

.286
		lodsb
		sub		al,30h				; convert the character
		cmp		al,9
		jle		vok
;
.386
		pop		edx					; bail out if not a number
		pop		eax
		xor		eax,eax
		xor		edx,edx
		pop		ebx
.286
		sti
		ret

vok:
.386			
		mov		ebx,eax
		pop		eax
		push	eax				; edx:eax=multiplier, also still on stack
		mul		ebx
								; edx:eax has value, add it to base value
		adc		rsltbuffl,eax
		jnc		sk1
		inc		rsltbuffh
sk1:
		add		rsltbuffh,edx	; result is saved
		
		pop		eax
		pop		edx				; edx:eax = multiplier,adjust multiplier
		loop	convloop
		mov		eax,rsltbuffl
		mov		edx,rsltbuffh
		pop		ebx
.286
		sti
		ret



getStringSize:		;returns string size in cx
		push	ax
		push	si
		mov		cx,0
ssnext:
		lodsb
		or	al,al
		jz		gssdone
		inc		cx
		jmp	ssnext

gssdone:
		pop		si
		pop		ax
		ret 
;******************************************************************************
;*  GetNextPAram - loops reading the string until a white space is found
;*                  si -> input buffer
;*			returns si-> remainder of line bufer, bx = pointer to parameter
;*
;******************************************************************************
public GetNextParam
GetNextParam:
		push	di
		push	ax
		mov		di,offset paramBuff

		lodsb			; get first character
		or		al,al
		jnz		gnpLoop
		mov		bx,0
		pop		ax
		pop		di

		ret
gnpLoop:	
		or		al,al
		jz 		gnpdone
		cmp		al,','
		jz 		gnpdone
		cmp		al,' '
		jz 		gnpdone

		stosb
		lodsb
		jmp	gnpLoop
gnpdone:
	   	mov		al,0
		stosb
		mov		bx,offset paramBuff
		pop		ax
		pop		di
		ret	
;
; -- DATA AREA ---
;
paramBuff 	db  80 dup (0)

_Text ENDS
  END 
