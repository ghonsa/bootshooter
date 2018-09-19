;*****************************************************************************
;  DrvInf - Disk Info checks a systems hard drives and collects
;       information about bootable partitions. ; 
;  Copyright, 2005 Greg Honsa
;*****************************************************************************
 include pte.inc
 include DispUtl.inc
 include partiton.inc
 include diskbuff.inc

public DriveInfoDisplay
public DriveInfoCollect  
										   
extrn ReadSectExt:near
extrn ReadSectStd:near
extrn WriteSectExt:near
extrn WriteSectStd:near


_Text SEGMENT PUBLIC USE16
  assume CS:_Text, DS:_Text
;
;  --- we have room for 4 drives ---						  
;
public dinf
dinf		DriveInfo 	<>	;8 dup (<>)  
			DriveInfo	<>
			DriveInfo	<>
			DriveInfo	<>
			DriveInfo	<>
			DriveInfo	<>
			DriveInfo	<>
			DriveInfo	<>
bdt 		BiosDrvTab <?>
ebdt		ExtBiosDrvTab <?>

sBext 		db 	"Bios has int 13h extensions",0dh,0ah,0   
berr1msg 	db "* ERROR* getting drive parameters",0
emessg 		db "* ERROR* reading sector",0
sFree		db "Free ",0
sTot		db "Total ",0
sHead		db " H:",0
sSector		db " S:",0
sCylinder	db "C:",0
sDrive		db "Drive ",0
sLF			db 0ah,0dh,0
sBootable		db "    Bootable ",0
snonBootable	db "    Non Boot ",0
sRel		db " LBA:",0
public sSpace
sSpace		db	"    ",0


							                                                                            
numdrv		db	?
BiosExt		db	0
idx			db	0
;*****************************************************************************
; --- collect the data ---
;
;*****************************************************************************

DriveInfoCollect:			; no input, ax has status
		push	bx			;
		push	cx
		push	dx
		push	si
		push	di
;
; --- get Drive info for # of drivess ---
;
		mov		di,offset bdt					; int 13h function 8 returns number of drives
		mov		ah,08h							; and a table of drive parameters
		mov		dl,80h
		int		13h
		jc		ok2
		mov		numdrv,dl						; dl has number of drives

		mov		idx,0
		mov		cl,numdrv
		mov		ch,0
		mov		dl,80h
;
; ---  Loop here for each drive
;
DriveLoop:
		push	cx
		push	dx

		xor 	cx,cx
		mov		cl,idx
		mov		bx,offset dinf
		mov		ax,SIZEOF DriveInfo
		mul		cx
		add		bx,ax
  		pop		dx
  		push	dx 
	assume 	bx:ptr DriveInfo				; 
		push	bx								; save pointer to drive info
		mov		[bx].DIExtend,0
	
;
; -- check for bios extenstions --
;
		mov		ah,41h							; Bios int 13H function 41h						
		mov		bx,55aah						;
		int		13h
		jc 		no_extensions
		cmp		bx,0aa55h						; restore drive info pointer
		jnz		no_extensions
		pop		bx
		push	bx
;
; -- bios has extensions --
;
		mov		BiosExt,1						; set has extensions
		mov		[bx].DIExtend,DIEXTENDED

;
; -- Get Extended drive table hard drive 0 ---
;
   										; drive should be in dl
		mov		si,offset ebdt				; table to retreve the total size...
	assume si:ptr  ExtBiosDrvTab
		mov		ax,	SIZEOF ExtBiosDrvTab	; set the size
		mov		[si].EBDTBuffSz,ax
		mov		ax,4800h					; Bios int 13h function 48h
		int		13h
		jnc		diok1
		pop		bx
		jmp		err1
;
; --- copy the info we want into our structure
;
diok1:
	assume 	bx:ptr DriveInfo				; 
		mov		[bx].DIExtend,DIEXTENDED
		mov		si,offset ebdt
		;mov		al,idx
		mov		[bx].DIid,dl
	assume si:ptr  ExtBiosDrvTab
.386
		mov		edx,[si].EBDTTotSect1
		mov		eax,[si].EBDTTotSect
		mov		[bx].DIExtSize1,edx
		mov		[bx].DIExtSize,eax
		mov		[bx].DITotSect,eax
		mov		[bx].DIFreeSect,eax
.286
no_extensions:
		pop		bx
;
; --- get Drive info for the drive 
;
		pop		dx						; retrieve the drive id
		push	dx
		mov		dh,0
		mov		di,offset bdt			; int 13h function 8 returns number of drives
		mov		ah,08h					; and a table of drive parameters
		int		13h
		jc		err1

;
; -- Save the BIOS logical driveparameters ---
;
	assume 	bx:ptr DriveInfo				; 

		mov		di,bx						; save DriveIfo ptr
	assume 	di:ptr DriveInfo				; 

		mov		[bx].DIHeads,dh				; int 13-8 returns the head in DH, the 
		mov		ax,cx						; number of drives in DL, sector in the 
		and	 	ax,3fh						; low 6 bits of CL, high order 2 bits
		mov		[bx].DISectors,al			; of cylinders in CL, and the low 
		mov		ax,cx						; cylinder in CH
		mov		cl,6
		shr		ax,cl
		mov		[bx].DICylinders,ax
