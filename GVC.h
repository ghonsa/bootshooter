/*****************************************************************************
*  GVC - video context
*
*       Copyright 2005 Greg Honsa
*
*
*****************************************************************************/
#define GVCDEFINED 1
#include "GVideo.h"

class GBitmap
{
	friend class GVC;
	friend class GCursor;
public:
	int GetWidth()
	{
		return m_xsiz;
	}
	int GetHeight()
	{
		return m_ysiz;
	}
	// default constructor
	GBitmap()
	{
		m_pBits = 0;
		m_xsiz = 0;
		m_ysiz = 0;
	}
	// destructor
	~GBitmap()
	{
		delete m_pBits;
	}
protected:

	uint8 * m_pBits;		// native bits
	uint16	m_xsiz;
	uint16	m_ysiz;
};
class GCursor
{
	friend class GVC;
	GCursor()
	{
		m_ccurx = 0;
		m_ccury = 0;
		m_validCursor = 0;

	}
	int init(int16 xsiz,int16 ysiz,uint8* pbits, uint16 tcolor);
	void show(GVC * gvc);
	void show(uint16 xloc,uint16 yloc,GVC * gvc);
	void erase(GVC * gvc);
	void move(uint16 newx,uint16 newy,GVC * gvc);
  	uint16 m_tcolor;
	uint16 m_ccurx;
	uint16 m_ccury;
	GBitmap	m_cursor;
	GBitmap m_screen;
	int8 	m_validCursor;

};



class GVC
{
public:
        GVC();
        virtual ~GVC();
        int Create(int vidMode);
        Restore();
        ClearV(int color);
        int GetNumPages();
		int16 GetMaxX(){return m_maxx;};
		int16	GetMaxY(){return m_maxy;};
        int SetActivePage(int page);
        void SetVisiblePage(int page);
        int Pixel(uint16 xloc,uint16 yloc, uint16 color);
        int FillRect(int16 xloc,int16 yloc,int16 xsiz, int16 ysiz,int16 color);
        int DrawRect(int16 xloc,int16 yloc,int16 xsiz, int16 ysiz,int16 color); 
        int DrawChar(int16 xloc,int16 yloc,char val,int16 color,int16 bgcolor);
        int DrawLine(int16 xstart, int16 ystart, int16 xend, int16 yend, int16 color);
		int lBlt(int16 xloc,int16 yloc, GBitmap* pBitmap, uint16 TranspColor);
		int RectCpy(int16 xloc,int16 yloc, GBitmap* pBitmap);
		void eraseCursor();
		void showCursor();
		int	enableCursor();
		void moveCursor(int16 xoff,int16 yoff,int16 * xpos,int16* ypos);

        DrawString(int16 xloc,int16 yloc,char* val,int16 color,int16 bgcolor);
        //void * CreateWindow(int xloc, int yloc, int xsiz, int ysiz,int color, int bgcolor); 
        //void * CreateButton(int xloc, int yloc, int xsiz, int ysiz,int color, char * label);

private:
		void processRect(void (callbk(uint8 far *,uint16,uint16,uint16,GVC *)),int xloc, int yloc, int xsiz, int ysiz);
		static void fillr(uint8 far * addr, uint16 width,uint16 xoff,uint16 yoff, GVC* ob);
		static void charr(uint8 far * addr, uint16 width,uint16 xoff,uint16 yoff, GVC* ob);
		static void bitblt(uint8 far * addr, uint16 width,uint16 xoff,uint16 yoff, GVC* ob);
		static void bitcpy(uint8 far * addr, uint16 width,uint16 xoff,uint16 yoff, GVC* ob);

        VBEINFO         m_vbi;          // video bios info
        MODEINFO        m_vmi;          // video mode info
		
		int16		m_rctcolor;
        int16       m_origMode;
        int16		m_currentMode; 
        int16		m_currentBank; 
        int16       m_banksPerPage;
        int16       m_activePage; 
        int16       m_activePageOffset; 
        int16       m_visiblePage;     
        int16       m_error;                        
        int16       m_maxx;                 
        int16       m_maxy;                 
        int16       m_vwidth;               
        int16       m_vheight;
        uint16   	m_fntwidth;              
        uint16       m_fontSeg;              
        uint16       m_fontOff;              
public :
		uint16 		m_cfontseg;
		uint16 		m_cfontoff;
		int16		m_ccolor;
		int16		m_cbgcolor;
		GBitmap *	m_bmp;
		int16		m_tcolor;
		GCursor     m_cursor;
};



