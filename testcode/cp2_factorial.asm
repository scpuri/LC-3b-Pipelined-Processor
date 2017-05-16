ORIGIN 4x0000
SEGMENT CodeSegment:

	; Load initials
	ADD R1, R0, 5		; Number to factorial
	ADD R3, R0, 1
	ADD R6, R0, -1

; while ((R1--) != 0) { R3 *= R1 }
Loop:
	; R3 *= R1
	ADD R2, R1, R0
	BRnzp Multiply
DoneMultiply:	ADD R3, R4, R0
	; Move loop along  (R1--)
	ADD R1, R1, R6
	BRp Loop

	; We are done then (result is in R3 and R4)
	BRnzp Halt


; Multiply R2 and R3 and place the result in R4
; Also trashes R5
Multiply:
	; Set R4 to 0, R5 to -1
	ADD R4, R0, 0
	ADD R5, R0, -1

	; Add R3 to R4 R2 times
	MultiplyLoop:
		ADD R4, R4, R3
		ADD R2, R2, R5
		BRp MultiplyLoop

	; Return
	BRnzp DoneMultiply
		

; Halt when done
Halt:
	BRnzp Halt

