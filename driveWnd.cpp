#include <stdlib.h>
#include "driveWnd.h"
#include "diskio.h"
#include "yesno.h"
#include "EditWnd.h"
#include "CreateP.h"
#include <i86.h>

extern GVC* vidp;


extern void txtout(char * txt);

driveWnd::driveWnd()
{
	di=0;
	modalWnd = 0;
;
}
driveWnd::~driveWnd()
{
;
}
void driveWnd::Create(uint16 xloc,uint16 yloc,GWindow * parent )
{
	setStyle(RAISED);
	GWindow::Create(xloc,yloc,500,400,120,2,parent);
	partwnd = new GWindow();
	
	if(partwnd != 0)
	{
		partwnd->Create(xloc+10, yloc+40, 478, 300,13, 1, (GWindow *) this);
		addChild(partwnd);
		partwnd->setStyle(SUNKEN);

	}
	BootButton=	new GWindow();
	if(BootButton != 0)
	{
		BootButton->Create(xloc+10, yloc + 364,84 ,28 ,118, 89, (GWindow *) this);
		BootButton->setStyle(RAISED);
		addChild(BootButton);
	}
	CPartButton=	new GWindow();
	if(CPartButton != 0)
	{
		CPartButton->Create(xloc+105, yloc + 364,84 ,28 ,118, 89, (GWindow *) this);
		CPartButton->setStyle(RAISED);
		addChild(CPartButton);
	}
	DPartButton=	new GWindow();
	if(DPartButton != 0)
	{
		DPartButton->Create(xloc+200, yloc + 364,84 ,28 ,118, 89, (GWindow *) this);
		DPartButton->setStyle(RAISED);
		addChild(DPartButton);
	}
}
void driveWnd::draw()
{
	GWindow::draw();
	char buff[33];
    //return;
    if(di!=0)
	{
    	long sz = ( ((di->DIExtSize/1000)*512)/1000);
    	int	x;
    	DrawString(-1 ,-1,"Drive ",14,120);
    	DrawString(-1 ,-1,itoa(di->DIid,buff,16) ,14,120);
    	DrawString(-1 ,-1,"  Total:",14,120);
    	DrawString(-1 ,-1,ltoa(sz,buff,10) ,14,120);
    	DrawString(-1 ,-1," Mb  Free:",14,120);

    	DrawString(-1 ,-1,ltoa((di->DIFreeSect*512)/1000000,buff,10) ,14,120);

    	DrawString(-1 ,-1," Mb",14,120);
		BootButton->DrawString(-1 ,-1,"Boot",89,118);
		CPartButton->DrawString(-1 ,-1,"Create",89,118);
		DPartButton->DrawString(-1 ,-1,"Delete",89,118);

		partwnd->m_currx = 10;			// current character position within window
		partwnd->m_curry = 4;			//
		
		displayPartitions(di->DIPartTab);
	}
}; 
void driveWnd::displayPartitions( PARTITION_INFO *  pis[])
{
	char buff[33];
	int	x;
	for(x=0;x<4;x++)
	{
		uint16 fgcolor = 1;
		uint16 bgcolor = 13;
						
		if(pis[x]!=0)
		{
			uint8 ostype =pis[x]->PIpte.bte_system;
			if(pis[x]->PIActive ==1)
			{
				fgcolor=13;
				bgcolor=1;
			}
			if(pis[x]->PIpte.bte_endsector!=0)										 
			{
    			if(pis[x]->PIInExtended ==1)
    				partwnd->DrawString(-1 ,-1,"   Ext ",fgcolor,bgcolor);
    			partwnd->DrawString(-1 ,-1,"Partition: ",fgcolor,bgcolor);
				if(pis[x]->PIbootable)
    				partwnd->DrawString(-1 ,-1,"Bootable ",fgcolor,bgcolor);
				partwnd->DrawString(-1 ,-1,getTypeStr(ostype),fgcolor,bgcolor);
 	    		long sz = (((pis[x]->PIpte.bte_totalsector/1000)*512)/1000);
        		partwnd->DrawString(-1 ,-1,ltoa(sz,buff,10) ,fgcolor,bgcolor);
				partwnd->DrawString(-1 ,-1,"Mb",fgcolor,bgcolor);
		   		partwnd->DrawString(-1 ,-1,"\n",fgcolor,bgcolor);
			 	if(pis[x]->PIExtended==PTE_EXTENDED)
				{
					displayPartitions(pis[x]->PIEParts);	
				}
		 	}
		}
	}
}

