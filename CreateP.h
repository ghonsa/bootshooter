#include "GWindow.h"
#include "ebox.h"
#include "DriveInfo.h"


class CreateP:public GWindow
{
public:
	CreateP();
	virtual ~CreateP();
	void Create(uint16 xloc, uint16 yloc,GWindow * parent,DriveInfo * di);
	void draw(); 
	int checkChar(char c);
	char * getAnswer();
	char getchr();
	DrawChar(int xloc,int yloc,char val,int color,int bgcolor);
	GWindow * yesbut;
	GWindow * nobut;
	ebox * reqSizeW;
	ebox * typeW;
	ebox * verifyW;
	DriveInfo * pdi;
	uint32 reqsize;
	uint16 ptype;
} ;
