/*****************************************************************************
*  GVC - video context
*
*       Copyright 2005 Greg Honsa
*
*
*****************************************************************************/
#include "GVC.h";
#include "GWindow.h"
#include <dos.h>;
#include <conio.h>
#include <stdlib.h>


void setPalette332();
void setgpallet();
void vgaSetPalette(int16 start, int16 count, vgaColor *p);

uint8 bcursor[] = {	00,00,88,88,88,88,88,88,88,88,
				  	00,00,00,88,88,88,88,88,88,88,
					00,00,00,00,88,88,88,88,88,88,
					00,00,00,00,00,88,88,88,88,88,
					00,00,00,00,00,00,88,88,88,88,
					00,00,00,00,00,00,00,88,88,88,
					00,00,00,00,00,00,00,00,00,88,
					00,00,00,00,00,00,00,00,00,00,
					00,00,00,00,00,00,88,88,88,88,
					00,00,00,88,88,00,00,88,88,88,
					00,00,88,88,88,00,00,00,88,88,
					00,00,88,88,88,88,00,00,00,88,
					88,88,88,88,88,88,88,00,00,88,
					88,88,88,88,88,88,88,00,00,00
					};
GVC::GVC()
{
}
GVC::~GVC()
{
              
}       
int GVC::Create(int vidMode)
{
	// save requested mode
	int32 temp;
	GetVBEInfo(&m_vbi);
                
	m_currentMode=vidMode;                  
	// verify the video BIOS support
	if (m_vbi.vesa[0] != 'V' ||
        m_vbi.vesa[1] != 'E' ||
        m_vbi.vesa[2] != 'S' ||
        m_vbi.vesa[3] != 'A')
	{
        return 0x056;
	}
    if (m_vbi.majorMode == 1 &&
        m_vbi.minorMode < 2)
	{
   		return 0x52;
	}
        // get mode info for requested mode
	if (!GetVModeInfo(m_currentMode, &m_vmi) || !(m_vmi.modeAttr & 1))
	{
        return 0x4d;
	}
	// is it an 8 bit, 256 color mode? *** we should not need this check 
	//  as we will control what modes we set 
	if (m_vmi.bitsPerPixel != 8)
	{
        return 0x381;
	}
	//setPalette332();
	m_maxx = m_vmi.width - 1;
	m_maxy = m_vmi.height - 1;

	m_vwidth = m_vmi.width;
	m_vheight = m_vmi.height;

	m_currentBank = -1;

	m_activePage = 0;
	m_activePageOffset = 0;
	m_visiblePage = 0;

	temp = (int32)m_vmi.width * (int32)m_vmi.height;
	temp = (temp + 0xffffL) >> 16;
	m_banksPerPage = temp;

	GetVMode(&m_origMode);      // save the current mode
	SetVMode(m_currentMode);    // set the new mode

	GetFont(&m_fntwidth,&m_fontSeg,&m_fontOff);        
	setgpallet();
	
 	//setPalette332();
	return 0;
}
void setgpallet()
{
    vgaColor p[256];

	int r,g,b,c ;
	r=0;
	g=0;
	b=0;

	c=0;
	// grey scale
	while(c<16)
	{
	    p[c].red = r;
        p[c].green = g;
        p[c].blue = b;
        
        c++;
		r+=4;
		g+=4;
		b+=4;
	 }
	 // reds
	 r=1;
	 g=0;
	 b=0;
	 while(c<32)
	 {
	    p[c].red = r;
        p[c].green = g;
        p[c].blue = b;
        
        c++;
		r+=4;
		//g+=1;
		//b+=1;
	  }
	 r=8;
	 g=1;
	 b=0;
	 while(c<48)
	 {
	    p[c].red = r;
        p[c].green = g;
        p[c].blue = b;
        
        c++;
		r+=3;
		g+=3;
		//b+=1;
	  }
	 // greens
	 r=4;
	 g=16;
	 b=4;
	 while(c<80)
	 {
	    p[c].red = r;
        p[c].green = g;
        p[c].blue = b;
        
        c++;
		;r+=1;
		g+=3;
		b+=1;
	  }
	 r=16;
	 g=16;
	 b=4;
	 while(c<112)
	 {
	    p[c].red = r;
        p[c].green = g;
        p[c].blue = b;
        
        c++;
		r+=3;
		g+=3;
		b+=1;
	  }
	 r=4;
	 g=4;
	 b=16;
	 while(c<144)
	 {
	    p[c].red = r;
        p[c].green = g;
        p[c].blue = b;
        
        c++;
		r+=1;
		g+=1;
		b+=3;
	  }
	 r=16;
	 g=4;
	 b=16;
	 while(c<176)
	 {
	    p[c].red = r;
        p[c].green = g;
        p[c].blue = b;
        
        c++;
		r+=3;
		g+=1;
		b+=3;
	  }
	 r=4;
	 g=16;
	 b=16;
	 while(c<208)
	 {
	    p[c].red = r;
        p[c].green = g;
        p[c].blue = b;
        
        c++;
		r+=1;
		g+=3;
		b+=3;
	  }
	 r=16;
	 g=16;
	 b=16;
	 while(c<240)
	 {
	    p[c].red = r;
        p[c].green = g;
        p[c].blue = b;
        
        c++;
		r+=3;
		g+=3;
		b+=3;
	  }
	 r=16;
	 g=16;
	 b=16;
	 while(c<256)
	 {
	    p[c].red = r;
        p[c].green = g;
        p[c].blue = b;
        
        c++;
		//r+=3;
		g+=3;
		b+=3;
	  }


   //
    vgaSetPalette(0, 256, p);


}
void setPalette332()
{
    int r, g, b, c;
    vgaColor p[256];

    c = 0;
    for (r = 0; r <= 64; r += 9)
    {
        for (g = 0; g <= 64; g += 9)
        {
            for (b = 0; b < 64; b += 21)
            {
                p[c].red = r;
                p[c].green = g;
                p[c].blue = b;
                c++;
            }
        }
    }

    vgaSetPalette(0, 256, p);
}

