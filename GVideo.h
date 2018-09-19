/*****************************************************************************
*  GVideo -
*
*       Copyright 2005 Greg Honsa
*
*
*****************************************************************************/
#include "gtypes.h"
typedef struct
{
    char vesa[4];
    uint8 minorMode;
    uint8 majorMode;
    char _far *vendorName;
    uint32 capabilities;
    uint16 _far *modes;
    uint16 memory;
    char reserved_236[236];
} VBEINFO;


typedef struct
{
    uint16 modeAttr;
    uint8 bankAAttr;
    uint8 bankBAttr;
    uint16 bankGranularity;
    uint16 bankSize;
    uint16 bankASegment;
    uint16 bankBSegment;
    uint32 posFuncPtr;
    uint16 bytesPerScanLine;
    uint16 width;
    uint16 height;
    uint8 charWidth;
    uint8 charHeight;
    uint8 numberOfPlanes;
    uint8 bitsPerPixel;
    uint8 numberOfBanks;
    uint8 memoryModel;
    uint8 videoBankSize;
    uint8 imagePages;

    uint8 reserved_1;

    uint8 redMaskSize;
    uint8 redFieldPos;
    uint8 greenMaskSize;
    uint8 greenFieldPos;
    uint8 blueMaskSize;
    uint8 blueFieldPos;
    uint8 rsvdMaskSize;
    uint8 rsvdFieldPos;
    uint8 DirectColorInfo;

    uint8 reserved_216[216];

} MODEINFO;
//---------------------------------------------------
//
// Color palette addresses
//

#define PAL_WRITE_ADDR (0x3c8)      // palette write address
#define PAL_READ_ADDR  (0x3c7)      // palette write address
#define PAL_DATA       (0x3c9)      // palette data register

typedef struct
{
    uint16 red;
    uint16 green;
    uint16 blue;
} vgaColor;

#ifndef GVIDEO
// int 10 bios  function prototypes

extern int GetVBEInfo(VBEINFO *);
extern int GetVModeInfo(int16 mode, MODEINFO *infoPtr);
extern int SetVMode(int16 mode);
extern int GetVMode(int16 *mode);
extern int GetFont(uint16 * fwidth, uint16 * fseg, uint16 * foff);
extern int SetVDisplayStart(uint16 pixel, uint16 line);
extern int SetVBankAAddr(uint16 addr);
extern void  memset(uint16 pseg, uint16 poff,uint16 val, uint16 len); 

#endif


