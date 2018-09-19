
#include <stdlib.h>
#include "EditWnd.h"
extern GVC* vidp;

EditWnd::EditWnd()
{
;
}
EditWnd::~EditWnd()
{
;
}
void EditWnd::Create(uint16 xloc,uint16 yloc,GWindow * parent )
{
	setStyle(RAISED);
	GWindow::Create(xloc,yloc,600,500,120,2,parent);
	WrkWnd = new GWindow();
	if(WrkWnd != 0)
	{
		WrkWnd->Create(xloc+10, yloc+10, 580, 450,13, 1, (GWindow *) this);
		addChild(WrkWnd);
	}
	LBAWnd = new GWindow();
	if(LBAWnd != 0)
	{
		LBAWnd->Create(xloc+70, yloc+470, 100, 20,13, 1, (GWindow *) this);
		addChild(LBAWnd);
	}
	
}
void EditWnd::draw()
{
	GWindow::draw();
	DrawString(20,470,"LBA:",89,118);
}; 
