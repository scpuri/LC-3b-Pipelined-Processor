ORIGIN 4x0000
SEGMENT  CodeSegment:
	ADD R1, R1, 1		; Executed first
	ADD R2, R1, 2		; Should stall until previous instruction finishes
	ADD R3, R0, 3		; Should be executed second (but is still committed last ;) )
