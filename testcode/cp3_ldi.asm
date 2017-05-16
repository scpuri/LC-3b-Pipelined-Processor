ORIGIN 4x0000
SEGMENT CodeSegment:
        LDI R1, R0, MyPointer
LOOP:   BRnzp LOOP

MyPointer:      DATA2 MyData
MyData:         DATA2 4x600D
