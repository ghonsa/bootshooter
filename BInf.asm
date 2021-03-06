;***********************************************************
;  BInd - BootInfo checks a systems hard drives and collects
;       information about bootable partitions. To be used as 
;       a test working toward a functional boot loader
;		Built as a com object (Tiny) easily converted to disk
;       boot image
; 
;  Copyright, 2005 Greg Honsa
;***********************************************************
include pte.inc
include DispUtl.inc

extrn DriveInfoCollect:near
extrn DriveInfoDisplay:near
extrn displayDI:NEAR
extrn ShowSector:near
extrn ZapDrive:near
extrn ZapPartition:near
extrn  lastByte:near
extrn BootPartition:near
extrn CreatePartition:near
extrn dinf:near

_Text SEGMENT PUBLIC USE16					  
  assume CS:_Text, DS:_Text
.286
IFDEF BOOTABLE 	  ; change to 1 for a bootable image
;
; -- if bootable, only the first 512 bytes gets read in!
;    this code here fits in the first 512 bytes and will read 
;    in the rest of the code... 
;
  org 0
public start
start:
  db 0EAh  					;jmp far SEG:OFS    ;Currently we are at 0:7C00
  dw OFFSET Begin, 7C0h    	;This makes us be at 7C0:0
;
; --- small data strings ---
;
bootdrive	db	?
bmessg 		db "reading booter code",0ah,0dh,0
bemessg 	db "* ERROR* reading booter",0
;
; --- resume at 7c0:Begin
;
Begin: 
  	push 	cs	   			; set all segmens the same...
 	pop 	ds     			; 
 	push	cs
	pop		es
;
;--- find out where we are booting from
;
	mov		bootdrive,dl
; assume floppy 0 now
;
;   read in the rest of the booter
;
	mov	si,offset bmessg
	call	println1

	mov	bx,200h
	mov	dh,00h
	mov	dl,bootdrive
	mov	ax,offset lastByte
	shr ax,9
	inc	al
	mov ah,2
   	mov	cx,02

	int 13h
	jnc	ok
	; -- something went wrong -- 
	mov	si,offset bemessg
	call	println1
	jmp	getout

ok:
	jmp	cont


 getout:
	int 18h

;**********************************************************
;  println ds:si -> null terminated string
;
;**********************************************************
println1:
	push	ax
	push	ds
	push	si
	mov	ah,0eh
charloop1:
	lodsb
	or	al,al
	jz	chardone1
	int	10h
	jmp	charloop1
chardone1:
 	pop	si
	pop	ds
	pop	ax
	ret

org 510    ; Make the file 512 bytes long
  dw 0AA55h  ; Add the boot signature

org 200h
cont:
ELSE
	org 0100h		
start:
;-- set all segments to the same value ---

	push	cs
	pop		ds
	push	cs
	pop		es

ENDIF
;
; --- The Real Start!!! ---
;
;
; -- say hello --
;

	call	init_vid
	
 	call	DriveInfoCollect

	call 	DriveInfoDisplay


;	mov		si,offset sCommands
;	call	println
;
;   --- command loop ---
;
public cmdloop
cmdloop:
		call	init_command

		mov		al,'>'
		call	printChar
		mov		bx,offset LineBuff
		mov		cx,80
		call 	getLine				; getLine bx-> buffer cx->buffsz
		jc		cerror
		mov		si,bx				; returns num characters in cx

		lodsb						; get the command
		cmp		al,'b'			  	; valid commands:
		jz		bootcmd			  	; b -Boot,drv,partition  ex:b,0,1 
		cmp		al,'B'			  	; sb = show boot devices
		jz		bootcmd			  	; sd,drv = show drive info drv=drive
									; ss,drv,lba 	
		cmp		al,'s'	
		jz		showcmd				; 
		cmp		al,'S'	
		jz		showcmd

		cmp		al,'Z'				; Zap command
		jz 		ZapCmd
		cmp		al,'z'
		jz		ZapCmd

		cmp		al,'C'				; Zap command
		jz 		CreateCmd
		cmp		al,'c'
		jz		CreateCmd
		
		cmp		al,'?'
		jz		shcmds

		cmp		al,'q'
		jz		quitcmd
		cmp		al,'Q'
		jnz		cerror
quitcmd:
		call	kill_vid
		ret
shcmds:
		;mov		si,offset sCommands
		;call	println
		jmp		cmdloop
cerror:	
		mov		si,offset sWhat
		call	println
	
		jmp		cmdloop
;
;  --- Boot command  "b drive partition" ---
;
bootdriveid	db	0
bootpart	db	0
bootcmd:

		lodsb					; get next byte , should be white space
		cmp		al,' '
		jz		bok1
		jmp		cerror		
bok1:		

		call	GetNextParam	; 1st param is drive id 
		or		bx,bx			;
		jz		cerror		
		push	si
		mov		si,bx	
		call	ascii2hex		; convert from ascii
		pop		si	
