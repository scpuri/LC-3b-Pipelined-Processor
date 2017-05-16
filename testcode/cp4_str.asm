ORIGIN 4x0000
SEGMENT CodeSegment:
        LDR R1, R0, VAL
        STR R1, R0, ADDR1
        ADD R0, R0, 2
        STR R1, R0, ADDR1
        ADD R0, R0, 2
        STR R1, R0, ADDR1
        ADD R0, R0, 2
        STR R1, R0, ADDR1
        ADD R4, R4, R4
        ADD R4, R4, R4
        ADD R4, R4, R4
        ADD R4, R4, R4
        ADD R4, R4, R4

LOOP:   BRnzp LOOP

VAL:    DATA2 4x600D
BUFF:   DATA2 4xCCCC
ADDR1:  DATA2 ?
ADDR2:  DATA2 ?
ADDR3:  DATA2 ?
ADDR4:  DATA2 ?
