;***********************************************************
;  Copyright 2005 Greg Honsa
;
;***********************************************************


VBEINFO struc
   vbesignature 	db "VESA"		; // VBE Signature
   vbeversion		dw	?        	; // VBE Version
   oemstringptr 	dd	?			; // Pointer to OEM String
   capabilities  	db 4 dup (?)   	; // Capabilities of graphics cont.
   videomodeptr 	dd	? 			; // Pointer to Video Mode List
   totalmemory		dw	?			; // number of 64Kb memory blocks
   oemsoftwarerev	dw	?			; // VBE implementation Software revision
   oemvendornameptr	dd	?			; // Pointer to Vendor Name String
   oemproductnameptr dd	?			; // Pointer to Product Name String
   oemproductrevptr	dd	?			; // Pointer to Product Revision String
   reserved 		db 222 dup (?)			; // Reserved for VBE implementation scratch area
   oemdata			db 256 dup (?)	; // Data Area for OEM Strings
VBEINFO	ends

MODEINFO struc

   ;// Mandatory information for all VBE revision

   modeattributes	dw	?			; // Mode attributes
   winaattributes	db	?			; // Window A attributes
   winbattributes	db	?			; // Window B attributes
   wingranularity	dw	?			; // Window granularity
   winsize			dw	?			; // Window size
   winasegment		dw	?			; // Window A start segment
   winbsegment		dw	?			; // Window B start segment
   winfuncptr		dd	?			; // pointer to window function
   bytesperscanline	dw	?			; // Bytes per scan line

   ;// Mandatory information for VBE 1.2 and above

   xresolution		dw	?			; // Horizontal resolution in pixel or chars
   yresolution		dw	?			; // Vertical resolution in pixel or chars
   xcharsize		db	?			; // Character cell width in pixel
   ycharsize		db	?			; // Character cell height in pixel
   numberofplanes	db	?			; // Number of memory planes
   bitsperpixel		db	?			; // Bits per pixel
   numberofbanks	db	?			; // Number of banks
   memorymodel		db	?			; // Memory model type
   banksize			db	?			; // Bank size in KB
   numberofimagepages db ?			; // Number of images
   reserved1		db	?			; // Reserved for page function

   ;// Direct Color fields (required for direct/6 and YUV/7 memory models)

   redmasksize		db	?			; // Size of direct color red mask in bits
   redfieldposition	db	?			; // Bit position of lsb of red bask
   greenmasksize	db	?			; // Size of direct color green mask in bits
   greenfieldposition db	?		; // Bit position of lsb of green bask
   bluemasksize		db	?			; // Size of direct color blue mask in bits
   bluefieldposition db ?			; // Bit position of lsb of blue bask
  rsvdmasksize		db	?			; // Size of direct color reserved mask in bits
   rsvdfieldposition db	?			; // Bit position of lsb of reserved bask   
   directcolormodeinfo db ?			; // Direct color mode attributes

   ;// Mandatory information for VBE 2.0 and above

   physbaseptr		dd	?			; // Physical address for flat frame buffer
   offscreenmemoffset dd ?			; // Pointer to start of off screen memory
   offscreenmemsize dw ?			; // Amount of off screen memory in 1Kb units
   reserved2 db 206 dup (?)			; // Remainder of ModeInfoBlock

MODEINFO ends

VGACOLOR struc
    red		dw	?
    green	dw	?
    blue	dw	?
VGACOLOR ends