void vgaSetPalette(int16 start, int16 count, vgaColor *p)
{
    int i;

    if (start < 0 || (start + count - 1) > 255)
    {
        return;
    }

    while(!(inp(0x3da) & 0x08));    // wait vertical retrace

    outp(PAL_WRITE_ADDR, start);
    for (i = 0; i < count; i++)
    {
        outp(PAL_DATA, p->red);
        outp(PAL_DATA, p->green);
        outp(PAL_DATA, p->blue);
        p++;
    }
}

/*****************************************************************************
*
*
*****************************************************************************/
GVC::Restore()
{
	SetVMode(m_origMode);    // set the new mode
}
/*****************************************************************************
*
*
*****************************************************************************/
GVC::ClearV(int color)
{
	int16 i;
	for (i = 0; i < m_banksPerPage; i++)
	{
		m_currentBank = i + m_activePageOffset;
		SetVBankAAddr(i + m_activePageOffset);
		memset(0xa000, 0, color, 0x8000);
		memset(0xa000, 0x8000, color, 0x8000);
	}
}
/*****************************************************************************
*
*
*****************************************************************************/
int GVC::GetNumPages()
{
	return m_vmi.imagePages + 1;
}
/*****************************************************************************
*
*
*****************************************************************************/
int GVC::SetActivePage(int page)
{
	int tmp_page= m_activePage;
	if (page < 0 || page >= GetNumPages())
	{
		return -1;
 	}
	m_activePage = page;
	m_activePageOffset = page * m_banksPerPage;

	return m_activePage;
}
/*****************************************************************************
*
*
*****************************************************************************/
void GVC::SetVisiblePage(int page)
{
	int16 pixel, line;
	int32 address;

	if (page < 0 || page >= GetNumPages())
	{
		return;
	}
	m_visiblePage = page;

	address = ((int32)m_banksPerPage * (int32)page) << 16;
	line = address / (int32)m_vmi.width;
	pixel = address % (int32)m_vmi.width;

	while(inp(0x3da) & 0x09);    // wait for blanking to end

	SetVDisplayStart(pixel, line);

	while(!(inp(0x3da) & 0x08));    // wait for vertical retrace
}
/*****************************************************************************
*
*
*****************************************************************************/
int GVC::Pixel(uint16 xloc,uint16 yloc, uint16 color)
{
	int32 offset;
	int16 bank;
	uint8 far *address;

	if (xloc < 0 || xloc > m_maxx || yloc < 0 || yloc > m_maxy)
	{
        return-1;
	}
	offset = ((int32)yloc * (int32)m_vmi.width) + (int32)xloc;
	bank = (offset >> 16) + m_activePageOffset;
	address = (uint8 far *) MK_FP(0xa000, (int)(offset & 0xffffL));
	if (bank != m_currentBank)
	{
        m_currentBank = bank;
        SetVBankAAddr(m_currentBank);
	}

	*address = (uint8)color;
	return 0;
}
/*****************************************************************************
*
*
*****************************************************************************/
int GVC::FillRect(int16 xloc,int16 yloc,int16 xsiz, int16 ysiz,int16 color)
{
	m_rctcolor=color;
	processRect(fillr, xloc, yloc,  xsiz,  ysiz);

	return 0;
}
/*****************************************************************************
*
*
*****************************************************************************/
int GVC::DrawRect(int16 xloc,int16 yloc,int16 xsiz, int16 ysiz,int16 color)
{
	uint16 xend = xloc + xsiz;
	uint16 yend = yloc + ysiz;
	uint16 tmp;
	// draw top and bottom
	for(tmp=xloc;tmp<xend;tmp++)
	{
		Pixel(tmp,yloc,color);
    	Pixel(tmp,yend,color);
	}
	for(tmp=yloc; tmp<yend;tmp++)
	{
    	Pixel(xloc,tmp,color);
    	Pixel(xend,tmp,color);
	}
	return 0;
} 
/*****************************************************************************
*
*
*****************************************************************************/
int GVC::DrawChar(int16 xloc,int16 yloc,char val,int16 color,int16 bgcolor)
{
	// get pointer to font...
	
	m_cfontseg=m_fontSeg;
	m_cfontoff = m_fontOff+(val*m_fntwidth);
	m_ccolor=color;
	m_cbgcolor=bgcolor;
	processRect(charr, xloc, yloc,  8,  m_fntwidth);
	return 0;
}
/*****************************************************************************
*
*
*****************************************************************************/
int GVC::DrawLine(int16 xstart, int16 ystart, int16 xend, int16 yend, int16 color)
{
 	int16 x,y;
	long ckval; 
	if(xstart==xend && ystart==yend)
		Pixel(xstart,ystart,color);
	else if(abs(xend - xstart) >= abs(yend-ystart))
	{
		if(xend<xstart)
		{ // swap ends
			x = xend;
			xend=xstart;
			xstart=x;	
			y = yend;
			yend=ystart;
			ystart=y;
		}
	   	ckval = (long)(yend-ystart)/(xend-xstart);

		for( x=xstart; x <= xend ; x++)
		{ 
			y= ystart + (x-xstart)* ckval;	
			Pixel(x,y,color);
		}
	}
	else
	{
		if(yend<ystart)
		{ // swap ends
			x = xend;
			xend=xstart;
			xstart=x;	
			y = yend;
			yend=ystart;
			ystart=y;
		}
	   	ckval = (long)(xend-xstart)/(yend-ystart);

		for( y=ystart; y <= yend ; y++)
		{ 
			x= xstart + (y-ystart)* ckval;	
			Pixel(x,y,color);
		}
	}
   return 0;
}
/*****************************************************************************
*
*
*****************************************************************************/
int GVC::DrawString(int16 xloc,int16 yloc,char* val,int16 color,int16 bgcolor)
{
	char	chr;
	while((chr=*val++)!=0)
	{
		DrawChar(xloc,yloc,chr,color,bgcolor);

	}

    return 0;

}
/*****************************************************************************
*
*
*****************************************************************************/
//void * GVC::CreateWindow(int xloc, int yloc, int xsiz, int ysiz,int color, int bgcolor)
//{
//	GWindow * pnewWnd = new GWindow();
//	pnewWnd->Create(xloc,yloc,xsiz,ysiz,bgcolor,color,this);
//
//	return (void *)pnewWnd ;
//
//} 
/*****************************************************************************
*
*
*****************************************************************************/
//void * GVC::CreateButton(int xloc, int yloc, int xsiz, int ysiz,int color, char * label)
//{
//	GWindow * pnewWnd = new GWindow();
//	return (void *)pnewWnd ;
//
//}
/*****************************************************************************
* fillr - input: char far * to screen memory
*                Width of the rectangle
*                x and y offsets from the orig rect start(not used for fill)
*                GVC pointer 
*
*
*****************************************************************************/
static void GVC::fillr(uint8 far * addr,uint16 width,uint16 xoff,uint16 yoff,GVC * ob)
{
    memset(FP_SEG(addr),FP_OFF(addr), ob->m_rctcolor, width);
}