;
;  --- read the partition table for the drive ---
;
		pop		dx
		push	dx
;
;  --- std bios int 13 will always work for the MBR ---
;		
		mov		dh,0
		mov		bx,offset dskbuffer
   		mov		cx,01
	  	mov 	ax,201h
		int		13h
		jnc		ok1

		; -- something went wrong -- 
		mov		si,offset emessg
		call	println
		jmp		err1
ok1:
		mov		bx,offset pte0
		call	parsePTable
;
;   --- adjust free space based upon partitions ---
;		 DI -> DriveInfo

		mov		ax,di
		add		ax,(sizeof DriveInfo - (4 * sizeof PARTITION_INFO))
		mov		bx,ax 
	assume bx:ptr PARTITION_INFO
.386
		mov		eax,[di].DIFreeSect
		mov		cx,4
public szloop
szloop:
		sub		eax,[bx].PIpte.bte_totalsector
		add 	bx,sizeof PARTITION_INFO
		loop	szloop
		mov		[di].DIFreeSect,eax
.286
 		
 		inc		idx
		pop		dx
		inc		dx
		pop		cx
		loop 	DriveLoop1

		jmp		ok2
DriveLoop1:
		jmp		DriveLoop
err1:
		pop		dx			
		pop		cx
		mov		ax,-1
.286
ok2:
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
	   	ret
;******************************************************************************
;*    ShowSector - cl has drve id EDX:EAX has LBA
;*				 
;*				 
;*
;******************************************************************************

PUBLIC	ShowSector
ShowSector:				; cl has drve id EDX:EAX has LBA
		push	cx
		push	di
		push	si
		push	cs
		pop		es

		mov		di,offset dskbuffer1
		call	ReadSectExt

		mov		si,offset dskbuffer1
		mov		cx,2
ssloop:
		call	displayBuffer
		;call	GetChar
		loop	ssloop
		pop		si
		pop		di
		pop	cx
		ret
;*****************************************************************************
;
; --- display the data ---
;
;*****************************************************************************
DriveInfoDisplay:
	   	push	bx			;
		push	cx
		push	dx
		push	si
		push	di
;
;   --- calculate the window size ---
;
		mov		cl,numdrv
		mov		al,(6*16)
		mul		cl

		mov		si,offset gwDrives
		assume  si:ptr GWIND
		
		mov		[si].xorg,20
		mov		[si].yorg,60
		mov		[si].xsiz,400
		mov		[si].ysiz,ax
		mov		[si].bcolor,80
		mov		[si].ccolor,0
		mov		[si].currx,25
		mov		[si].curry,65

		mov		bx,word ptr vidcontext
		assume bx:ptr VDCONTX
		call	[bx].createWindow
		mov		word ptr activeWindow,si

		test	BiosExt,1
		jz		noext1
		mov		dx,0
		mov		cx,0
		mov	si,offset sBext					; Has extensions message
		call	println
noext1:
		mov	idx,0
		mov	cl,numdrv
		mov	ch,0
		

DispLoop:
		push	cx
		xor		cx,cx
		mov		bx,offset dinf
		mov		ax,SIZEOF DriveInfo
		mov		cl,idx
		mul		cx
		add		bx,ax
		call 	dispDI
		inc	idx
		pop	cx
		loop DispLoop


		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
	   	ret
;*****************************************************************************
;
; --- display the Drive info --- al index of drive
;
;*****************************************************************************

public displayDI

displayDI:						; called with drive id in al
		push	cx
		push	bx
		push	ax
		xor		cx,cx
		mov		cl,al

		mov		bx,offset dinf
		mov		ax,SIZEOF DriveInfo
		mul		cx
		add		bx,ax
		assume 	bx:ptr DriveInfo				; 
		call	dispDI

		pop		ax
		pop		bx
		pop		cx
		ret

;*****************************************************************************
;
; --- display the Drive info --- bx-> drive info
;
;*****************************************************************************

dispDI:
		push	cx
		assume 	bx:ptr DriveInfo				; 
	  .386
		xor		eax,eax
	  .286
		mov		si,offset sDrive			; String "Drive"
		call	println						
		mov		al,':'
		call 	printChar					; 
	   	xor		ax,ax
		mov		al,[bx].DIid
		call	printHexByte
	

		mov		al,' '	
		call 	printChar

	 	jmp		skipdetails

		mov		si,offset sLF				
		call	println

		mov		si,offset sCylinder			; Cylinder
		call	println
		mov		ax,[bx].DICylinders

		mov		cx,10
		call	print_size
		mov		al,' '	
		call 	printChar

		mov		si,offset sHead				; Head
		call	println
		xor		ax,ax
		mov		al,[bx].DIHeads
		mov		cx,19
		call	print_size
		mov		al,' '	
		call 	printChar


		mov		si,offset sSector			; Sector
		call	println
		xor		ax,ax
		mov		al,[bx].DISectors
		mov		cx,10
	   	call	print_size
		mov		al,' '	
		call 	printChar
