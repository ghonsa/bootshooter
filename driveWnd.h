#include "GWindow.h"
#include "DriveInfo.h"
class driveWnd:public GWindow
{
public:
	driveWnd();
	virtual ~driveWnd();
	void Create(uint16 xloc, uint16 yloc,GWindow * parent);
	void draw(); 
	DrawChar(int xloc,int yloc,char val,int color,int bgcolor);
	DriveInfo * di;
	void setDriveInf(DriveInfo * pdi);
	char * getTypeStr(uint8 ostype);
	void displayPartitions( PARTITION_INFO * pis[] );
	int checkChar(char c);
	void processMsg(MSG m);

	GWindow * partwnd;
	GWindow * BootButton;
	GWindow * CPartButton;
	GWindow * DPartButton;
private:
	void createPartition();
	void deletePartition();
	void prevPartition();
	void nextPartition();
	int	 nextExtendPart(int fresh,PARTITION_INFO *  pis[]);
	PARTITION_INFO  * getActive();
	GWindow * modalWnd;

} ;
