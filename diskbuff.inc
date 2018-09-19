;*****************************************************************************
;  DiskBuff
;  Copyright, 2005 Greg Honsa
;*****************************************************************************
; Always link last, this is not loaded from disk
;
;   --- dskbuffer - used for primary partitions ---
;
extrn dskbuffer:near ptr byte
extrn pte0:near
extrn pte1:near
extrn pte2:near
extrn pte3:near

extrn dskbuffer1:near ptr byte 
extrn pte10:near
extrn pte11:near
extrn pte12:near
extrn pte13:near
extrn ptsig:near ptr word

extrn dskbuffer2:near
extrn ptsig2:near ptr word 
 