skipdetails:
		
		test	BiosExt,1
		jz		noext2
		mov		si,offset sToT
		call	println

;		mov		si,offset sSector
;		call	println
;.386
;		mov		eax,[bx].DIExtSize
;.286
;		mov		cx,10
;		call	print_size
;		mov		al,' '
;		call	printChar
;
;   --- show total size ---
;
.386
		push	edx
		push	ecx
		mov		ecx,512
		mov		eax,[bx].DIExtSize
		mul		ecx
		mov		ecx,1000000
		div		ecx
		pop		ecx
		pop		edx
.286
		mov		cx,10
		call	print_size
		mov		al,'M'
		call	printChar
		mov		al,'b'
		call	printChar
		mov		al,' '
		call	printChar
		mov		al,' '
		call	printChar
;
;   --- show free space ---
;
		mov		si,offset sFree
		call	println

.386
		push	edx
		push	ecx
		mov		ecx,512
		mov		eax,[bx].DIFreeSect
		mul		ecx
		mov		ecx,1000000
		div		ecx
		pop		ecx
		pop		edx
.286
		mov		cx,10
		call	print_size
		mov		al,'M'
		call	printChar
		mov		al,'b'
		call	printChar


								  
noext2:
		mov		si,offset sLF
		call	println

; --- loop through the partitions and display 
		
		mov		ax,bx
		add		ax,(sizeof DriveInfo - (4 * sizeof PARTITION_INFO))
		mov		bx,ax 
	assume bx:ptr PARTITION_INFO
		
		mov		cx,4
ptdisploop:
;
;  --- check if defined , ie. size !=0
;
	.386
		xor		eax,eax
		mov		eax,[bx].PIpte.bte_relativesector
		or		eax,eax
	.286
		jz		nextpart

; 
; --- adjust pointers and loop through all 4 partitions
;
		mov	 si,offset sBootable
;
; -- check bootable --
;
		cmp		[bx].PIbootable,PTE_BOOTABLE
		jz		isbootable
		mov	 	si,offset snonBootable;
public 	isbootable
isbootable:
		call	println
		push	dx
		mov		dx,0
		call	DisplayPTable
		pop		dx
		mov		al,[bx].PIExtended
		cmp		al,PTE_EXTENDED
		jnz		nextpart
		
		push	cx
		push	bx
		push	ax
		mov		cx,4
	 	mov		ax,(sizeof PARTITION_INFO - ((sizeof	EXT_PARTITION)*4))	
		add 	bx,ax
exploop:
		assume	bx:ptr EXT_PARTITION
	.386
		xor		eax,eax
		mov		eax,[bx].EPpte.bte_relativesector
		or		eax,eax
	.286
		jz		extpskip
		push	si
		mov		si,offset sSpace
		call	println
		mov		si,offset sSpace
		call	println
		pop		si

		;push	dx
		;mov		dx,1
		;call	DisplayPTable
		;pop		dx
extpskip:	
		add		bx,sizeof EXT_PARTITION
		loop	exploop
		pop		ax
		pop		bx
		pop		cx
nextpart:
		add 	bx,sizeof PARTITION_INFO
		loop 	ptdisploop

		pop		cx
		ret
;*****************************************************************************
;*
;*		BootPartition al=driveid ah=partition
;*		
;*
;*****************************************************************************

public BootPartition
BootPartition:
		push	di
		push	cx
		push	bx
		push	ax
		xor		cx,cx
		mov		cl,al

		mov		bx,offset dinf
		mov		ax,SIZEOF DriveInfo
		mul		cx
		add		bx,ax
		mov		cl,ah
		assume 	bx:ptr DriveInfo; 
		pop		ax			;ah has partition index, move to cx
		push	ax	   	 
		xchg	ah,al
		xor		ah,ah
		mov		cl,sizeof PARTITION_INFO
		mul		cl
		mov		di,ax
		mov		si,offset snotboot

		mov		al,[bx].DIPartTab1[di].PIbootable
		cmp		al,PTE_BOOTABLE
		jnz		no_boot
		mov		cl,[bx].DIPartTab1[di].PIDrive
		
.386
		mov		eax,[bx].DIPartTab1[di].PIStartLBA 
		mov		edx,0 
.286
IFDEF BOOTABLE 	 
extrn	start:near
 
		mov		di,offset start
ELSE
		mov		di,offset dskbuffer1
ENDIF
		call	ReadSectExt
		jnc		do_boot
		mov		si,offset srdError
		jmp		no_boot
public do_boot
do_boot:
IFDEF BOOTABLE 	  
		mov		dl,cl
	  	db 0EAh  					;jmp far SEG:OFS    ;Currently we are at 0:7C00
  		dw OFFSET 7c00h, 0h    	;This makes us be at 7C0:0
ELSE
		pop	di
		pop	cx
		pop	bx
		pop	ax
		ret
ENDIF
snotboot	db	"Non bootable partition",0dh,0ah,0
srdError	db	"Error reading boot sector",0dh,0ah,0
no_boot:
		call	println
		
	  	pop		ax
		pop		ax
		pop		cx
		pop		di
		ret
	
_Text ENDS
	END	



