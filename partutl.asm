;*****************************************************************************
;  Partutl
;  Copyright, 2005 Greg Honsa
;*****************************************************************************
 include pte.inc
 include diskbuff.inc
 include DispUtl.inc
 include error.inc

_Text SEGMENT PUBLIC USE16
  assume CS:_Text, DS:_Text
										   
extrn ReadSectExt:near
extrn WriteSectExt:near
extrn VerfSectExt:near
extrn LBA2CHS:near

public PTFindFree
.386
;*****************************************************************************
;   PTFindFree - find free partition table entry in DriveInfo struct
;       inputs: DI -> DriveInfo
;		output: BX -> free PARTITION_INFO struct
;		`		   =  NULL if no free entries
;*****************************************************************************

PTFindFree:
		push	eax
		push	cx
		mov		cx,4
		mov		ax,di
		add		ax,(sizeof DriveInfo - (4 * sizeof PARTITION_INFO))
		mov		bx,ax 
	assume BX:ptr PARTITION_INFO
cploop1:
		mov		eax,[bx].PIpte.bte_totalsector
		or		eax,eax
		jz		partspace
		add 	bx,sizeof PARTITION_INFO
		loop	cploop1
		mov		bx,0
partspace:
		pop		cx
		pop		eax
		ret
;*****************************************************************************
;   PTGetUsedT -  Sort the partition tables by starting addr
;	   input: DI ->DriveInfo containing 
;	   output:SI ->List of in use partitions 
;
;*****************************************************************************
public PTGetUsed
tmptab	dw	5 dup (0)						; tmp table used while we sort the
											; existing partitions by start adr.
PTGetUsed:
 		push	di			; 
		push	cx
		push	eax

		mov		si,di
		add		si,(sizeof DriveInfo - (4 * sizeof PARTITION_INFO))
	  assume si:ptr PARTITION_INFO
		mov		cx,4
		mov		di,offset tmptab
ckptblp:
	
		mov		eax,[si].PIpte.bte_totalsector
		or		eax,eax			; skip if also free
		jz		skus
;      -- si -> a valid partition table entry
		mov		word ptr[di],si
		inc		di
		inc		di
skus:
		add		si,sizeof PARTITION_INFO
		loop	ckptblp
		mov		si,offset tmptab
		pop		eax
		pop		cx
		pop		di
		ret
		
;*****************************************************************************
; sortpTabs  Sorts table of Partition tables by start LBA
;     input: SI -> array of pointers to PARTITION_TABLE_ENTRY's
;	  output: nothing, table sorted...	 
;
;*****************************************************************************
public PTSort

PTSort:
		push	di
		push	bx
		push	eax
		push	cx
		push	si

sortptablp0:
		pop		si
		push	si
		mov		cx,0
		assume si:ptr word
		mov		bx,[si]
		or		bx,bx
		jz		sortpTabsDone	; if the table s empty on start then exit
		add		si,2			; next elenemt
sortptablp1:
		mov		di,[si]			;  get pointer
		or		di,di			; if 0 end of list
		jz		sptabl1pdone

		assume di:ptr PARTITION_INFO
		mov		eax,[bx].PIStartLBA	; previous element
		cmp		eax,[di].PIStartLBA	; curent element
		jb		sptnoswap
		;						swap elements
		mov		[si],di
		mov		[si-2],bx
		mov		cx,55h			; set swapped flag
sptnoswap:
		mov		bx,si
		add		si,2
		jmp		sortptablp1
sptabl1pdone:
		or		cl,cl
		jnz		sortptablp0
sortpTabsDone:
		pop		si
		pop		cx
		pop		eax
		pop		bx
		pop		di
		ret
;*****************************************************************************
; GetStartLBA  di-> DriveInfo
;              si-> sorted pointers to ptabs
;			  edx size needed
;
;   returns: eax = Starting LBA
;
;*****************************************************************************
public PTGetStartLBA
PTGetStartLBA:
		push	si
		push	di
		;
		; special case for lowest check if room below
		; 		
		mov		di,[si]			; get lowset partition
		add		si,2		
	  assume di:ptr PARTITION_INFO
		mov		eax,[di].PIStartLBA
		cmp		eax,90
		jl		nxt
		sub		eax,edx
		jl		nxt
		dec		eax		; for fun
		;eax has starting lba
		jmp		found_space

nxt:	; here di ->current ptable, si->next ptable ptr
		;
		; --- now we look for space between partitions if any...
		;
		mov		eax,[di].PIEndLBA
		mov		di,[si]
		or		di,di
		jz		ckend
		sub		eax,[di].PIStartLBA		; see if space between partitions
		sub		eax,2					; leave 1 sector buffer on each side 
		cmp		eax,edx
		jg		gotit
		add		si,2
		jmp		nxt
ckend:
		;   check if we have space a end of drive
		;
		sub		si,2		; get back last one
		mov		di,[si]
		mov		eax,[di].PIEndLBA

		pop		si
		push	si			; get driveinfo
	assume si:ptr DriveInfo
		inc		eax
		push	eax
		add		eax,edx
	
		cmp		eax,[si].DITotSect
		pop		eax
		jg		noroom
		mov		eax,[di].PIEndLBA
		inc		eax
		jmp		found_space
gotit:
		; get back endlba from previous entry
		sub		si,2
		mov		eax,[di].PIEndLBA
		inc		eax
		jmp		found_space
noroom:
		xor		eax,eax

found_space:
		pop		di
		pop		si
		ret
 
;*****************************************************************************
; PTVerify
;		inputs: eax has starting lba
;               edx has size
;       		di ->DriveInfo
;		output:	returns carry if error
;*****************************************************************************
public PTVerify
PTVerify:
	   assume di:ptr DriveInfo
		push	eax
		push	edx			; save origional size
vsloop:
		push	si
		mov		si,offset verifys
		call	println
		pop		si

		push	ax
		push	cx
		mov		cx,10
		call	print_size
		pop		cx
		mov		al,0dh
		call	PrintChar
		pop		ax

		push	edx
		mov		edx,0
		mov		cl,[di].DIid
		call	verfSectExt
		pop		edx
		
		jc		vfailed
		inc		eax
		dec		edx
		jg		vsloop	
	   	clc
vfailed:
		pop		edx
		pop		eax
		ret
verifys	db	"Verify sector ",0
;*****************************************************************************
;	PTUpdate
;	 input: eax has start lba
;		    edx has size
;		    bx has the partition table entry
;		    di-> DriveInfo
;			cx has type
;	 output: nothing, tables updated
;
;*****************************************************************************
public PTUpdate
PTUpdate:
		push	eax
		push	edx
		push	cx

		assume bx:ptr PARTITION_INFO
		;
		; --- set LBA start and size ---
		;
		mov		[bx].PIStartLBA,eax
		mov		[bx].PIpte.bte_relativesector,eax
		mov		[bx].PIpte.bte_totalsector,edx
		;
		; --- get starting CHS from LBA ---
		;
		push	edx
 		mov		edx,0
		
		push	bx
		mov		bx,di
		call	LBA2CHS
		pop		bx
		
		mov		[bx].PIpte.bte_starthead,dh
		shl		cx,6
		or		cl,dl
		mov		[bx].PIpte.bte_startsector,cx
		pop		edx
		
		;
		;  --- set end LBA info
		;

		add		eax,edx
		mov		[bx].PIEndLBA,eax
		;
		; --- get ending CHS from LBA ---
		;

		push	edx
		mov		edx,0
		
		push	bx
		mov		bx,di
		call	LBA2CHS
		pop		bx
		
		mov		[bx].PIpte.bte_endhead,dh
		shl		cx,6
		or		cl,dl
		mov		[bx].PIpte.bte_endsector,cx
		pop		edx
		;
		;  --- upate free info ---
		;
  	   	mov		eax,[di].DIFreeSect
		sub		eax,edx
		mov		[di].DIFreeSect,eax
		pop		cx			; get back type
		mov		[bx].PIpte.bte_system,cl
	
		pop		edx
		pop		eax
		ret

;*****************************************************************************
;   PTCommit - Commits partition tables to disk
;		input:	DI-> DriveInfo struct
;
;
;*****************************************************************************
public PTCommit
PTCommit:
		push	di
		push	si
		push	eax
		push	edx
		push	cx
	
		push	di
		mov		cl,[di].DIid
		xor		edx,edx
		mov		eax,0
		mov		di,offset dskbuffer
		call	ReadSectExt
		pop		di

		jc		CommitFailed
		;
		;  --- now copy our table entries into the real one
		;
		mov		ax,di
		add		ax,(sizeof DriveInfo - (4 * sizeof PARTITION_INFO))
		mov		si,ax 
	
	assume si:ptr PARTITION_INFO

		push	di
		mov		di,offset pte0
		mov		cx,4
wptloop:

; 
;   --- copy the table entres from our struct
;		
		push	si
		push	cx
		mov		cx,sizeof PARTITION_TABLE_ENTRY
	   	rep 	movsb
		pop		cx
		pop		si
		mov		ax,si
		add		ax,sizeof PARTITION_INFO
		mov		si,ax
		loop 	wptloop
		pop		di
		;
		;  --- and write the sector back ---
		;

		push	di
		mov		cl,[di].DIid
		xor		edx,edx
		mov		eax,0
		mov		di,offset dskbuffer
		call	WriteSectExt
		pop		di
		jc		CommitFailed
		clc
CommitFailed:
		pop		cx
		pop		edx
		pop		eax
		pop		si
		pop		di
		ret





_Text ENDS
	END	 
