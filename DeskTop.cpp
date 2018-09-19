#include "DeskTop.h"
//#include "GMouse.h"
extern GVC* vidp;

DeskTop::DeskTop()
{
	lastmsg.msg = 0;
	lastmsg.parm1 = 0;

}
DeskTop::~DeskTop()
{
;
}
void DeskTop::Create( )
{
	int	t;
	GWindow * pw;
	for(t=0;t<20;t++)
		drives[t]=0;

	GWindow::Create(0,0,vidp->GetMaxX(),vidp->GetMaxY(),12,116,0);
}
void DeskTop::AddDrive(DriveInfo * pdrv)
{
	int	t;
	for(t=0;t<20;t++)
	{
		if(drives[t]==0)
		{
			driveWnd * pdrvw = new driveWnd();
			if(pdrvw !=0)
			{
				pdrvw->setDriveInf(pdrv);
				pdrvw->Create((t+1)*60,((t+1)*40)+40,(GWindow *) this);
				addChild((GWindow *)pdrvw);

				drives[t]=pdrvw;
			}
			else
			{
				txtout("DriveWnd fail\n");
				_asm
				{
					mov	ax,0
					int	16h
				}

			}
			break;
		}
	}

}

void DeskTop::draw()
{
	vidp->eraseCursor();
	GWindow::draw();
	GWindow * pwnd;
	int ctr =0;
    DrawString(100,20,"Bootshooter",48,12);
   	vidp->showCursor();



   //	while(( pwnd = m_children[ctr])!=0)
   //	{
   //		DrawString(-1,-1,"child\n",34,01);
   //		m_children[ctr++]->draw();
   //	}
}
int DeskTop::checkChar(char c)
{
	int processed = 0;
 	switch (c)
 	{
 		case 9:
 			nextWnd();
			processed=1;
 			break;
		case 0xc8:
			// mouse up
			vidp->moveCursor(0,-2,0,0);
			processed=1;
			break;
		case 0xD0:
			// mouse up
			vidp->moveCursor(0,2,0,0);
			processed=1;
			break;
		case 0xcd:
			// mouse right
			vidp->moveCursor(2,0,0,0);
			processed=1;
			break;
		case 0xcb:
			// mouse up
			vidp->moveCursor(-2,0,0,0);
			processed=1;
			break;

	
		default:
		 	processed=m_children[m_topWnd]->checkChar(c);
		 	break;	
	}
	return processed;
}
void DeskTop::processMsg(MSG m)
{
	GWindow * pwnd;
	if(m.msg == lastmsg.msg)
		return ;
	if(m.msg == LBUTTON)
	{
		int chk;
		for(chk = 0; chk <MAXCHILD; chk++)
		{
			if(m_zorder[chk]!=-1)
			{
				pwnd =m_children[m_zorder[chk]];
				if(pwnd->inBounds(m.parm1, m.parm2) !=0)
				{
					if(chk!=0)
					{
						move2Top(pwnd);
						break;
					}
					else
					{
						pwnd->processMsg(m);
						break;
					}
				}
			} 
		}
	}
}
