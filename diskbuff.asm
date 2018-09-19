;*****************************************************************************
;  DiskBuff
;  Copyright, 2005 Greg Honsa
;*****************************************************************************
; Always link last, this is not loaded from disk
;
;   --- dskbuffer - used for primary partitions ---
;
include pte.inc

_Text SEGMENT PUBLIC USE16
  assume CS:_Text, DS:_Text

public dskbuffer 
public pte0
public pte1
public pte2
public pte3

dskbuffer db  01beh dup(?)
pte0	PARTITION_TABLE_ENTRY <?>
pte1	PARTITION_TABLE_ENTRY <?>
pte2	PARTITION_TABLE_ENTRY <?>
pte3	PARTITION_TABLE_ENTRY <?>
		dw	?
	db 16 dup(0)

;
;   --- dskbuffer - used for extended partitions ---
;
public dskbuffer1 
public pte10
public pte11
public pte12
public pte13
public ptsig

public dskbuffer1
dskbuffer1 db  01beh dup(?)
pte10	PARTITION_TABLE_ENTRY <?>
pte11	PARTITION_TABLE_ENTRY <?>
pte12	PARTITION_TABLE_ENTRY <?>
pte13	PARTITION_TABLE_ENTRY <?>
ptsig	dw	?
	db 16 dup(0)

;
;   --- dskbuffer2 - used for extended partitions checks ---
;

public dskbuffer2
public ptsig2

dskbuffer2 db  510 dup(?)
ptsig2	dw	?
	db 16 dup(0)


_Text ENDS
	END	