#define TYPESZ 21	
char TYPE_TAB[TYPESZ] = {
	FAT12, 	
	FAT16, 	
	EXTEND,  
	BGFAT16,	
	NTFS,	
	FAT32,	
	BFAT32,	
	BFAT16,	
	BEXTEND, 
	EISA,	
	DYNVOL,
	LINUXSW,	
	LINUXRT,
	POWMAN,  
	MDFAT16,	
	MDNTFS,  
	HIB,		
	DELL,	
	IBM,		
	GPT,		
	EFI};		

char * TYPE_STR_TAB[TYPESZ] = {
 "FAT12 primary ",
 "FAT16 partition ",
 "Extended partition ",
 "BIGDOS FAT16 ",
 "Installable (NTFS) ",
 "FAT32 partition " ,   
 "FAT32 INT 13h exts " , 
 "BIGDOS/FAT16/INT13x "	,
 "Extended INT13 exts "	,
 "EISA partition  ",    
 "Dynamic volume  ",    
 "Linux swap ",          
 "Linux native ",        
 "Power management ",   
 "Multidisk FAT16 NT4", 
 "Multidisk NTFS  NT4", 
 "Laptop hibernation",  
 "Dell OEM partition ",  
 "IBM OEM partition ",  
 "GPT partition ",      
 "EFI System "};         

char *sUnknown	= "Unknown ";

void driveWnd::setDriveInf(DriveInfo * pdi)
{
	di=pdi;
}
char * driveWnd::getTypeStr(uint8 ostype)
{
	int	x=0;
	while(x<TYPESZ)
	{
		if(TYPE_TAB[x]== ostype)
		{
			return TYPE_STR_TAB[x];
		}
		x++;
	}
	return(sUnknown);	
}


