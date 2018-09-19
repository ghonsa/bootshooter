#include "GWindow.h"
class yesno:public GWindow
{
public:
	yesno();
	virtual ~yesno();
	void Create(uint16 xloc, uint16 yloc,GWindow * parent);
	void draw(); 
	char * getAnswer();
	DrawChar(int xloc,int yloc,char val,int color,int bgcolor);
	GWindow * yesbut;
	GWindow * nobut;
	char answ;
} ;
