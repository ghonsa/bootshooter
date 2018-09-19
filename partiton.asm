
;*****************************************************************************
;  Partition
;  Copyright, 2005 Greg Honsa
;*****************************************************************************
 include pte.inc
 include diskbuff.inc
 include DispUtl.inc
 include error.inc
 include PartUtl.inc
_Text SEGMENT PUBLIC USE16
  assume CS:_Text, DS:_Text
										   
extrn ReadSectExt:near
extrn ReadSectStd:near
extrn WriteSectExt:near
extrn WriteSectStd:near
extrn VerfSectExt:near
extrn LBA2CHS:near
extrn sSpace:near
;*****************************************************************************
;
; --- CreatePartition ---  DI -> DriveInfo
;                          EDX = number of blocks
;							BX = type 
;    
;        returns ax =0 ok, else error code  tbd.   					
;*****************************************************************************
public CreatePartition
 .386
CreatePartition:
assume DI:ptr DriveInfo

		push	si
		push	ecx		;
   		push	bx		; save type
;
;   --- step 1 -- check if partition table has free entry ---
;
		call	PTFindFree
		or		bx,bx				; Null if no free entries
		jnz		partspace
		mov		ax,CPERR_TAB
		jmp		CPFailed
;
;   --- step 2 -- check if enough space left --- 
;
partspace: 
		cmp		edx,[di].DIFreeSect	; check DriveInfo for free space
		jl		gotspace			; enough?
		mov		ax, CPERR_SPACE
		jmp		CPFailed

;
;   --- step 3 -- select the starting sector ---
;
gotspace:
		call   PTGetUsed			; builds a list of used entries
	  assume si:ptr word 			; SI-> list
		call	PTsort			; sorts list SI-> list

		call	PTGetStartLBA			; Looks for space in based upon list
									; SI-> sorted list of partition entries
									; EDX has size DI->driveInfo
									; returns EAX starting lba 0 of none
		or		eax,eax
		jnz		cpChkDsk
		mov		ax,CPERR_CSPACE
		jmp		CPFailed
;
;   --- step 4 -- check disk integrity ---
;
cpChkDsk:
		; eax has starting lba
		; edx has size
		; di ->DriveInfo

		call	PTVerify
		jnc		cpVerified
		mov		ax,CPERR_VERIFY
		jmp		CPFailed
;
;   --- step 5 -- write partition table ---
;
cpVerified:
		
		; eax has start lba
		; edx has size
		; bx has the partition table entry to update
		; di-> DriveInfo
		; cx has type
		pop		cx					; get type from stack
		push	cx
		call 	PTUpdate	 		; updates DriveInfo
		call	PTCommit
		jnc		cpFormat
		mov		ax,CPERR_COMMIT
		jmp		CPFailed
;		
;   --- step 6 -- format partition based upon type
;
cpFormat:
		push	di
		push	edx
		push	eax
		mov		cl,[di].DIid
		mov		ax,0f6h
		mov		di,offset dskbuffer
		push	cx
		mov		cx,512
		rep stosb
		pop		cx
		pop		eax
		mov		di,offset dskbuffer
		mov		edx,0
		
		call	WriteSectExt
		
		pop		edx
		pop		di
		 
		mov		si,offset sComplete
		call	println

		mov		ax,0
		pop		bx
		pop		ecx
		pop		si
		ret		
;
;   --- error exit ---
;
CPFailed:
		mov		si,offset sFailed
		call	println

		pop		bx
		pop		ecx
		pop		si
		ret
sVerify	db	"Verifing disk",0
sFailed db	"FAILED! ",0
sComplete db "Complete ",0

;*****************************************************************************
;
; --- ParsePTable --- BX -> PARTITION_TABLE_ENTRY[4]
;                     DI -> DriveInfo
;   					we copy the tabe entres into our data structs If this 
;                       is an extended partition, we then look for another 
;                       partition table
;
;*****************************************************************************
public ParsePTable
ParsePTable:
   		
		push	cx
		push	si
		push	di
		push	dx

		mov		dx,di				; save pointer to Drive Info		

	assume di:ptr DriveInfo
	assume bx:ptr PARTITION_TABLE_ENTRY

;
;   --- set drive into struct
;
		mov		al,[di].DIid		; drive id
		push	bx
		mov		bx,0
		mov		cx,4
clll:
		mov		[di].DIPartTab1.PIDrive[bx],al
		add		bx,sizeof PARTITION_INFO
		loop	clll
		pop		bx
		
		mov		ax,di
		add		ax,(sizeof DriveInfo - (4 * sizeof PARTITION_INFO))
		mov		di,ax 
	
	assume di:ptr PARTITION_INFO

		mov		cx,4
