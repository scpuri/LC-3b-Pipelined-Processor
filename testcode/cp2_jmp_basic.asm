ORIGIN 4x0000
SEGMENT  CodeSegment:
	ADD R2, R0, 6
	JMP R2
	ADD R1, R1, 2
label:
	ADD R1, R1, 5
	;; If successful, R1 will equal 5 and this will halt forever
	ADD R2, R2, 4
Done:	JMP R2
