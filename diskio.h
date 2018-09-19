#include "gtypes.h"

typedef struct
{
	uint8		EBDAPSz;
	uint8		EBDAPres1;
	uint8		EBDAPBlocks;
	uint8		EBDAPres2;
	uint16		EBDAPLowPtr;
	uint16		EBDAPHighPtr;
	uint32		EBDAPLBAlow;
	uint32		EBDAPLBAhigh;
	uint32		EBDAPFlatAdr1;
	uint32		EBDAPFlatAdr2;
} ExtBiosDiskAddrPkt;

uint16 ReadExtended( uint32 lba,uint8 drv,void far * buff) ;
uint16 ReadStd( uint8 head, uint8 sector, uint16 cyl, uint8 drv, void far * buff) ;
uint16 WriteExtended( uint32 lba,uint8 drv,void far * buff) ;
uint16 WriteStd( uint8 head, uint8 sector, uint16 cyl, uint8 drv, void far * buff) ;
uint16 VerifyExtended( uint32 lba,uint8 drv) ;
uint16 VerifyStd( uint8 head, uint8 sector, uint16 cyl, uint8 drv) ;

uint16 Boot(uint32 lba, uint8 drv) ;