.386
		or		edx,edx			; check value in range
.286
		jnz		cerror
.386
		cmp		eax,90h
.286
		jg		cerror
		mov		bootdriveid,al	; save boot id

		call	GetNextParam	; next parameter is the partition to boot
		or		bx,bx
		jz		cerror		
		push	si
		mov		si,bx	
		call	ascii2hex
		pop		si	
.386
		or		edx,edx			 ; check for in range
.286																							
		jnz		cerror
.386
		cmp		eax,4
.286
		jg		cerror
		mov		bootpart,al

;
;   --- display the boot command
;
		push	si
		mov		si,offset sLF
		call	println
		mov		si,offset sBootCmd
		call	println
		pop		si
		mov		al, bootdriveid
		call	printHexByte
		mov		al,','
		call	printChar
		mov		al, bootpart
		call	printHexByte
 
		mov		si,offset sLF
		call	println

;
;   --- here we should call load the boot sector and launch it
;
		; we need to get LBA from the partition info for the drive
		mov		ah,al
		mov		al,bootdriveid

		call	BootPartition		


		jmp		cmdloop
;
;   --- Show commands ---
;
;	ss - show sector , drive, LBA sector #
;	sd - show drive info , drive 
;					
showcmd:
		;push	si
		;mov		si,offset sLF
		;call	println
		;mov		si,offset sShowCmd
		;call	println
		;pop		si

		lodsb				; get next byte what to show

		cmp		al,'d'		; show drive info
		jz		showDI
		cmp		al,'D'
		jz		showDI

		cmp		al,'s'		; show sector
		jz		showSect
		cmp		al,'S'
		jz		showSect
		jmp		cerror
;
;    --- show DriveInfo	1 parameter drive id
;
driveid	db	0
showDI:

		lodsb		; get next byte , should be white space
		cmp		al,' '
		jz		sDIok1
		jmp		cerror		

sDIok1:	

		call	GetNextParam
		or		bx,bx
		jz		cerror		
		push	si
		mov		si,bx	
		call	ascii2hex		; convert from ascii
		pop		si	
.386
		or		edx,edx			; check value in range
.286
		jnz		cerror
.386
		cmp		eax,90h
.286
		jg		cerror
		mov		driveid,al	; save boot id
;
;		set the active window to drives...
;		
		push	ax
		mov		ax,offset gwDrives
		mov		word ptr activewindow,ax
		pop		ax
		call 	displayDI 
;	
		jmp		cmdloop
	

;
;	--- show Sector 2 parameters drive id, LBA of sector---
;
sectl	dd	0			; lba of sectot
secth	dd	0

showSect:
		call	init_sector
		lodsb		; get next byte , should be white space
		cmp		al,' '
		jz		ssok1
		jmp		cerror		
ssok1:		

		call	GetNextParam
		or		bx,bx
		jz		cerror		
		push	si
		mov		si,bx	
		call	ascii2hex		; convert from ascii
		pop		si	
.386
		or		edx,edx			; check value in range
.286
		jnz		cerror
.386
		cmp		eax,90h
.286
		jg		cerror
		or		al,80h			; hack convert
		mov		driveid,al	; save boot id
;
;   --- get the LBA
;
		call	GetNextParam
		or		bx,bx
		jz		cerror	
		push	si
		mov		si,bx	
		call	ascii2hex
		pop		si	
.386
		mov		sectl,eax		;save off the LBA
		mov		secth,edx
.286
;
;    --- we have the info, display the sector...
;			
		call	showZero
		mov		cl,driveid
		call	ShowSector
		jmp		cmdloop
;
;   --- Create commands
;   CP Create Partition, drive, size, type  ex: CP 0 10000 10 
;
cpDrvId	db	?
cpSize	dd	?
CreateCmd:
		push	si
		mov		si,offset sLF
		call	println
		mov		si,offset sCreateCmd
		call	println
		pop		si
		lodsb				; get next byte what to show

		cmp		al,'p'		; Zap drive info
		jz		CreatePart
		cmp		al,'P'
		jnz		cerror
CreatePart:
		lodsb					; get next byte , should be white space
		cmp		al,' '
		jz		cpok1
		jmp		cerror		
cpok1:		

		call	GetNextParam	; 1st param is drive id 
		or		bx,bx			;
		jz		cerror		
		push	si
		mov		si,bx	
		call	ascii2hex		; convert from ascii
		pop		si	
.386
		or		edx,edx			; check value in range
.286
		jnz		cerror
.386
		cmp		eax,90h
