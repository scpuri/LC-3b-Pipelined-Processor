ORIGIN 4x0000
SEGMENT  CodeSegment:
	ADD R2, R2, 6
	BRn label
	ADD R1, R1, 2
label:
	ADD R1, R1, 5
	;; If successful, R1 will equal 7 and this will halt forever
Done:	BRnzp Done