ptloop:

; 
;   --- copy the table entres into our struct
;
		push	di
		push	cx
		mov		cx,sizeof PARTITION_TABLE_ENTRY
		mov		si,bx
	   	rep 	movsb
		pop		cx
		pop		di
;
;   --- check the boot bit in the PT
;
		; dx-> Drive Info struct
		; di-> PARTITION_INFO
		mov		al,[di].PIpte.bte_bootable
		mov		[di].PIbootable,al
.386
		mov		eax,[di].PIpte.bte_relativesector
		mov		[di].PIStartLBA,eax
		add		eax,[di].PIpte.bte_totalsector
		mov		[di].PIEndLBA,eax

.286
;
;   --- and read the starting sector and check for boot val
;
		call	CheckPartition		
; 
; --- adjust pointers and loop through all 4 partitions
;
		add 	bx,sizeof PARTITION_TABLE_ENTRY
		mov		ax,di

		add		ax,sizeof PARTITION_INFO
		mov		di,ax
		loop 	ptloop

		pop		dx
		pop		di
		pop		si
		pop		cx
		ret

;******************************************************************************
;*    CheckPartition - di-> PARTITION_INFO  dx-> DRIVE_INFO
;*		Looks at the info in the partition table. If it looks like a valid 
;*      the code will read the 1st sector of the partition and see if it is 
;*      bootable, also if the partition s an extended partition, the code
;*      then looks for a another partition table for the extension	 
;*
;******************************************************************************
	assume di:ptr PARTITION_INFO
	assume dx:ptr DriveInfo
public CheckPartition

CheckPartition:
		push	cx
		mov		cx,[di].PIpte.bte_endsector		; if endsector is 0 assume not valid
		or		cx,cx
		jnz		validPartition
		mov		cl,-1
		mov		[di].PIbootable,cl
		jmp		CPDone
;
;   --- partition is valid, read in the sector...
;
validPartition:

.386
;
;    --- extended or std bios read?
;
		push	bx
		mov		bx,dx
	assume bx:ptr DriveInfo
		cmp	[bx].DIExtend,DIEXTENDED
		pop		bx
		jz		cpExtRead	

;
;   --- setup standard bios regs ---
;		
		push	di	

		push	bx
		push	cx
		push	dx
 
		mov		dl,[di].PIDrive
		mov		dh,[di].PIpte.bte_starthead
		mov		ax,[di].PIpte.bte_startsector
		and 	al,0c0h					;MASK	Cylinder
		shr		al,6
		xchg	al,ah
		mov		bx,ax
		mov		ax,[di].PIpte.bte_startsector
		and		ax,MASK	Sector
		mov		cl,al
		mov		di,offset dskbuffer1
		call	ReadSectStd
		
		pop		dx
		pop		cx
		pop		bx
		jc		cpout
		jmp		cpChkSig
cpExtRead:
		push	di

		push	edx
		push	eax

		mov		edx,0
		mov		eax,[di].PIStartLBA				; Get the starting LBA 
.286
		mov		cl,[di].PIDrive					; drive id

		push	cs
		pop		es
		mov		di,offset dskbuffer1
		call	ReadSectExt						; and read the sector
.386
		pop		eax
		pop		edx
		jc		cpout
cpChkSig:

		mov		ax,ptsig
		cmp		ax,0AA55h
 		pop		di
		push	di
	assume di:ptr PARTITION_INFO
		jnz		ckext

		mov		al,PTE_BOOTABLE
		mov		[di].PIbootable,al
ckext:
;
; --- check if this is an extended partition
;
		mov	al,[di].PIpte.bte_system
		cmp	al,EXTEND
		jz	getsubparts
		cmp	al,BEXTEND
		jnz	cpout
getsubparts:
		mov		al,PTE_EXTENDED
		mov		[di].PIExtended,al
	
		call	getExtPart
;
;   --- all done ---
;
cpout:
		pop		di

.286
CPDone:
		pop		cx
		ret

;*****************************************************************************
; getExtPart   DI ->PartitionInfo struct
; 				 dskbuffer1 contains 1st sector of extended partition
;				 dx -> DriveInfo
;*****************************************************************************
public getExtPart
partbase	dd 0
getExtPart:
  assume di:ptr PARTITION_INFO
  assume dx:ptr DriveInfo
		
		push	si
		push	di
		push	cx
		push	bx
		push	ax
.386
		mov		eax,[di].PIStartLBA
		mov		partbase,eax
