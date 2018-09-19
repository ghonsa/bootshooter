
#include <stdlib.h>
#include "yesno.h"
extern GVC* vidp;

yesno::yesno()
{
;
}
yesno::~yesno()
{
	delete(yesbut);
	delete(nobut);
;
}
void yesno::Create(uint16 xloc,uint16 yloc,GWindow * parent )
{
	setStyle(RAISED);
	GWindow::Create(xloc,yloc,250,80,120,2,parent);
	yesbut = new GWindow();
	if(yesbut != 0)
	{
		yesbut->Create(xloc+10, yloc+30, 80, 34,118,89, (GWindow *) this);
		yesbut->setStyle(RAISED);
		addChild(yesbut);
	}
	nobut = new GWindow();
	if(nobut != 0)
	{
		nobut->Create(xloc+150, yloc+30, 80, 34,118,89, (GWindow *) this);
		nobut->setStyle(RAISED);
		addChild(nobut);
	}

}
void yesno::draw()
{
	GWindow::draw();
	yesbut->DrawString(-1 ,-1,"Yes",89,118);
	nobut->DrawString(-1 ,-1,"No",89,118);

}; 

char * yesno::getAnswer()
{
	char tc;
	char sc;
	_asm
	{
		mov	ax,0
		int	16h
		mov	tc,al
		mov	sc,ah
	}
	answ = tc;
	return &answ;
}
