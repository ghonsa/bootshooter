#include "diskio.h"
#include "GMouse.h"
#include <i86.h>

extern GMouse * moup;

extern void txtout(char * txt);
#define DREAD 1
#define DWRITE 2
#define DVERF 3 


uint16 diskExtended( uint32 lba,uint8 drv,void far * buff,int op)
{
	union REGS reg;
	struct SREGS sreg;
	ExtBiosDiskAddrPkt ebdap;
	uint16 sss;
	_asm
	{
		mov	ax,ds
		mov	sss,ax
	}
	ebdap.EBDAPSz=16;
	ebdap.EBDAPres1=0;
	ebdap.EBDAPres2=0;
	ebdap.EBDAPBlocks = 1;
	ebdap.EBDAPHighPtr = FP_SEG(buff);
	ebdap.EBDAPLowPtr = FP_OFF(buff);
	ebdap.EBDAPFlatAdr1 =0;
	ebdap.EBDAPFlatAdr2 =0;
	ebdap.EBDAPLBAhigh = 0;
	ebdap.EBDAPLBAlow = lba;
	
	switch (op)
	{
		case DREAD:
			reg.x.ax = 0x4200 ;
			break;
		case DWRITE:
			reg.x.ax = 0x4300 ;
			break;
		case DVERF:
			reg.x.ax = 0x4400 ;
			break;
	}
	
	reg.h.dl = drv;
	reg.x.si= FP_OFF( &ebdap);
	sreg.ds= sss;
	int86x(0x13, &reg, &reg, &sreg);
	return(reg.x.cflag);

}

uint16 ReadExtended( uint32 lba,uint8 drv,void far * buff)
{
	return (diskExtended(lba,drv,buff,DREAD));
}
uint16 WriteExtended( uint32 lba,uint8 drv,void far * buff)
{
	return (diskExtended(lba,drv,buff,DWRITE));
}
uint16 VerifyExtended( uint32 lba,uint8 drv)
{
	return (diskExtended(lba,drv,0,DVERF));
}


uint16 diskStd( uint8 head, uint8 sector, uint16 cyl, uint8 drv, void far * buff,int op) 
{
	union REGS reg;
	struct SREGS sreg;

	switch (op)
	{
		case DREAD:
			reg.x.ax = 0x201 ;
			break;
		case DWRITE:
			reg.x.ax = 0x301 ;
			break;
		case DVERF:
			reg.x.ax = 0x401 ;
			break;
	}
	reg.x.bx = FP_OFF(buff);
	sreg.es = FP_SEG(buff);
	reg.h.dh = head;
	reg.h.dl = drv;

	reg.x.cx = (cyl<<6) +sector;
	int86x(0x13, &reg, &reg, &sreg);
	return(reg.x.cflag);
}


uint16 ReadStd( uint8 head, uint8 sector, uint16 cyl, uint8 drv, void far * buff) 
{
	return( diskStd(head,sector,cyl,drv,buff,DREAD));
}
uint16 WriteStd( uint8 head, uint8 sector, uint16 cyl, uint8 drv, void far * buff) 
{
	return( diskStd(head,sector,cyl,drv,buff,DWRITE));

}
uint16 VerifyStd( uint8 head, uint8 sector, uint16 cyl, uint8 drv) 
{
	return( diskStd(head,sector,cyl,drv,0,DVERF));

}


uint16 Boot(uint32 lba, uint8 drv)
{
	moup->Disable();

	txtout("Try Boot ...");
	if( ReadExtended( lba, drv,MK_FP(0,0x7c00))==0)
	{
		_asm
		{
			mov	dl,drv
			
			db 0EAh
			dw	07c00h
			dw	0
		}
	}
	txtout("Boot Failed!");
	moup->Enable();
	return 0;
}											