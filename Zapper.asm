;*****************************************************************************
;  Zapper - ; 
;  Copyright, 2005 Greg Honsa
;*****************************************************************************
 include pte.inc
 include DispUtl.inc
										   
extrn ReadSectExt:near
extrn ReadSectStd:near
extrn WriteSectExt:near
extrn WriteSectStd:near
extrn dskbuffer1:near
extrn dinf:near
_Text SEGMENT PUBLIC USE16
  assume CS:_Text, DS:_Text

;******************************************************************************
;*    ZapDrive - cl has drve id 
;*	   Wipes all data on drive and fills drive with 0			 
;*	   using either int 13-3 for older bioses or 13-43 for enhanced BIOSes			 
;*
;******************************************************************************
public ZapDrive
ZapDrive:
		push	di
		push	cx
		push	bx
		push	ax

		mov		di,offset dskbuffer1
		mov		al,0
		push	cx
		mov		cx,512
		rep stosb
		pop		cx
		mov	ch,0
;		
;   --- get pointer to drive info ---
;
		mov		bx,offset dinf
		mov		ax,SIZEOF DriveInfo
		mul		cx
		add		bx,ax
		assume 	bx:ptr DriveInfo	
;
;   --- see if drive has extensions
;		 
		cmp		[bx].DIExtend,DIEXTENDED
		jz		zapDExtend
;
;   --- no extensions, use older bios writes
;
		mov		cx,[bx].DICylinders		; for each cylinder						
		mov		zpCurCyl,0
zpcyllp:
		push	cx
		mov		cl,[bx].DIHeads			; for each head
		mov		ch,0
		mov		zpCurHead,0
zphdlp:
		push	cx
		mov		cl,[bx].DISectors		; for each sector
		mov		ch,0
		mov		zpCurSect,1
zpseclp:
		push	bx
		push	cx
		mov		dl,[bx].DIid			; get Drive id
		mov		dh,zpCurHead
		mov		bx,zpCurCyl
		mov		cl,zpCurSect
		call 	WriteSectStd
		inc		zpCurSect		
		pop		cx
		pop		bx
		loop	zpseclp					; next Sector

		inc		zpCurHead
		pop		cx
		loop	zphdlp					; next head

		inc		zpCurCyl
		pop		cx
		loop	zpcyllp					; next Cylinder
		jmp		zapdrvdone



zapDExtend:
		assume 	bx:ptr DriveInfo		;from above
.386		
		mov		zpCurLbaH,0
		mov		zpCurLbal,0
zpextlp:		
.286
		mov		di,offset dskbuffer1
		mov		cl,[bx].DIid
.386
		mov		eax,zpCurLbaL
		mov		edx,zpCurLbaH
		mov		si,offset sZapping
		call	println
		push	cx
		mov		cx,10
		call	print_size
		pop		cx
		mov		si,offset sOf
		call 	println

.286
		call	WriteSectExt
		jc		zaperror
.386
		mov		eax,[bx].DIExtSize
.286
		push	cx
		mov		cx,10
		call	print_size
		pop		cx
		mov		al,0dh
		call	PrintChar
.386
		mov		eax,zpCurLbaL
		inc		eax
.286
		jnc		z1
.386
		inc		zpCurLbah
z1:
		mov		zpCurLbaL,eax
		cmp		[bx].DIExtSize,eax
		jl		zpextlp
		cmp		[bx].DIExtSize1,edx
		jge		zpextlp
		jmp		zapdrvdone
		
zaperror:

zapdrvdone:
		pop		ax
		pop		bx
		pop		cx
		pop		di
		ret


;******************************************************************************
;*    ZapPartition - cl has drve id ch has partition indx
;*	   Wipes all data on drive and fills partition with 0			 
;*	   using either int 13-3 for older bioses or 13-43 for enhanced BIOSes			 
;*
;******************************************************************************
public ZapPartition
ZapPartition:
		push	cx
		push	bx
		push	ax
;
;   --- get pointer to drive info ---
;
		mov		ch,0
		mov		bx,offset dinf
		mov		ax,SIZEOF DriveInfo
		mul		cx
		add		bx,ax

		assume 	bx:ptr DriveInfo
		
		mov		al,ch
		xor		ah,ah
		mov		cl,sizeof PARTITION_INFO
		mul		cl
		mov		di,ax
		assume  di:ptr PARTITION_INFO 
;
;   --- see if drive has extensions
;		 
		cmp		[bx].DIExtend,DIEXTENDED
		jz		zapPExtend
;
;   --- no extensions, use older bios writes
;
		jmp		zapprtdone	; not ready!!!!!!!!!

;
;  need to get starting cylinder head sector
;
;  and compare to ending cylinder head sector
;
;
	.286
zppcyllp:
		push	cx
		mov		cl,[di].PIpte.bte_endhead			; for each head
		mov		ch,0
		mov		al,[di].PIpte.bte_starthead
		mov		zpCurHead,al
zpphdlp:
		push	cx
		mov		cl,[bx].DISectors		; for each sector
		mov		ch,0
		mov		zpCurSect,1
zppseclp:
		push	bx
		push	cx
		mov		dl,[bx].DIid			; get Drive id
		mov		dh,zpCurHead
		mov		bx,zpCurCyl
		mov		cl,zpCurSect
		call WriteSectStd
		inc		zpCurSect		
		pop		cx
		pop		bx
		loop	zppseclp					; next Sector

		inc		zpCurHead
		pop		cx
		loop	zpphdlp					; next head

		inc		zpCurCyl
		pop		cx
		loop	zppcyllp					; next Cylinder
		jmp		zapprtdone



zapPExtend:
		assume 	bx:ptr DriveInfo		;from above
		assume  di:ptr PARTITION_INFO 
.386		
		mov		eax,[di].PIpte.bte_relativesector
		mov		zpCurLbaL,eax
		mov		zpCurLbaH,0
zppextlp:		
.286
		push	di
		mov		di,offset dskbuffer1
		mov		cl,[bx].DIid
.386
		mov		edx,zpCurLbaH
		mov		eax,zpCurLbaL
.286
		call	WriteSectExt
		pop		di
		jc		zaperror
.386
		mov		eax,zpCurLbaL
		inc		eax
.286
		jnc		z1
.386
		inc		zpCurLbah
zp1:
		mov		zpCurLbaL,eax
		;cmp		[di].DIExtSize,edx
		;jl		zpextlp
		cmp		[di].PIpte.bte_totalsector,eax
		jl		zpextlp
		jmp		zapprtdone
		
zapperror:

zapprtdone:
		pop		ax
		pop		bx
		pop		cx
		ret

zpCurLbaL	dd	0
zpCurLbaH	dd	0
zpCurHead	db	0
zpCurSect	db	0
zpCurCyl	dw	0

sZapping	db	"Zapping sector ",0
sOf			db	" of ",0

_Text ENDS
	END	
