#include "GVC.H"
#include "DeskTop.h"
#include <stdlib.h>
#include <i86.h>
#include "GMouse.h"
#include "DriveInfo.h"

DeskTop * DTop;
GVC*  vidp;
GMouse * moup;
char getchr();

void DriveInfoCollect();

MSG	msgs[20];

//
// shuffles the messages down in the que. called after message 0 has been extracted.
//
void nextMsg(MSG * pmsg)
{
	int ctr;
	
	_asm cli;
	
	*pmsg = msgs[0];
	msgs[0].msg = 0;
	ctr = 0; 
	while(msgs[ctr+1].msg !=0)
	{
		msgs[ctr] = msgs[ctr+1];
		ctr++;
	}
	_asm sti;	
}

main()  
{
	int x,y,c;
	char chr;
	vidp = new GVC(); 
	int	msgidx = 0;
	for(x=0 ; x<20 ; x++)
	{
		msgs[x].msg = 0;
	}
	if(vidp==0)
	{
		txtout("alloc GVC failed\n");
		return(-1);
	}

	moup = new GMouse();
	if(moup==0)
	{
		txtout("alloc GMouse failed\n");
		return(-1);
	}



	GWindow	* tstwnd;

//
//   collect drive info
//
// 
//   set up video mode ...
//
	if((x=vidp->Create(0x105))!=0)
	{
		return( -1);
	}
    vidp->SetActivePage(0);
    vidp->SetVisiblePage(0);
    vidp->ClearV(7);		// Clear screen 
//
//  create the desktop
//
	DTop = new DeskTop();
	if(DTop!=0)
	{
		DTop->Create();
		DriveInfoCollect();

		moup->Init();
		moup->Disable();
		//vidp->enableCursor();
		//getchr();
		DTop->draw();
		moup->Enable();
	}
	//chr=getchr();

	while((chr !='q')&& (chr!='Q'))
	{
		MSG msgg; 
		nextMsg(&msgg);

		if(msgg.msg!=0)
		{
			DTop->processMsg(msgg);
		}

		chr=getchr();
		if(chr!=0x0) DTop->checkChar(chr);


	}
	moup->Disable();
    vidp->Restore();
	return (0);
}
void postMsg(MSG m)
{
	int ctr;
	for(ctr = 0; ctr < 20; ctr++)
	{
		if(msgs[ctr].msg == 0)
		{
			msgs[ctr] = m;
			break;
		} 
	}	
}
char getchr()
{
	char tc;
	char sc;
	_asm
	{
		mov	ax,100h
		int	16h
		mov	ax,0
		jz	noChr		
		int	16h
		nop
noChr:
		mov	tc,al
		mov	sc,ah
	}
	if(tc==0 && sc!=0)
		tc = sc + 0x80;
	return tc;
}
void DriveInfoCollect()
{
	DriveInfo * pDrv;
	uint8 currdrv=0x80;
	uint8 numdrives= DriveInfo::GetNumDrives();
	int16 tr;
	_asm
	{
		mov	ax,sp
		mov	tr,ax
	}
	while(numdrives--)
	{
		pDrv=new DriveInfo();
	   	
	   	if(pDrv==0)
		{
			txtout("alloc DriveInfo failed\n");
			return;
		}
	   	pDrv->CollectInfo(currdrv++);

		tr =(int16) numdrives;
		hexout(tr);
 	
		DTop->AddDrive(pDrv);
 	}
}
	