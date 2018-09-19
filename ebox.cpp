
#include <stdlib.h>
#include "ebox.h"
#include <ctype.h>
extern GVC* vidp;

ebox::ebox()
{
	int x;
	for(x=0;x<128;x++)
		buff[x]=0;

	chpos=0;
	style = NUMERIC;
}
ebox::~ebox()
{
;
}
void ebox::Create(uint16 xloc,uint16 yloc,uint16 xsiz, uint16 ysiz,GWindow * parent )
{
	GWindow::Create(xloc,yloc,xsiz,ysiz,13,1,parent);

}

void ebox::draw()
{
	GWindow::draw();
	DrawString( -1,-1,buff,1,13);


}

char * ebox::getAnswer()
{
	char tc;
	chpos = 0;
	dobeep();
	tc = getchr();
	if(tc!=0)
	{
		if(tc=0x0d)
			return buff;

		if((style == NUMERIC) && (!isdigit(tc)))
		{
			dobeep();
		}
		else if(chpos<127)
		{
			buff[chpos] = tc;
			chpos++;
		}	
		else
		{
			dobeep();
		}
		draw();
	}
	return 0;
}

char ebox::getchr()
{
	char tc=0;
	char sc;
	_asm
	{
		mov	ax,1
		int	16h
		jz nothing
		mov	ax,0
		int	16h

		mov	tc,al
		mov	sc,ah
nothing:
	}
	return tc;
}


void ebox::dobeep()
{
	_asm
	{
		mov	ax,0e07h
		mov	bx,0
		int	10h
	}

}