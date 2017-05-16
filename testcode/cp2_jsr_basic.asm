ORIGIN 4x0000
SEGMENT  CodeSegment:
	JSR Subroutine
	;; If successful, R1 will equal 5 and this will halt forever
Done:	JMP R2

Subroutine:
	ADD R1, R1, 2
	ADD R2, R2, Done
	ADD R1, R1, 3
	RET