.286
;
;   --- adjust pointers ---
;
		mov		bl,[di].PIDrive		; get drive
	 	mov		ax,(sizeof PARTITION_INFO - ((sizeof	EXT_PARTITION)*4))	
		add 	di,ax

		assume  di:ptr EXT_PARTITION
		mov		si,offset pte10
		
;
;   --- we need to copy the partition tables into our structure
;
		
		mov	cx,4
extcpylp:
		mov		[di].EPDrive,bl
;
;   --- copy ptable ---
;
		push	cx
		push	di
		mov		cx,sizeof  PARTITION_TABLE_ENTRY
		rep movsb
		pop		di
		pop		cx

;
;  --- set other info in struct ---
;
		mov		al,[di].EPpte.bte_bootable
		mov		[di].EPbootable,al
.386
		mov		eax,[di].EPpte.bte_relativesector
		add		eax,partbase
		mov		[di].EPStartLBA,eax
		add		eax,[di].EPpte.bte_totalsector
;
;   --- read the sector and look for bootable sig ---
;
;    --- extended or std bios read?
;
		push	bx
		mov		bx,dx
	assume bx:ptr DriveInfo
		cmp		[bx].DIExtend,DIEXTENDED
		pop		bx
		jz		cxpExtRead	

;
;   --- setup standard bios regs ---
;		
		push	bx
		push	cx
		push	dx
 
		mov		dl,[di].EPDrive
		mov		dh,[di].EPpte.bte_starthead
		mov		ax,[di].EPpte.bte_startsector
		and 	al,0c0h					;MASK	Cylinder
		shr		al,6
		xchg	al,ah
		mov		bx,ax
		mov		ax,[di].EPpte.bte_startsector
		and		ax,MASK	Sector
		mov		cl,al

		push	di
		mov		di,offset dskbuffer2
		call	ReadSectStd
		pop		di

		pop		dx
		pop		cx
		pop		bx
		jc		getExtPartOut
		jmp		cxpChkSig
relay1:
		loop	extcpylp
		
cxpExtRead:

		push	cx
		mov		cl,[di].EPDrive
		push	di
		push	edx
		xor		edx,edx
		mov		di,offset dskbuffer2
		call	ReadSectExt
		pop		edx
		pop		di
		pop		cx

		jc		getExtPartOut
cxpChkSig:
		mov		ax,ptsig2
		cmp		ax,0AA55h
		jnz		GetNextExt

		mov		al,PTE_BOOTABLE
		mov		[di].EPbootable,al

GetNextExt:
		mov		ax,sizeof EXT_PARTITION
		add		di,ax
		jmp		relay1


getExtPartOut:
		pop		ax
		pop		bx
		pop		cx
		pop		di
		pop		si
		ret
;*****************************************************************************
; DisplayPTable - BX -> PARTITION_INFO or EXT_PARTITION which are the same
;				  for the elements we are displaying
;
;				  DX = tabs before display
;*****************************************************************************
public DisplayPTable
DisplayPTable:
	assume bx:ptr PARTITION_TABLE_ENTRY
		push	ax
		push	bx
		push	cx
		push	si

 
; -- check partition type --
		mov		di,offset TYPE_TAB
		mov		cx,TYPESZ
; -- loop through the type tablle looking for a match ---
ckptype:
		mov		al,[di]
		cmp		al,[bx].bte_system
		jz 		match
		inc 	di
		loop 	ckptype
		mov		si,offset sUnknown
		jmp		showtype
; -- we have a match, display it --
; -- using the count from the match loop 
; -- we get the string pointer from the string table

match:
		mov		ax,TYPESZ	 
		sub		ax,cx
		mov		cx,ax
		mov		ax,TYPE_STR_TAB
		shl		cx,1
		add		ax,cx
		;sub		ax,2
		mov		di,ax
		
		mov		si,word ptr [di]
showtype:		    
		call	println
; -- get the partition size --
.386
		push	edx
		push	ecx
		mov		ecx,512
		mov		eax,[bx].bte_totalsector
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

		;mov		si,offset sLF
		;call	println
		
		JMP		GTO
;
;    --- for display of extended we need to shift right
;
		or		dx,dx
		jz		skled
		mov		si,offset sSpace
		call	println
skled:
; -- get start head,sector and cylinder
		mov		si,offset sStart
		call	println
;-- Start Cylinder
		mov		si,offset sCylinder
		call	println
		mov		al ,'0'
		call	printChar
	
	.386
		xor		eax,eax
	.286

		mov		ax,[bx].bte_startsector
		and 	al,0c0h					;MASK	Cylinder
		shr		al,6
		xchg	al,ah
		mov		cx,10	
		call print_size

