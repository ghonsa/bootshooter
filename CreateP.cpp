
#include <stdlib.h>
#include "CreateP.h"
extern GVC* vidp;

CreateP::CreateP()
{
	reqsize = 0;
}
CreateP::~CreateP()
{
	delete(yesbut);
	delete(nobut);
;
}
void CreateP::Create(uint16 xloc,uint16 yloc,GWindow * parent,DriveInfo * di  )
{
	pdi = di;
	setStyle(RAISED);
	GWindow::Create(xloc,yloc,350,300,120,2,parent);
	
	reqSizeW = new ebox();
	if(reqSizeW != 0)
	{
		reqSizeW->Create(xloc+90, yloc+100, 120, 24, (GWindow *) this);
		reqSizeW->setStyle(SUNKEN);
		addChild(reqSizeW);
	}
	m_FocusWnd = reqSizeW;
	typeW = new ebox();
	if(typeW != 0)
	{
		typeW->Create(xloc+90, yloc+150, 120, 24, (GWindow *) this);
		typeW->setStyle(SUNKEN);

		addChild(typeW);
	}
	verifyW = new ebox();
	if(verifyW != 0)
	{
		verifyW->Create(xloc+90, yloc+200, 24, 24, (GWindow *) this);
		verifyW->setStyle(SUNKEN);

		addChild(verifyW);
	}



	yesbut = new GWindow();
	if(yesbut != 0)
	{
		yesbut->Create(xloc+10, yloc+260, 80, 34,118,89, (GWindow *) this);
		yesbut->setStyle(RAISED);
		addChild(yesbut);
	}
	nobut = new GWindow();
	if(nobut != 0)
	{
		nobut->Create(xloc+150, yloc+260, 80, 34,118,89, (GWindow *) this);
		nobut->setStyle(RAISED);
		addChild(nobut);
	}

}
void CreateP::draw()
{
	char buff[33];
	
	GWindow::draw();
	DrawString( 80,30,"Create Partition Drive ",14,120);
    DrawString(-1 ,-1,itoa(pdi->DIid,buff,16) ,14,120);

   	DrawString( 20,60," Available: ",14,120);
    DrawString(-1 ,-1,ltoa((pdi->DIFreeSect*512)/1000000,buff,10) ,14,120);
	DrawString(-1,-1," Mb",14,120);

	DrawString(30, 100," Size:",14,120);
	DrawString(30, 150," Type:",14,120);

	yesbut->DrawString(-1 ,-1,"Yes",89,118);
	nobut->DrawString(-1 ,-1,"No",89,118);

}; 
int CreateP::checkChar(char c)
{
	return 0;
}

char * CreateP::getAnswer()
{
	char tc;
	char sc;
	char * rslt;
	while(1)
	{
		if(m_FocusWnd !=0)
		{
			rslt = m_FocusWnd->getAnswer();
			if(rslt !=0)
			{
				if(m_FocusWnd==reqSizeW)
				{
					reqsize = (uint32) (atol(rslt)*2048);
					m_FocusWnd = typeW;
				}
				else if(m_FocusWnd==typeW)
					ptype = (uint16) atoi(rslt);
			}
		}
		else
		{
			tc = getchr();
			if((tc=='y')||(tc == 'Y'))
			{
				pdi->CreatePartition(reqsize,ptype,0);
				return 0;
			}
			else if((tc=='n')||(tc == 'N'))
				return 0;
		}
	}
	return 0;
}

char CreateP::getchr()
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
