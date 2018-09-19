
#include "GVC.H"
#include <stdlib.h>
#include <stdio.h>
GVC*  vidp;

main()  
{
	int16 x,y,c;
	int16 dif, col;;
	vidp = new GVC(); 
	if(vidp==0)
	{
		printf("alloc GVC failed\n");
		return(-1);
	}
	if((x=vidp->Create(0x105))!=0)
	{
		return( -1);
	}
    vidp->SetActivePage(0);
    vidp->SetVisiblePage(0);
    vidp->ClearV(0);		// Clear screen 

	x=10;
	y=10;
	col=0;
	dif = (vidp->GetMaxX()-32)/16;
	for(c=0;c<256;c++)
	{
		vidp->FillRect( x, y, dif,dif/2, c);
		x+=dif+2;
		if(++col >=16)
		{
			x=10;
			y+=(dif/2)+2;
			col=0;
		}
	}
	_asm
	{
		mov	ax,0
		int	16h
	}
	return 0;
}