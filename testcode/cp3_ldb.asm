ORIGIN 4x0000
SEGMENT CodeSegment:
        LDB R6, R0, LowByte
        LDB R7, R0, HighByte
        LDR R1, R0, Word
LOOP:   BRnzp LOOP

LowByte:        DATA1 4x0D
HighByte:       DATA1 4x60
Word:           DATA2 4xAABB

