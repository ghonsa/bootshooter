/*****************************************************************************
*  GVideo - video Bios routines
*
*       Copyright 2005 Greg Honsa
*
*
*****************************************************************************/
#define GVIDEO 1
#include "GVideo.h"
#include <i86.h>

int GetVBEInfo(VBEINFO * vbi)
{
        // bios int 10 function 4f-00
        union REGS reg;
        struct SREGS sreg;
        reg.x.ax = 0x4f00;
        sreg.es = FP_SEG(vbi);
        reg.x.di = FP_OFF(vbi);

        int86x(0x10, &reg, &reg, &sreg);
    return (reg.x.ax == 0x004f);
}


int GetVModeInfo(int16 mode, MODEINFO *infoPtr)
{
    union REGS reg;
    struct SREGS sreg;

    reg.x.ax = 0x4f01;
    reg.x.cx = mode;

    sreg.es = FP_SEG(infoPtr);
    reg.x.di = FP_OFF(infoPtr);

    int86x(0x10, &reg, &reg, &sreg);

    return (reg.x.ax == 0x004f);
}

int SetVMode(int16 mode)
{
    union REGS reg;
    struct SREGS sreg;

    reg.x.ax = 0x4f02;
    reg.x.bx = mode;

    int86x(0x10, &reg, &reg, &sreg);

    return (reg.x.ax == 0x004f);
}

int GetVMode(int16 *mode)
{
    union REGS reg;
    struct SREGS sreg;

    reg.x.ax = 0x4f03;

    int86x(0x10, &reg, &reg, &sreg);

    *mode = reg.x.bx;

    return (reg.x.ax == 0x004f);
}
int GetFont(uint16 * fwidth,uint16 * fseg, uint16 * foff)
{
   
   _asm
   {

		push	es
		push	bp

		mov		bx,100h
    	mov     ax, 1130h    ; Service to Get Pointer
    	int     10h                 ; Call VGA BIOS
		
		mov		ax,es
		mov		bx,bp
		pop		bp
		pop		es
	
		mov		di,fseg
		mov		[di],ax
		mov		di,foff
		mov		[di],bx
		mov		di,fwidth
		mov		[di],cx
   }
        
        return 0;
}
        
int SetVDisplayStart(uint16 pixel, uint16 line)
{
    union REGS reg;

    reg.x.ax = 0x4f07;
    reg.h.bh = 0x00;
    reg.h.bl = 0x00;

    reg.x.cx = pixel;
    reg.x.dx = line;

    int86(0x10, &reg, &reg);

    return (reg.x.ax == 0x004f);
}

int SetVBankAAddr(uint16 addr)
{
    union REGS reg;

    reg.x.ax = 0x4f05;
    reg.h.bh = 0x00;
    reg.h.bl = 0x00;
    reg.x.dx = addr;

    int86(0x10, &reg, &reg);

    return (reg.x.ax == 0x004f);
}

void  memset(uint16 pseg, uint16 poff,uint16 val, uint16 len)
{
	_asm
	{
		push	ax
		push	bx
		push	cx
		push	es
		push	di
		mov		bx,val
		mov		di,poff
		mov		cx,len
		mov		ax,pseg
		mov		es,ax

		mov		ax,bx
		rep stosb

		pop		di
		pop		es
		pop		cx											   
		pop		bx
		pop		ax
	}
}