/*****************************************************************************
* charr - input: char far * to screen memory
*                Width of the character
*                x and y offsets from the font start
*                GVC pointer 
*	This is the callback routine to write a character row of dots. The GVC 
*   object contains the pointer to the font data, the character color and the 
*   background color. Based on the font bit values the pixels pointed to by the 
*   screen memory will be set to character color if the font bit is set. The
*   pixel will be set to the background color if the font bit is 0  
*          
*
*****************************************************************************/
static void GVC::charr(uint8 far * addr,uint16 width,uint16 xoff,uint16 yoff,GVC * ob)
{
	int16	fseg = ob->m_cfontseg;
	int16	foff = ob->m_cfontoff;
	int16	cchar = ob->m_ccolor;
	int16	bclr = ob->m_cbgcolor;
	_asm
	{
		push	es
		push	si
		push	di
		push	cx
		push	bx

	   	mov		es,fseg
		mov		si,foff
	   	mov		bx,yoff
	   	mov		al,es:[si][bx]	   ; get the current row of dots
		mov		cx,width
	   	les		di,addr;
		clc
chrloop:		
		mov		bl,byte ptr bclr 
		rcl		al,1
		jnc		stbk
		mov		bl,byte ptr cchar
stbk:		
		push	ax
		mov		al,bl
		stosb
		pop		ax
		loop	chrloop

		pop		bx
		pop		cx
		pop		di
		pop		si
		pop		es
	}
}
/*****************************************************************************
*	processRect: input: Callback pointer to a fill function
*                       screen x,y locations, sizes
*
*	This routine Handles the video bank switching logic for the rectangle fill
* and character generator functions. These callback functions take a far mem
* pointer, a width, x and y offsets from the top level request and a reference 
* to this GVC object.
*
* The FillRect callback does a simple memory set of the width with the 
* requested color. The callback gets called onc for each screen row within the 
* rectangle 
* DrawChar looks up the font data for the character. The callback uses the 
* font data and the y offset to set the dots in memory for the width of 
* character cell. The allack gets called once for each row of the character.  
*
*****************************************************************************/
void GVC::processRect(void (callbk(uint8 far *, uint16,uint16,uint16, GVC * )),
                             int xloc, int yloc, int xsiz, int ysiz)
{
	int16 i;
	int16 lines;

	int16 x1 = xloc;
	int16 x2 = xloc + xsiz - 1;
	int16 y1 = yloc;
	int16 y2 = yloc + ysiz - 1;

	int16 rowoff=0;
	int16 coloff=0;

	int32 offset;
	int32 startBank;

	int32 endOffset;
	int32 endBank;

	uint8 far *address;

	if(x1 < 0)
	{
    	coloff=abs(x1);
        x1 = 0;
	}
	if(x2 > m_maxx)
	{
        x2 = m_maxx;
	}
	if(y1 < 0)
	{
		rowoff = abs(y1);
        y1 = 0;
	}
	if(y2 > m_maxy)
	{
        y2 = m_maxy;
	}
	if (y2 < y1 || x2 < x1)
	{
        return;
	}

	xsiz = x2 - x1 + 1;
	offset = ((int32)y1 * (int32)m_vmi.width) + (int32)x1;
	startBank = (offset >> 16) + m_activePageOffset;
	endOffset = ((int32)y2 * (int32)m_vmi.width) + (int32)x2;
	endBank = (endOffset >> 16) + m_activePageOffset;

	if (startBank != m_currentBank)
	{
        m_currentBank = startBank;
        SetVBankAAddr(m_currentBank);
	}
	offset &= 0xffffL;
	if (startBank == endBank)
	{
        address = (uint8 far *) MK_FP(0xa000, (int)offset);

        for (i = y1; i <= y2; i++)
        {
   			callbk(address, xsiz,coloff,rowoff,this);
	        address += m_vmi.width;
			rowoff++;
        }
	}
	else
	{
        ysiz = y2 - y1 + 1;
        while (ysiz > 0)
        {
        	uint32 start;
            lines = (0x10000L - offset) / m_vmi.width;
            lines = __min(lines, ysiz);
            ysiz -= lines;
        	for (i = 0; i < lines; i++)
        	{
                callbk((uint8 far *) MK_FP(0xa000, (uint16) offset),xsiz,coloff,rowoff,this);
                offset += m_vmi.width;
				rowoff++;
        	}
        	if (ysiz > 0)
        	{
                ysiz--;
                start = 0x10000L - offset;
                if (start >= xsiz)
                {
            	    callbk((uint8 far *) MK_FP(0xa000, (uint16) offset),xsiz,coloff,rowoff,this);
                	m_currentBank++;
					rowoff++;
                	SetVBankAAddr(m_currentBank);
                }
                else
                {
                	callbk((uint8 far *) MK_FP(0xa000, (uint16) offset), start,coloff,rowoff,this);
                	m_currentBank++;
                	SetVBankAAddr(m_currentBank);
					rowoff++;
                	callbk((uint8 far *) MK_FP(0xa000, (uint16) 0), xsiz - start,coloff,rowoff,this);
                }
        	}
        	offset += m_vmi.width;
        	offset &= 0xffffL;
       	}
  	}
}
/*****************************************************************************
*
*
*****************************************************************************/

