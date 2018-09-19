
/*****************************************************************************
*  GMouse
*
*       Copyright 2005 Greg Honsa
*
*
*****************************************************************************/
#ifndef GMOUSEDEF

#define GMOUSEDEF 1
#define LBUTTON 1
#define RBUTTON 2

typedef struct
{
	unsigned int combase[4];
	unsigned int lptbase[3];
	unsigned int foo1;
	unsigned int HWList;

}BIOSDAT;

class GMouse
{
public:

	GMouse();	
    virtual ~GMouse();
	char Init();
	char Enable();
	char	Disable();
	void Update(int mxloc,int myloc,int mzloc,int status);
	int xloc;
	int	yloc;
	int	checkCOM(int cbase);
	int checkPS2();
	char cport;
};
#endif