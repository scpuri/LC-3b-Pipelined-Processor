ORIGIN 4x0000
SEGMENT  CodeSegment:

	;; Various TRAP tests
	;; Assumes LDR, BR, NOT, ADD, LEA, JMP are working
	;; R3 contains test failure number (if 0 then no test failed)

TEST_1: ;; Basic Test 1: See if it works
	ADD R3, R3, 1
	TRAP t1
	
	;; Compare its value
	LEA R4, TEST1
	LDR R2, R4, 0
	NOT R2, R2
	ADD R2, R2, 1
	ADD R1, R1, R2
	BRnp DONE

SUCCESS:
	;; All tests passed
	ADD R3, R0, R0

DONE: BRnzp DONE

TEST1: DATA2	4x1

t1: DATA2	trap1

trap1:
	ADD R1, R1, 1 
	RET
