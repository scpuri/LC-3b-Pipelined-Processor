ORIGIN 4x0000
SEGMENT CodeSegment:
        ADD R2, R0, 2
        ADD R4, R0, 4 
        LDR R1, R0, GOOD
        LDR R3, R0, GOOD
        ADD R0, R0, 2
        LDR R5, R0, BAD ; Should still be 600D
        ADD R0, R0, -4
        LDR R6, R0, WORSE ; Should also still be 600D
        BRnzp -1

LOOP:   BRnzp LOOP
BAD:    DATA2 4xBADD
GOOD:   DATA2 4x600D
WORSE:  DATA2 4xBEEF