int GVC::RectCpy(int16 xloc,int16 yloc, GBitmap* pBitmap)
{
 	if( pBitmap == NULL || pBitmap->m_pBits == NULL)
	{
		return -1;
	}
	m_bmp = pBitmap;
	processRect(bitcpy, (int)xloc, (int)yloc,  pBitmap->GetWidth(),  pBitmap->GetHeight());
	return 0;
}
static void GVC::bitcpy(uint8 far * addr,uint16 width,uint16 xoff,uint16 yoff,GVC * ob)
{
	uint16 nHeight = ob->m_bmp->GetHeight()-yoff;
	uint8 * pDstLine = (uint8*) ob->m_bmp->m_pBits;
	pDstLine += xoff + yoff * ob->m_bmp->GetWidth();
	uint8 far * pSrc = addr;
	uint8* pDest = pDstLine;
	for (int x = 0; x < width; x++)
	{
		*pDest = *pSrc;
		pDest ++;
		pSrc++;
	}
}

/*****************************************************************************
*
*
*****************************************************************************/

int GVC::lBlt(int16 xloc,int16 yloc, GBitmap* pBitmap, uint16 TranspColor)
{
 	if( pBitmap == NULL || pBitmap->m_pBits == NULL)
	{
		return -1;
	}
	m_tcolor = TranspColor;
	m_bmp = pBitmap;
	processRect(bitblt, (int)xloc, (int)yloc,  pBitmap->GetWidth(),  pBitmap->GetHeight());
	return 0;
}

