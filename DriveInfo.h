//;***********************************************************
//;  Copyright 2005 Greg Honsa
//;
//;***********************************************************
#ifndef DRVINFOINC
#define DRVINFOINC 1

#include "gtypes.h"
typedef struct 
{ 
	uint8	bte_bootable;
	uint8 	bte_starthead;
	uint16 	bte_startsector;	     
	uint8	bte_system;
	uint8	bte_endhead;
	uint16	bte_endsector;
	uint32	bte_relativesector;
	uint32	bte_totalsector;
} PARTITION_TABLE_ENTRY;

typedef struct
{
	uint8	fill[446];
	PARTITION_TABLE_ENTRY pte[4];
	uint16	ptsig;
} MBR;


typedef struct PARTITION_INFOt
{
  	PARTITION_TABLE_ENTRY	PIpte;
	uint32	PIStartLBA;
	uint32	PIEndLBA;
	uint8	PIbootable;
	uint8	PIDrive;
	uint8	PIExtended;
	uint8   PIInExtended;
	uint8   PIActive;
   	PARTITION_INFOt * PIEParts[4];
} PARTITION_INFO ;
typedef struct
{
	uint16		BDTCylinders;
	uint8		BDTHeads;
	uint16		r1;
	uint16		BDTPrecomp;
	uint8		BDTECC;
	uint8		BDTCtrl;
	uint16		r2;
	uint16		r3;
	uint16		BDTLanding;
	uint8		BDTSectors;
	uint8		r4;
} BiosDrvTab; 

typedef struct
{
	uint16		EBDTBuffSz;
	uint16		EBDTInfo;
	uint32		EBDTCylinders;
	uint32		EBDTHeads;
	uint32		EBDTSectors;
	uint32		EBDTTotSect;
	uint32		EBDTTotSect1;
	uint16		EBDTSectTrk;
	uint32		EBDTEDD;
} ExtBiosDrvTab ;

#define PTE_BOOTABLE  0x80
#define PTE_EXTENDED  0x0AA

//
// --- partition types
//
#define FAT12   0x01 	// FAT12 primary parttion (fewer than 32,680 sectors in the volume) 
#define XENIXR	0x02 	// Xenix root
#define XENIXU  0x03 	// Xenix usr
#define FAT16 	0x04 	// FAT16 partition or logical drive ( 16 MB) 
#define EXTEND  0x05 	// Extended partition 
#define BGFAT16	0x06 	// BIGDOS FAT16 partition or logical drive (33 mb)  
#define NTFS	0x07 	// Installable File System (NTFS partition or logical drive) 
#define AIXBOOT 0x08 	// AIX boot partition
#define AIXDATA 0x09 	// AIX data
#define OS2BOOT 0x0A 	// OS/2 boot partition
#define FAT32	0x0B 	// FAT32 partition or logical drive 
#define BFAT32	0x0C 	// FAT32 partition or logical drive using BIOS INT 13h extensions 
#define BFAT16	0x0E 	// BIGDOS FAT16 partition or logical drive using BIOS INT 13h extensions 
#define BEXTEND 0x0F 	//  Extended partition using BIOS INT 13h extensions 
#define EISA	0x12 	// EISA partition or OEM partition 
#define DYNVOL	0x42 	// Dynamic volume 
#define LINUXSW 0x82 	// Linux swap partition
#define LINUXRT 0x83 	// Linux native partition
#define POWMAN  0x84 	// Power management hibernation partition 
#define MDFAT16	0x86 	// Multidisk FAT16 volume created by using Windows NT 4.0 
#define MDNTFS  0x87 	// Multidisk NTFS volume created by using Windows NT 4.0 
#define HIB		0x0A0 	// Laptop hibernation partition 
#define DELL	0x0DE 	// Dell OEM partition 
#define IBM		0x0FE 	// IBM OEM partition 
#define GPT		0x0EE 	// GPT partition  
#define EFI		0x0EF 	// EFI System partition on an MBR disk 

void txtout(char * txt);
void hexout (uint16 val);


class DriveInfo
{
public:
	DriveInfo();
	virtual ~DriveInfo();
	static uint8	GetNumDrives();
	void 	CollectInfo(uint8 drvid);
	void	GetPartitionTables();
	void 	CheckPartition( PARTITION_INFO  ppi[4]);
	uint8	DIid;
	uint8	DIHeads;		
	bool	DIBiosExt;
	uint8	DISectors;	
	uint8	rsv;	
	uint16	DICylinders;
	uint32	DIFreeSect;
	uint32	DITotSect;
   	uint32	DIExtSize1;
   	uint32	DIExtSize;
   	PARTITION_INFO  * DIPartTab[4];
//private:
 	uint16 segs;
	uint8 	inExtended;
	uint32 	partoffset;
	uint8	partdepth;
	MBR * 	sectptr;

	int DeletePartition(PARTITION_INFO * pis);
	int CreatePartition(uint32 blocks,uint16 type,int Verify);
	uint16 VerifyPartition(PARTITION_INFO* ppti );
	
	PARTITION_INFO* PTFindFree();
	uint32 getStartLBA(uint32 blocks);
	int CommitPTable();

};

#endif