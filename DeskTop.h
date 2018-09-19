#include "driveWnd.h"
class DeskTop :public GWindow
{
public:
	DeskTop();
	virtual ~DeskTop();
	void Create();
	void draw(); 
	DrawChar(int xloc,int yloc,char val,int color,int bgcolor);
	void AddDrive(DriveInfo * pdrv);
	int checkChar(char c);
	void processMsg(MSG m);
	driveWnd * drives[20];

} ;