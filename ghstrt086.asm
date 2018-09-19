;*****************************************************************************
;*
;*                            Open Watcom Project
;*
;*    Portions Copyright (c) 1983-2002 Sybase, Inc. All Rights Reserved.
;*
;*  ========================================================================
;*
;*    This file contains Original Code and/or Modifications of Original
;*    Code as defined in and that are subject to the Sybase Open Watcom
;*    Public License version 1.0 (the 'License'). You may not use this file
;*    except in compliance with the License. BY USING THIS FILE YOU AGREE TO
;*    ALL TERMS AND CONDITIONS OF THE LICENSE. A copy of the License is
;*    provided with the Original Code and Modifications, and is also
;*    available at www.sybase.com/developer/opensource.
;*
;*    The Original Code and all software distributed under the License are
;*    distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
;*    EXPRESS OR IMPLIED, AND SYBASE AND ALL CONTRIBUTORS HEREBY DISCLAIM
;*    ALL SUCH WARRANTIES, INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF
;*    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR
;*    NON-INFRINGEMENT. Please see the License for the specific language
;*    governing rights and limitations under the License.
;*
;*  ========================================================================
;*
;* Description:  C/C++ DOS 16-bit console startup code.
;*
;*****************************************************************************


;       This must be assembled using one of the following commands:
;               wasm cstrt086 -bt=DOS -ms -0r -d__TINY__
;               wasm cstrt086 -bt=DOS -ms -0r
;               wasm cstrt086 -bt=DOS -mm -0r
;               wasm cstrt086 -bt=DOS -mc -0r
;               wasm cstrt086 -bt=DOS -ml -0r
;               wasm cstrt086 -bt=DOS -mh -0r
;
include mdef.inc
.286p
        name    cstart

        assume  nothing

        extrn   __CMain                 : near
        extrn   main_                 : near
        extrn   __InitRtns              : near
        extrn   __FiniRtns              : near
        extrn   __fatal_runtime_error_  : near

        extrn   _edata                  : byte  ; end of DATA (start of BSS)
        extrn   _end                    : byte  ; end of BSS (start of STACK)

        extrn   "C",_curbrk             : word
        extrn   "C",_osmajor            : byte
        extrn   "C",_osminor            : byte
        extrn   __osmode                : byte

        extrn   __HShift                : byte
        extrn   "C",_STACKLOW           : word
        extrn   "C",_STACKTOP           : word
        extrn   "C",_cbyte              : word
        extrn   "C",_child              : word
        extrn   __no87                  : word
        extrn   __FPE_handler           : word
        extrn  ___FPE_handler           : word
        extrn   "C",_LpCmdLine          : word
        extrn   "C",_LpPgmName          : word
        extrn   __get_ovl_stack         : word
        extrn   __restore_ovl_stack     : word
        extrn   __close_ovl_file        : word
        extrn   __DOSseg__              : byte


        extrn   __stacksize             : word
 DGROUP group _TEXT,CONST,STRINGS,_DATA,DATA,XIB,XI,XIE,YIB,YI,YIE,_BSS

_TEXT   segment word public 'CODE'

         assume  ds:DGROUP

CONST   segment word public 'DATA'
CONST   ends

STRINGS segment word public 'DATA'
STRINGS ends

XIB     segment word public 'DATA'
XIB     ends
XI      segment word public 'DATA'
XI      ends
XIE     segment word public 'DATA'
XIE     ends

YIB     segment word public 'DATA'
YIB     ends
YI      segment word public 'DATA'
YI      ends
YIE     segment word public 'DATA'
YIE     ends

_DATA   segment word public 'DATA'



_DATA   ends

DATA    segment word public 'DATA'
DATA    ends

_BSS    segment word public 'BSS'
_BSS    ends

        assume  nothing
        public  _cstart_
 
        assume  cs:_TEXT

 org     000h
; org 100h
 _cstart_ proc near

 ;	jmp	  cont	

  db 0EAh                                       ;jmp far SEG:OFS    ;Currently we are at 0:7C00
  dw OFFSET around, 7C0h         ;This makes us be at 7C0:0

; miscellaneous code-segment messages
;
;
; --- small data strings ---
;
bootdrive       db      ?
bmessg          db "reading booter code",0ah,0dh,0
bemessg         db "* ERROR* reading booter",0
NoMemory        db      'Not enough memory',0dh,0ah,0

ConsoleName     db      'con',00h
sectors			db	0
around: 

;
; --- resume at 7c0:Begin
;
Begin: 
        push    cs                              ; set all segmens the same...
        pop     ds                      ; 
        push    cs
        pop             es
;
;--- find out where we are booting from
;
        mov             bootdrive,dl
