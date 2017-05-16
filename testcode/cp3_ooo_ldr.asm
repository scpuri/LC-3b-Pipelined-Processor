ORIGIN 4x0000
SEGMENT CodeSegment:
        LDR R0, R0, OFFSET
        LDR R1, R0, BAD
        LDR R2, R0, BAD
        LDR R3, R0, BAD
        LDR R4, R5, GOOD ; Should load first but commit last
LOOP:   BRnzp LOOP

OFFSET: DATA2 4x0002
BAD:    DATA2 4xBADD
GOOD:   DATA2 4x600D
WORSE:  DATA2 4xBEEF

