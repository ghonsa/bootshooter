;***********************************************************
;  Copyright 2005 Greg Honsa
;
;***********************************************************

BOOTABLE equ 1			; set to make a bootable image
OPSIZ macro
	db 66h
endm

;
;** fat type byte defs
;
FAT12 	equ 01h 	;FAT12 primary parttion (fewer than 32,680 sectors in the volume) 
XENIXR	equ 02h		;Xenix root
XENIXU  equ 03h		;Xenix usr
FAT16 	equ 04h 	;FAT16 partition or logical drive ( 16 MB) 
EXTEND  equ 05h 	;Extended partition 
BGFAT16	equ 06h		;BIGDOS FAT16 partition or logical drive (33 mb)  
NTFS	equ 07h		;Installable File System (NTFS partition or logical drive) 
AIXBOOT equ 08h		;AIX boot partition
AIXDATA equ 09h		;AIX data
OS2BOOT equ	0Ah		;OS/2 boot partition
FAT32	equ 0Bh		;FAT32 partition or logical drive 
BFAT32	equ 0Ch		;FAT32 partition or logical drive using BIOS INT 13h extensions 
BFAT16	equ 0Eh 	;BIGDOS FAT16 partition or logical drive using BIOS INT 13h extensions 
BEXTEND equ 0Fh		; Extended partition using BIOS INT 13h extensions 
EISA	equ 12h 	;EISA partition or OEM partition 
DYNVOL	equ 42h 	;Dynamic volume 
LINUXSW equ 82h		;Linux swap partition
LINUXRT equ 83h		;Linux native partition
POWMAN  equ 84h 	;Power management hibernation partition 
MDFAT16	equ 86h 	;Multidisk FAT16 volume created by using Windows NT 4.0 
MDNTFS  equ 87h 	;Multidisk NTFS volume created by using Windows NT 4.0 
HIB		equ 0A0h 	;Laptop hibernation partition 
DELL	equ 0DEh 	;Dell OEM partition 
IBM		equ 0FEh 	;IBM OEM partition 
GPT		equ 0EEh 	;GPT partition  
EFI		equ 0EFh 	;EFI System partition on an MBR disk 

PTE_BOOTABLE EQU 80h
PTE_EXTENDED EQU 0AAh
CYLSEC record Cylinder:10,Sector:6

PARTITION_TABLE_ENTRY struc
	bte_bootable		db	?
	bte_starthead		db	?
	bte_startsector		dw	?	     
	bte_system			db	?
	bte_endhead			db	?
	bte_endsector		dw	?
	bte_relativesector	dd	?
	bte_totalsector		dd	?
PARTITION_TABLE_ENTRY ends

EXT_PARTITION struc
  	EPpte		PARTITION_TABLE_ENTRY <>
	EPStartLBA			dd ?
	EPEndLBA			dd ?
	EPbootable			db ?
	EPDrive				db ?
EXT_PARTITION ends

PARTITION_INFO struc
  	PIpte		PARTITION_TABLE_ENTRY <>
	PIStartLBA			dd ?
	PIEndLBA			dd ?
	PIbootable			db ?
	PIDrive				db ?
	PIExtended			db ?
   	PIEParts			EXT_PARTITION 4 DUP(<>)
PARTITION_INFO	ends
;
;--- drive info
;
DIEXTENDED		equ	055h
DriveInfo	STRUC
	DIid			db	?
	DIHeads			db	?		
	DIExtend		db	?
	DISectors		db	?
					db	?
	DICylinders		dw  ?
	DIFreeSect		dd	?
	DITotSect		dd	?
   	DIExtSize1		dd  ?
   	DIExtSize		dd  ?
   	DIPartTab1		PARTITION_INFO 4 DUP (<>)

DriveInfo	ENDS
;
; --- BIOS disk parameter table ---
;
BiosDrvTab	STRUC
	BDTCylinders	dw	?
	BDTHeads		db	?
					dw	?
	BDTPrecomp		dw	?
	BDTECC			db	?
	BDTCtrl			db	?
					db	?
					dw	?
	BDTLanding		dw	?
	BDTSectors		db	?
					db	?		
BiosDrvTab ENDS
;
; --- BIOS extended disk parameter table
;
ExtBiosDrvTab STRUC
	EBDTBuffSz		dw	?
	EBDTInfo		dw	?
	EBDTCylinders	dd	?
	EBDTHeads		dd	?
	EBDTSectors		dd	?
	EBDTTotSect 	dd	?
	EBDTTotSect1	dd	?
	EBDTSectTrk		dw	?
	EBDTEDD			dd	?				   	
ExtBiosDrvTab ENDS
;
;  --- entended disk address packet
;
ExtBiosDiskAddrPkt STRUC
	EBDAPSz			db	?
	EBDAPres1		db	?
	EBDAPBlocks		db	?
	EBDAPres2		db	?
	EBDAPLowPtr		dw	?
	EBDAPHighPtr	dw	?
	EBDAPLBAlow		dd	?
	EBDAPLBAhigh	dd	?
	EBDAPFlatAdr1	dd	?
	EBDAPFlatAdr2	dd	?
ExtBiosDiskAddrPkt ENDS
	
;
; --- vesa info
;
VgaInfoBlock    STRUC
      VESASignature   db   'VESA'      ; 4 signature bytes 
      VESAVersion     dw   ?           ; VESA version number
      OEMStringPtr    dd   ?           ; Pointer to OEM string
      Capabilities    db   4 dup(?)    ; capabilities of the video environment
      VideoModePtr    dd   ?           ; pointer to supported Super VGA modes
      TotalMemory     dw   ?           ; Number of 64kb memory blocks on board
      Reserved        db   236 dup(?)  ; Remainder of VgaInfoBlock
	  OemData		  db   256 dup(?)  ;
VgaInfoBlock    ENDS
