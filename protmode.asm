;
;
;

;
;	build an IDT for all hardware interrupts.
;   point to code that just thunks down to 16 bit real mode
;
;	for software interrupts, pass all down as well for now. 
;   later we will special case the bios disk int 13 and video int 10
;
;	the thunk code will need to save off the pm state and install 
;   a rm state