ORIGIN 4x0000
SEGMENT  CodeSegment:
	ADD R3, R3, Subroutine
	JSRR R3
	;; If successful, R1 will equal 5 and this will halt forever
Done:	JMP R2

Subroutine:
	ADD R1, R1, 2
	ADD R2, R2, Done
	ADD R1, R1, 3
	RET