void driveWnd::processMsg(MSG m)
{
	PARTITION_INFO  *  pis;
	
	if(m.msg == lastmsg.msg)
		return ;
	if(m.msg == LBUTTON)
	{
		if(BootButton->inBounds(m.parm1, m.parm2) !=0)
		{
	 		checkChar('B');	

		}
		if(DPartButton->inBounds(m.parm1, m.parm2) !=0)
		{
	 		checkChar('d');	
		}
		if(CPartButton->inBounds(m.parm1, m.parm2) !=0)
		{
	 		checkChar('c');	
		}

	}
}
int driveWnd::checkChar(char c)
{
	PARTITION_INFO  *  pis;
	int	processed =0;
	if(modalWnd !=0)
		return modalWnd->checkChar(c);

	switch(c)
	{
		case 'b':
		case 'B':
			processed = 1;
			if((pis=getActive())!=0)
			{
				if(pis->PIbootable==0)
				{
					char * rslt;
					yesno * yesdlg = new yesno();
					yesdlg->Create(300,300,0);
					yesdlg->draw();
					yesdlg->DrawString(-1,-1,"Not marked as bootable, try boot?",89,120);
					rslt = yesdlg->getAnswer(); 
					m_parentW->draw();
					delete(yesdlg);
					if(*rslt=='n')
					{
						break;
					}	
				}
				Boot(pis->PIStartLBA,pis->PIDrive);
			}			
			// boot request
			break;
		case 'c':
		case 'C':
			{
				CreateP * crpwnd  = new CreateP();
				crpwnd->Create(300,200,0,di);
				crpwnd->draw();
				crpwnd->getAnswer();
				processed = 1;
				draw();


				break;
			}
		case 'p':
		case 'P':
			processed = 1;
			// Partition work
			break;
		case 'd':
		case 'D':
		case 0x7f:
			if((pis=getActive())!=0)
			{
				char * rslt;
				yesno * yesdlg = new yesno();
				yesdlg->Create(300,300,0);
				yesdlg->draw();
				yesdlg->DrawString(-1,-1,"Delete Partition?",89,120);
				rslt = yesdlg->getAnswer();
				if(*rslt == 'y')	
			   	{
			   	   	di->DeletePartition(pis);
				}
				delete yesdlg;
				draw();
			}
			processed =1;
			break;
		case 0xc9:
			// up arrow
			prevPartition();
			break;
		case 0xd1:
			nextPartition();
			break;
			// down arrow
		default:
			break;
	}
	return processed ;
}
void driveWnd::prevPartition()
{
	int	x;
	int setactive=0;
	for(x=0;x<4;x++)
	{
		if(di->DIPartTab[x]->PIActive == 1)
		{
			int  y;
			di->DIPartTab[x]->PIActive=0; 
			if(x==0) y=3;
			else y=x-1;

			while(y >=0)
			{
				if(di->DIPartTab[y]->PIpte.bte_totalsector!=0)
				{
					di->DIPartTab[y]->PIActive = 1;
					setactive =1;
					break;
				}
				if(y==x)
				{
					di->DIPartTab[y]->PIActive = 1;
					setactive =1;
				 	break;
				}
				if(y==0) y=4;
				y--;
			}
			if(	setactive!=0) break;
		}
	}
	partwnd->m_currx = 10;			// current character position within window
	partwnd->m_curry = 4;			//

	displayPartitions(di->DIPartTab);
}
void driveWnd::nextPartition()
{
	int	x;
	int setactive=0;
	for(x=0;x<4;x++)
	{
		if(di->DIPartTab[x])
		{
			if(di->DIPartTab[x]->PIExtended ==PTE_EXTENDED)
			{
				int rslt;
				if((rslt=nextExtendPart(0, di->DIPartTab[x]->PIEParts))==1)
					break;	
				else if(rslt == -1)  di->DIPartTab[x]->PIActive = 1;
			}	
			if( di->DIPartTab[x]->PIActive == 1)
			{
			// we have the active partition here
				int  y;
				di->DIPartTab[x]->PIActive=0; // mark inactive

				if(x==3) y=0;  // set index to next partition( or first if x is last)
				else y=x+1;
				while(y <4)
				{
					if(di->DIPartTab[y]!=0)	 // is partition valid?
					{
						// if an extended partition, we need to look at the children

						if(di->DIPartTab[y]->PIExtended ==PTE_EXTENDED)
						{
							if(nextExtendPart(1,di->DIPartTab[y]->PIEParts))
							{
								setactive =1;
								break;
							}
						}
		   				di->DIPartTab[y]->PIActive = 1;
						setactive =1;
						break;
					}
					if(y==3) y=0;
					else y++;
				}
			}
			if(	setactive!=0) break;
		}
	}
	partwnd->m_currx = 10;			// current character position within window
	partwnd->m_curry = 4;			//
	displayPartitions(di->DIPartTab);
}
int	driveWnd::nextExtendPart(int fresh,PARTITION_INFO  * pis[])
{
	int	x;
	int setactive=0;

	if(fresh==1)
	{
		for(x=0;x<4;x++)
		{
			if(pis[x])
			{
				if(pis[x]->PIpte.bte_totalsector!=0)
				{
					pis[x]->PIActive = 1;
					setactive =1;
					break;
				}
			}
		}
		return setactive;
	}	
	for(x=0;x<4;x++)
	{
		if(pis[x])
		{
			if( pis[x]->PIActive == 1) 	// look for active part
			{
				int  y;
				pis[x]->PIActive=0;    // clear it

				if(x==3) y=0;
				else y=x+1;

				while(y <4)
				{
					if(pis[y] !=0)
					{
						pis[y]->PIActive = 1;
						setactive =1;
						return 1;
					}
					if(y==x)
					{
				 		return -1;
					}		
					if(y==3)  return -1;
					else y++;
				}
			}
		   
		}
	}
	return 0;
} 
PARTITION_INFO  * driveWnd::getActive()
{
	int	x;
	for(x=0;x<4;x++)
	{
		if(di->DIPartTab[x])
		{
			if(di->DIPartTab[x]->PIExtended ==PTE_EXTENDED)
			{
				int y;
				for(y=0;y<4;y++)
				if( di->DIPartTab[x]->PIEParts[y]!=0)
				{
					if(di->DIPartTab[x]->PIEParts[y]->PIActive == 1)
						return(di->DIPartTab[x]->PIEParts[y]);
				}	
			}
			if( di->DIPartTab[x]->PIActive == 1)
				return(di->DIPartTab[x]);
		}
	}
	return(0);
}