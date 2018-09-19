;***********************************************************
;  Copyright 2005 Greg Honsa
;
;***********************************************************
 include video.inc


VDCONTX	struc
	;
	;	--- function pointers --- 
	;
	Create			dw	?	; Create function pointer
	Destroy			dw	?	; Destroy function
	Clear			dw	?	;
	getNumPages		dw	?	;
    setActivePage	dw	?	;  
    setVisiblePage	dw	?	;
    pixel			dw	?	;	(int16 x, int16 y, int16 color);
    fillRect		dw	?	;  (int16 x, int16 y, int16 width, int16 height, int16 color);
	drawRect		dw	?
	drawChar		dw	?	;	
	drawLine		dw	?	;
	drawString		dw	?	;
	createWindow	dw	?	;
	createbutton	dw	?	;

	vbi			VBEINFO <>
	vmi 		MODEINFO <>
	origMode		dw	?	;
	currentMode		dw	?	;
	currentBank		dw	?	;
	banksPerPage	dw	?	;
	activePage		dw	?	;
	activePageOffset dw ?	;
	visiblePage		dw	?	;
	error			dw	?	;
	maxx			dw	?	;
	maxy			dw	?	;
	vwidth			dw	?	;
	vheight			dw	?	;
	fontSeg			dw	?
	fontOff			dw	?
VDCONTX ends



GWIND	struc
	xorg	dw	?			; x start
	yorg	dw	?			; ystart
	xend	dw	?
	yend	dw	?
	xsiz	dw	?			; size x
	ysiz	dw	?			; size y
	bcolor	dw	?			; background window color
	ccolor	dw	?			; character color
	currx	dw	?			; current character position
	curry	dw	?
GWIND	ends