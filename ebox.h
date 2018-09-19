#include "GWindow.h"
#define NUMERIC 1
#define ALPHA 2;
class ebox:public GWindow
{
public:
	ebox();
	virtual ~ebox();
	void Create(uint16 xloc, uint16 yloc,uint16 xsiz, uint16 ysiz,GWindow * parent);
	void draw(); 
	DrawChar(int xloc,int yloc,char val,int color,int bgcolor);
	char * getAnswer();
	char getchr();
	void dobeep();

	char buff[128];
	int chpos;
	int style;
} ;
