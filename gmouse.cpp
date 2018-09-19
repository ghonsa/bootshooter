/*****************************************************************************
*  GMouse
*
*       Copyright 2005 Greg Honsa
*
*
*****************************************************************************/
#include "GVC.H"	;
#include <stdio.h>
#include "GMouse.h";
#include <dos.h>
#include <I86.H>
#include "DeskTop.h"


//extern void txtout(char * txt);
//extern void hexout(uint16 val);
//extern void hcode();
//#define DUMP 1

extern GVC* vidp;
extern void postMsg(MSG m);

#ifdef DUMP
void hexout(int val)
{
	_asm
	{
		push	es
		push	bx
		push	cx
		
		mov	ah,0eh
		mov	al,'['
		int	10h

		
		mov	ax,val
		mov		cx,4
dlp:
		rol		ax,4
		push	ax
		and 	al,0fh
		cmp		al,9
		jg		alpha
		add		al,30h
		jmp		showval
alpha:
		add		al,37h
showval:
		mov	ah,0eh
		int	10h

		pop		ax
		loop	dlp
		mov	ah,0eh
		mov	al,']'
		int	10h

		pop		cx
		pop		bx
		pop		es

	}

}
#endif

int mstat;
int mxpos;
int	mypos;
int mzpos;
int mbusy = 0;
GMouse * pgm;
void notifyGMouse()
{
#ifdef DUMP
   	_asm
	{
	 	mov	ah,0eh
		mov	al,'{'
	 	int	10h
	}
	if(mstat & 1)
	{
		_asm
		{
			mov	ah,0eh
			mov	al,'L'
			int	10h
		}
	}
	if(mstat & 2)
	{
		_asm
		{
			mov	ah,0eh
			mov	al,'R'
			int	10h
		}
	}
	if(mstat & 0x40)
	{
		_asm
		{
			mov	ah,0eh
			mov	al,'X'
			int	10h
		}
	}
	if(mstat  & 0x80)
	{
		_asm
		{
			mov	ah,0eh
			mov	al,'Y'
			int	10h
		}
	}

	_asm
	{
		mov	ah,0eh
		mov	al,'x'
		int	10h
	}
	hexout(mxpos);

	_asm
	{
		mov	ah,0eh
		mov	al,'y'
		int	10h
	}
	hexout(mypos);
#endif
   	pgm->Update(mxpos,mypos,mzpos,mstat);
#ifdef DUMP
   	_asm
	{
	 	mov	ah,0eh
		mov	al,'}'
	 	int	10h
	}
#endif
}

void mhandler()
{

	_asm
	{
	    cli
		push	bp
		mov		bp,sp

		push	es
        push    ds
  
        push    cs
		push	cs
		pop		es
        pop     ds
  
        push    ax
		mov		ax,mbusy
		or		ax,ax
		jnz		skipm
		mov		ax,1
		mov		mbusy,ax

		mov     ax,[bp+22]
    	mov     mstat,ax
		
    	mov     al,[bp+20]
		cbw
    	mov     mxpos,ax

    	mov     ax,[bp+18]
    	cbw
		neg		ax
    	mov     mypos,ax

    	mov     al,[bp+16]
		cbw
    	mov     mzpos,ax

    	call    notifyGMouse
   	
   	 	;mov	ax,0e33h
	 	;int	10h
   		mov		ax,0
		mov		mbusy,ax
skipm:
    	pop     ax
    	pop     ds
		pop		es
		pop	   	bp

		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
    	sti
    	retf
	}
}
GMouse::GMouse()
{
	pgm = this;
	xloc = 0;
	yloc = 0;

}
GMouse::~GMouse()
{

}

char GMouse::Init()
{
	char	rslt = 0;
	BIOSDAT far * pBios = (BIOSDAT far *)MK_FP(0x40 ,0);

	pgm = this;
	if(pBios->HWList &4)
	{
		rslt = checkPS2();
	}
	if(rslt)
	{
		int numports = ((pBios->HWList & 0x0e00)>>9);
		int t;
		for(t=0;t<numports; t++)
		{
			if(checkCOM(pBios->combase[t]))  // serial mouse 
			{ 
				break;
			}
		}
	}
	if(rslt !=0)
	{
	   //	txtout("Mouse init failed\n");
	}
	return rslt;
}
char GMouse::Enable()
{
	char rslt = 0;
	Disable();
	_asm
	{
		cli
		mov	ax,0c207h
		push	es
		push 	cs
		pop		es
		mov		bx,offset mhandler
		int		15h
		pop		es

		mov		ax,0c200h
		mov		bh,1
		int		15h
		mov		rslt,ah
		sti
	}
	if(rslt==0)
	{
	   	vidp->enableCursor();
	}
	return rslt;
}
char GMouse::Disable()
{
	char rslt = 0;
	_asm
	{
		cli
		xor		bx,bx
		mov		ax,0c200h
		int		15h
		push	es
		xor		bx,bx
		mov		es,bx
		mov		ax,0c207h
		int		15h
		pop		es
		mov		rslt,ah
		sti
	}
	
	return rslt;
}
void GMouse::Update(int mxloc,int myloc,int mzloc,int status)
{
	int		xdif;
	int 	ydif;

	MSG m;
	
	vidp->moveCursor(mxloc,myloc,(int16*)&m.parm1,(int16*)&m.parm2);

	if(status & LBUTTON)
	{
		m.msg = LBUTTON;

		postMsg(m);
       // vidp->DrawChar(20, 20,'l',48,12);

	}
	return;


}
			
int GMouse::checkCOM(int cbase)
{
	int rslt = 0;
	//txtout(" checkCOM");

	return rslt;

}
int GMouse::checkPS2()
{
	int rslt = 0;
	//txtout(" checkPS2()");
_asm
{
mover: mov	ax,0c205h
		mov	bh,3
		int	15h
		jc	merr
		mov	ax,0c203h
		mov	bh,3
		int	15h
		jc	merr
		mov	ax,0c202h
		mov	bh,05
		int	15h
		jc	merr
		mov	ax,0c207h
		push	es
		push 	cs
		pop		es
		mov		bx,offset mhandler
		int	15h
		pop		es
merr:
		mov	al,ah
		mov	ah,0;
		mov	rslt,ax
	}
	//if(rslt!=0) txtout("Failed!");
	return rslt;

}