#include "GWindow.h"
extern GVC* vidp;

GWindow::GWindow()
{
        m_style=0;
}
GWindow::~GWindow()
{
;
}
void GWindow::Create(int startx,int starty, int sizex, int sizey,int bgcolor, int ccolor ,GWindow* parent)
{
        int tp;
        m_xorg = startx;                // x start
        m_yorg = starty;                // ystart
        m_xend = sizex+startx -8;       // end x
        m_yend = sizey+starty -8;       //
        m_xsiz = sizex;                 // size x
        m_ysiz = sizey;                 // size y
        m_bcolor = bgcolor;             // background window color
        m_ccolor = ccolor;              // character color
        m_currx = 10;                   // current character position within window
        m_curry = 4;                   //
        m_parentW = parent;
        for(tp=0;tp<32;tp++)
        {
                m_zorder[tp] = -1;
                m_children[tp]=0;
        }
}

virtual void GWindow::draw()
{
        int ctr;
        int16 tmpxs,tmpys,tmpxe,tmpye;
        int clr;
        vidp->FillRect(m_xorg,m_yorg,m_xsiz,m_ysiz,m_bcolor);

// highlight the top...
        
        tmpxs=m_xorg;
        tmpys=m_yorg;
        tmpxe=m_xorg+m_xsiz;
        tmpye=tmpys;

        if((m_style & SUNKEN)!=0)
        {
                clr=3;
        }
        else
        {
                clr = 13;
        }
        for(ctr=0;ctr<3; ctr++)
        {
                vidp->DrawLine(tmpxs,tmpys, tmpxe,tmpye,clr++);
                tmpys++;
                tmpye++;
        }
// highlight the right side...

        tmpxs=m_xorg+m_xsiz;
        tmpys=m_yorg;
        tmpxe=tmpxs;
        tmpye=tmpys+m_ysiz;

        if((m_style & SUNKEN)!=0)
        {
                clr=13;
        }
        else
        {
                clr = 3;
        }

        for(ctr=0;ctr<3; ctr++)
        {
                vidp->DrawLine(tmpxs,tmpys, tmpxe,tmpye,clr++);
                tmpys++;
                tmpxs--;
                tmpxe--;
        }
// bottom
        tmpxs=m_xorg;
        tmpys=m_yorg+m_ysiz;
        tmpxe=m_xorg+m_xsiz;
        tmpye=tmpys;
        if((m_style & SUNKEN)!=0)
        {
                clr=13;
        }
        else
        {
                clr = 3;
        }

        for(ctr=0;ctr<3; ctr++)
        {
                vidp->DrawLine(tmpxs,tmpys, tmpxe,tmpye,clr++);
                tmpys--;
                tmpye--;
        }
// left
        
        tmpxs=m_xorg;
        tmpys=m_yorg;
        tmpxe=tmpxs;
        tmpye=tmpys+m_ysiz;

        if((m_style & SUNKEN)!=0)
        {
                clr=3;
        }
        else
        {
                clr = 13;
        }
        for(ctr=0;ctr<3; ctr++)
        {
                vidp->DrawLine(tmpxs,tmpys, tmpxe,tmpye,clr++);
                tmpye--;
                tmpxs++;
                tmpxe++;
        }
        m_currx = 15;                   // current character position within window
        m_curry = 6;                   //

        drawChildren();
}
void GWindow::drawChildren()
{
//
//  --- now draw any children use zorder ---
//
        int     t;
        for(t=MAXCHILD;t>=0;t--)
        {
                if(m_zorder[t] != -1)
                {
                        if(m_children[m_zorder[t]]!=0)
                        {
                                m_topWnd=t;
                                m_children[m_zorder[t]]->draw();
                        }
                }
        }

}
void GWindow::nextWnd()
{
        GWindow * pwnd;
        int cindx;
        if(m_zorder[0] != -1)
        {
                cindx = m_zorder[0];
                if((pwnd = m_children[cindx+1]) !=0)
                {
                        move2Top(pwnd);
                }
                else
                {
                        move2Top(m_children[0]);
                
                }       
        }
}
 
GWindow::DrawChar(int16 xloc,int16 yloc,char val,int16 color,int16 bgcolor)
{
	if(xloc == -1) xloc = m_currx;
    if(yloc == -1) yloc = m_curry;

    xloc += m_xorg;
    yloc += m_yorg;
 
    if(val == 0x0d)
    {
	    m_currx = 10;
        if((m_curry +8 ) < m_yend) m_curry+=8;
    }
    else if(val== 0x0a)
    {
  	  if((m_curry +8 ) < m_yend) m_curry+=8;
    }               
    else
    {
        vidp->DrawChar(xloc,yloc, val,color,bgcolor);
        if((m_currx+=7) >= m_xend)
        {
    	    m_currx = m_xorg+4;
            if((m_curry +8 ) < m_yend) m_curry+=8;
        }
    }
}

GWindow::DrawString(int16 xloc,int16 yloc,char* val,int16 color,int16 bgcolor)
{
	char chr;
    while((chr=*val++)!=0)
    {
    	if(xloc != -1) m_currx = xloc;
        if(yloc != -1) m_curry = yloc ;
        if(chr==0x0a)
        {
        	DrawChar(xloc,yloc,0x0d,color,bgcolor);
        }
        DrawChar(xloc,yloc,chr,color,bgcolor);
        xloc=-1;
        yloc=-1;                
    }       
}

int GWindow::addChild(GWindow * child)
{
        int     t;
        for(t=0;t<MAXCHILD;t++)
        {
                if(m_children[t]==0)
                {
                        m_children[t]=child;
                        add2ZBottom(t);
                        //move2Top(child);
                        return 1;
                }
        }
        return 0;
}
virtual int GWindow::checkChar(char c)
{
        return 0; // not processed      
}
int GWindow::add2ZBottom(char indx)
{
        char tmp;
        int ctr;
        for(ctr =0; ctr<MAXCHILD;ctr++)
        {
                if(m_zorder[ctr]==-1)
                {
                        m_zorder[ctr]=indx;
                        return 0;
                }       
        }
        return -1;
}
int GWindow::move2Top(GWindow * pwnd)
{
        unsigned char tmpin, tmpout;
        int indx = -1;
        int ctr;
        // find index of window ( our handle)
        for(ctr =0; ctr<MAXCHILD;ctr++)
        {
                if(m_children[ctr] == pwnd)
                {
                        indx = ctr;
                        break;
                }       
        }
        if(indx != -1)
        {
                // check if already on top
                if(indx == m_zorder[0])
                {
                        return 0;
                }
                tmpin = m_zorder[0];
                m_zorder[0]=indx;
                m_topWnd=indx;

                for(ctr=1;ctr<MAXCHILD;ctr++)
                {
                        tmpout = m_zorder[ctr]; 
                        m_zorder[ctr] = tmpin;
                        if((tmpout == indx) ||(tmpout == -1))
                        {
                                break; // nothing more to move
                        }
                        m_zorder[ctr] = tmpin;
                        tmpin = tmpout;
                }
                pwnd->draw();
                return 0;
        }
        return -1;
}

int GWindow::inBounds(int x,int y)
{
        if((x >= m_xorg) && (x <= m_xend) && (y >= m_yorg) && (y <= m_yend))
        {
                return 1;
        }
        return 0;
}

void GWindow::moveWindow(int x,int y)
{

        m_xorg = x;             // x start
        m_yorg = y;             // ystart
        m_xend = x+ m_xsiz -8;  // end x
        m_yend = y+ m_ysiz -8 ;         //

}
