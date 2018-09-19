/*****************************************************************************
*  GWindow -
*
*       Copyright 2005 Greg Honsa
*
*
*****************************************************************************/
#ifndef GWindowDEFINED
 #define GWindowDEFINED 1
 #ifndef GVCDEFINED
 #include "GVC.H"
 #endif
#include "gmouse.h"
typedef struct 
{
	int	msg;
	int	parm1;
	int parm2;
} MSG;



#define MAXCHILD  32
class GWindow
{
public:
    GWindow();
    virtual ~GWindow();
	void Create(int startx, int starty, int sizex, int sizey,int bgcolor, int ccolor, GWindow * parent);
	virtual void draw();
	DrawChar(int16 xloc,int16 yloc,char val,int16 color,int16 bgcolor);
    DrawString(int16 xloc,int16 yloc,char* val,int16 color,int16 bgcolor);
	int addChild(GWindow * child);
	void setStyle(int style){m_style= style;}
	void	nextWnd();
	void drawChildren();
	void moveWindow(int x,int y);
	virtual char * getAnswer() {return 0;}
	virtual int checkChar(char c);
	virtual char getchr() {return 0;}
	int add2ZBottom(char indx);
	int move2Top(GWindow * pwnd);
	int	inBounds(int x,int y);
	virtual void processMsg(MSG m){};

	int16	m_xorg;		// x start
	int16	m_yorg;		// ystart
	int16	m_xend;		// end x
	int16	m_yend;		//
	int16	m_xsiz;		// size x
	int16	m_ysiz;		// size y
	int16	m_bcolor;	// background window color
	int16	m_ccolor;	// character color
	int16	m_currx;	// current character position
	int16	m_curry;	//
	GWindow * m_parentW;
	GWindow * m_children[MAXCHILD] ;
	GWindow * m_FocusWnd;
	char 	m_zorder[MAXCHILD];
	int		m_style;
	int		m_topWnd;
	MSG 	lastmsg;

};

#define SUNKEN 1
#define RAISED 2
#define BORDER 4
#endif