; assume floppy 0 now
;
;   read in the rest of the booter
;
        mov     si,offset bmessg
        call    println1

        mov     bx,200h
        mov     dh,00h
        mov     dl,bootdrive
        mov     ax,offset DGROUP:_end
        shr 	ax,9
        inc     al
		mov		sectors,al
        mov 	ah,2
        mov     cx,02

        int 	13h
        jnc     okg
        ; -- something went wrong -- 
errorm:
        mov     si,offset bemessg
        call    println1
        jmp     getout

okg:
		cmp		al,sectors
		jnz		errorm
       
       
       
       
        jmp     cont


 getout:
        int 18h

;**********************************************************
;  println ds:si -> null terminated string
;
;**********************************************************
println1:
        push    ax
        push    ds
        push    si
        mov     ah,0eh
charloop1:
        lodsb
        or      al,al
        jz      chardone1
        int     10h
        jmp     charloop1
chardone1:
        pop     si
        pop     ds
        pop     ax
        ret

org 510    ; Make the file 512 bytes long
  dw 0AA55h  ; Add the boot signature



org 200h


cont:

        sti                             ; enable interrupts
        
        mov     cx,cs
        mov     es,cx                   ; point to data segment
        assume  es:DGROUP
        mov     byte ptr es:__osmode,0  ;  not protect-mode

        ;mov     ss,cx

        mov     bx,offset DGROUP:_end   ; get bottom of stack
        add     bx,0Fh                  ; ...
        and     bl,0F0h                 ; ...
        mov     es:_STACKLOW,bx ; ...
        mov     es:_psp,ds              ;***** save segment address of PSP

        mov     ax,4000h                ; force size of stack required
        cmp     ax,0800h                ; make sure stack size is at least
        jae     ss_ok                   ; 2048 bytes
        mov     ax,0800h                ; - set stack size to 2048 bytes
ss_ok:  add     bx,ax                   ; calc top address for stack
        add     bx,0Fh                  ; round up to paragraph boundary
        and     bl,0F0h                 ; ...
        mov     ss,cx                   ; set stack segment
        
		;mov		bx,fff0
        mov     sp,bx                   ; set sp relative to DGROUP
        
        mov     es:_STACKTOP,bx         ; set stack top

 
;
mem_setup:
;
         ; end of stack in data segment

        assume  ds:DGROUP
        mov     dx,cs
        mov     ds,dx
        mov     es,dx

        mov      bp,1   ; gch- pentium always have math co-p
        mov     __no87,bp               ; set state of "NO87" environment var
        mov     _STACKLOW,di            ; save low address of stack

        mov     cx,offset DGROUP:_end   ; end of _BSS segment (start of STACK)
        mov     di,offset DGROUP:_edata ; start of _BSS segment
        sub     cx,di                   ; calc # of bytes in _BSS segment
        mov     al,0                    ; zero the _BSS segment
        rep     stosb                   ; . . .

        mov     ax,offset __null_ovl_rtn; - set vectors to null rtn
        mov     __get_ovl_stack,ax      ; - ...
        mov     __get_ovl_stack+2,ax    ; - ...
        mov     __restore_ovl_stack,ax  ; - ...
        mov     __restore_ovl_stack+2,ax; - ...
        mov     __close_ovl_file,ax     ; - ...
        mov     __close_ovl_file+2,ax   ; - ...

 
        ; DON'T MODIFY BP FROM THIS POINT ON!
        mov     ax,offset __null_FPE_rtn; initialize floating-point exception
        mov     ___FPE_handler,ax       ; ... handler address
        mov     ___FPE_handler+2,cs     ; ...

        mov     ax,0ffh                 ; run no initalizers
        call    __InitRtns              ; call initializer routines
 

	    call    __CMain
       
_cstart_ endp

;       don't touch AL in __exit, it has the return code

__exit  proc near
        public  "C",__exit

        jmp     ok


        public  __do_exit_with_msg__

; input: DX:AX - far pointer to message to print
;        BX    - exit code

__do_exit_with_msg__:

ok:

               ; back to DOS
__exit  endp


;
;       set up addressability without segment relocations for emulator
;
public  __GETDS
__GETDS proc    near
        push    ax                      ; save ax

;       can't have segment fixups in the TINY memory model
        mov     ax,cs                   ; DS=CS

        mov     ds,ax                   ; load DS with appropriate value
        pop     ax                      ; restore ax
        ret                             ; return
__GETDS endp


__null_FPE_rtn proc far
        ret                             ; return
__null_FPE_rtn endp


__null_ovl_rtn proc far
        ret                             ; return
__null_ovl_rtn endp


_TEXT   ends

        end     _cstart_
