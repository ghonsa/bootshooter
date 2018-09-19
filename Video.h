/*****************************************************************************
*  GWindow -
*
*       Copyright 2005 Greg Honsa
*
*
*****************************************************************************/

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