static void GVC::bitblt(uint8 far * addr,uint16 width,uint16 xoff,uint16 yoff,GVC * ob)
{
	uint16 nHeight = ob->m_bmp->GetHeight()-yoff;

	uint8 * pSrcLine = (uint8*) ob->m_bmp->m_pBits;

	pSrcLine += xoff + yoff * ob->m_bmp->GetWidth();

	if (ob->m_tcolor == 0xFFFF)
	{
		uint8 far * pDest = addr;
		uint8* pSrc = pSrcLine;
		for (int x = 0; x < width; x++)
		{
			*pDest = *pSrc;
			pDest ++;
			pSrc++;
		}
	}
	else
	{
		uint8 far * pDest = addr;
		uint8 * pSrc = pSrcLine;
		for (int x = 0; x < width; x++)
		{
			if (*pSrc != ob->m_tcolor)
			{
				*pDest = *pSrc;
			}
			pDest ++;
			pSrc++;
		}
	}

}
int	GVC::enableCursor()
{
	if(m_cursor.init(300,300,bcursor,88) == 0)
	{
		m_cursor.show(300,300,this);
		return 0;
	}
	return -1;
}

void GCursor::show(uint16 xloc,uint16 yloc,GVC * gvc)
{
	gvc->RectCpy(xloc,yloc,&m_screen);
	m_curx = xloc;
	m_cury = yloc;
	gvc->lBlt(xloc, yloc, &m_cursor, m_tcolor)

}
void GCursor::erase(GVC * gvc)
{



}
void GCursor::move(uint16 newx,uint16 newy,GVC * gvc)
{


}
