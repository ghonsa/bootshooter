#include "GWindow.h"
class EditWnd:public GWindow
{
public:
	EditWnd();
	virtual ~EditWnd();
	void Create(uint16 xloc, uint16 yloc,GWindow * parent);
	void draw(); 
	DrawChar(int xloc,int yloc,char val,int color,int bgcolor);
	GWindow * WrkWnd;
	GWindow * LBAWnd;
} ;