.286
		jg		cerror
		mov		cpDrvId,al		; save disk id

		call	GetNextParam	; next parameter is the partition size
		or		bx,bx
		jz		cerror		
		push	si
		mov		si,bx	
		call	ascii2hex		; convert from ascii
		pop		si
		.386	
		mov		cpSize,eax
		.286		
		call	GetNextParam	; next parameter is the partition size
		or		bx,bx
		jz		cerror		
		push	si
		mov		si,bx	
		call	ascii2hex		; convert from ascii
		pop		si	
		mov		bx,ax

		mov		di,offset dinf
		mov		ax,SIZEOF DriveInfo
		mul		cpDrvId
		add		di,ax
		.386
		mov		edx,cpSize
		.286

		call	CreatePartition						

;
;  --- ZAP commands ---
;
;	ZD Zap Drive	 ex: ZD 0
;   ZP Zap Partition ex: ZP 0 1
ZapCmd:
		push	si
		mov		si,offset sLF
		call	println
		mov		si,offset sZapCmd
		call	println
		pop		si

		lodsb				; get next byte what to show

		cmp		al,'d'		; Zap drive info
		jz		zapDrv
		cmp		al,'D'
		jz		zapDrv

		cmp		al,'p'		; Zap Partition
		jz		zapPart
		cmp		al,'P'
		jz		zapPart
		jmp		cerror


ZapDriveid		db	0
ZapPartitionid	db	0
public zapDrv
zapDrv:
		lodsb					; get next byte , should be white space
		cmp		al,' '
		jz		zdok1
		jmp		cerror		
zdok1:		

		call	GetNextParam	; 1st param is drive id 
		or		bx,bx			;
		jz		cerror		
		push	si
		mov		si,bx	
		call	ascii2hex		; convert from ascii
		pop		si	
.386
		or		edx,edx			; check value in range
.286
		jnz		cerror
.386
		cmp		eax,90h
.286
		jg		cerror
		mov		ZapDriveid,al	; save boot id
		mov		cl,al

		mov		si, offset sDrv
		call	println
		call	printHexNibble
		mov		si,offset sConfirm
		call	println
		mov		bx,offset LineBuff
		mov		cx,80
		call 	getLine				; getLine bx-> buffer cx->buffsz
		mov		si,offset sLF
		call	println
		mov		si,bx				; returns num characters in cx

		lodsb						; get the command
		cmp		al,'y'			  	; valid commands:
		jz		zpdrv			  	; b -Boot,drv,partition  ex:b,0,1 
		cmp		al,'Y'			  	; sb = show boot devices
		jnz		nodzap			  	; sd,drv = show drive info drv=drive

zpdrv:
		mov		cl,ZapDriveid
		call	ZapDrive
nodzap:
		jmp		cmdloop

zapPart:
		lodsb					; get next byte , should be white space
		cmp		al,' '
		jz		zok1
		jmp		cerror		
zok1:		

		call	GetNextParam	; 1st param is drive id 
		or		bx,bx			;
		jz		cerror		
		push	si
		mov		si,bx	
		call	ascii2hex		; convert from ascii
		pop		si	
.386
		or		edx,edx			; check value in range
.286
		jnz		cerror
.386
		cmp		eax,90h
.286
		jg		cerror
		mov		ZapDriveid,al	; save boot id

		call	GetNextParam	; next parameter is the partition to boot
		or		bx,bx
		jz		cerror		
		push	si
		mov		si,bx	
		call	ascii2hex
		pop		si	
.386
		or		edx,edx			 ; check for in range
.286																							
		jnz		cerror
.386
		cmp		eax,4
.286
		jg		cerror
		mov		ZapPartitionid,al


;
; -- DATA AREA ---
;

;rs1		dd	0
;rs2		dd	0

LineBuff	db	80	dup (0) 
rsltbuffl	dd	 0
rsltbuffh	dd	0
sConfirm	db	" Are you sure? y/n",0
sBootCmd	db	"Boot Cmd:",0
sShowCmd	db	"ShowCmd:",0
sZapCmd		db	"Zap ",0
sCreateCmd  db  "Create Partition ",0
sSect		db	"Sector ",0
sDrv		db	"Drive ",0
sPartition  db	"Partition ",0
sLF			db 0ah,0dh,0

sStartMsg 	db 	"Collecting boot device parameters",0ah,0dh,0
sWhat		db	"?",0dh,0ah,0
sCommands	db	0dh,0ah
			db	"Command Set: 'sd 0'      = Show Drive idx = drive index ",0dh,0ah
			db	"             'ss 0 123 ' = Show Sector idx= drive id lsector number",0dh,0ah
			db	"             'b 0 0'     = Boot partition drive index partition indx",0dh,0ah
			db  "             'cp 0 23 6' = Create Partition drive,size,type",0dh,0ah
			db	"             'zd 0'      = Zap Drive idx=drive index",0dh,0ah
			db  "             'zp 0 1'    = Zap Partition idx=drive index, partition index",0dh,0ah
			db  "             '?'         = show command set",0dh,0ah,0
 _Text ENDS
  END  start