; --  Start head
		mov		si,offset sHead
		call	println
		mov		al ,'0'
		call	printChar

	.386
		xor		eax,eax
	.286
		mov		al,[bx].bte_starthead
		mov		cx,10
		call 	print_size
;-- start sector
		mov		si,offset sSector
		call	println
		mov		al ,'0'
		call	printChar
	.386
		xor		eax,eax
	.286

		mov		ax,[bx].bte_startsector
		and		ax,MASK	Sector
		mov		cx,10
		call 	print_size
; -- end
		mov		si,offset sEnd
		call	println

;-- end Cylinder
		mov		si,offset sCylinder
		call	println
		mov		al ,'0'
		call	printChar
	.386
		xor		eax,eax
	.286

		mov		ax,[bx].bte_endsector
		and 	al,0c0h					;MASK	Cylinder
		shr		al,6
		xchg	al,ah
		mov		cx,10
		call 	print_size

; -- end head ...
		mov		si,offset sHead
		call	println
		mov		al ,'0'
		call	printChar
	.386
		xor		eax,eax
	.286

		mov		al,[bx].bte_endhead
		mov		cx,10
		call 	print_size
;-- end sector
		mov		si,offset sSector
		call	println
		mov		al ,'0'
		call	printChar
	.386
		xor		eax,eax
	.286

		mov		ax,[bx].bte_endsector
		and		ax,MASK	Sector
		mov		cx,10
		call 	print_size
GTO:

; --- relative sector ---
	
		mov		si,offset sRel
		call	println
		

	.386
		assume bx:ptr PARTITION_INFO
		xor		eax,eax
		mov		eax,[bx].PIStartLBA
	.286
		mov		cx,10
		call 	print_size

		;mov		si,offset sLF
		;call	println
		mov		si,offset sLF
		call	println

		pop	si
		pop	cx
		pop	bx
		pop	ax
		ret

;***************************************************************
;
sRel		db " LBA:",0
sHead		db " H:",0
sSector		db " S:",0
sCylinder	db "C:",0
sEnd			db "  End ",0
sStart			db "        Start ",0
sLF			db 0ah,0dh,0

TYPESZ	EQU 21
TYPE_TAB:
	db	FAT12 	
	db	FAT16 	
	db	EXTEND  
	db	BGFAT16	
	db	NTFS	
	db	FAT32	
	db	BFAT32	
	db	BFAT16	
	db	BEXTEND 
	db	EISA	
	db	DYNVOL
	db  LINUXSW	
	db  LINUXRT
	db	POWMAN  
	db	MDFAT16	
	db	MDNTFS  
	db	HIB		
	db	DELL	
	db	IBM		
	db	GPT		
	db	EFI		

TYPE_STR_TAB:
	dw	offset sFAT12 
	dw	offset sFAT16 
	dw	offset sEXTEND
	dw	offset sBGFAT16
	dw	offset sNTFS	
	dw	offset sFAT32	
	dw	offset sBFAT32
	dw	offset sBFAT16
	dw	offset sBEXTEND
	dw	offset sEISA	
	dw	offset sDYNVOL
	dw  offset sLINUXSW
	dw  offset sLINUXRT
	dw	offset sPOWMAN
	dw	offset sMDFAT16
	dw	offset sMDNTFS
	dw	offset sHIB	
	dw	offset sDELL	
	dw	offset sIBM	
	dw	offset sGPT	
	dw	offset sEFI	

sFAT12   	db "FAT12 primary       ",0 
sFAT16   	db "FAT16 partition     ",0  
sEXTEND  	db "Extended partition  ",0  
sBGFAT16 	db "BIGDOS FAT16        ",0  
sNTFS	  	db "Installable (NTFS)  ",0 
sFAT32	  	db "FAT32 partition     ",0
sBFAT32  	db "FAT32 INT 13h exts  ",0
sBFAT16  	db "BIGDOS/FAT16/INT13x ",0
sBEXTEND 	db "Extended INT13 exts ",0
sEISA	  	db "EISA partition      ",0
sDYNVOL  	db "Dynamic volume      ",0
sPOWMAN  	db "Power management    ",0
sMDFAT16 	db "Multidisk FAT16 NT4 ",0
sMDNTFS  	db "Multidisk NTFS  NT4 ",0
sHIB	  	db "Laptop hibernation  ",0
sDELL	  	db "Dell OEM partition  ",0
sIBM	  	db "IBM OEM partition   ",0
sGPT	  	db "GPT partition       ",0
sEFI	  	db "EFI System          ",0
sLINUXSW  	db "Linux swap          ",0
sLINUXRT  	db "Linux native        ",0

sUnknown		db "Unknown ",0




_Text ENDS
	END	 
