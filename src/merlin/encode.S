         XC    OFF
         XC
         REL
         DSK   ENCODE.L

* subroutines for encoding a picture.
* this is all conditional assembly.

         PUT   equiv
         USE   macros

         DO    _pics/3

* imports from BITSTREAM

stBits   EXT
clsBits  EXT
resmBits EXT
chkpBits EXT
seek     EXT

* main interface, encode command indexed by X.
* update cmdIdx and checkpoint stream record.
doEncode ENT
         JSR   resmp
         TXA
         PHA
         LDX   #3
         JSR   stBits
         PLA
         ASL
         TAX
         JMP   (enTable,X)
closEn   inc16 cmdIdx
         JSR   chkpp
         RTS

resmp    ENT
         mkptr encoder;zptr
         JMP   resmBits

chkpp    ENT
         mkptr encoder;zptr
         JMP   chkpBits

* seek by X00 commands.
* if stream=0 seek from current position.
* sets zptr to the decoder descriptor.
seekp    ENT
         mkptr encoder;zptr
         cp16  cmdIdx;prod
         JSR   seek
         cp16  prod;cmdIdx
         RTS

* return command count in Y + 256*A
tellp    ENT
         LDY   cmdIdx
         LDA   cmdIdx+1
         RTS

* pack 10-bit coord from A + 256*X.
setAX    PHX
         LDX   #8
         JSR   stBits
         LDX   #2
         PLA
         JSR   stBits
         RTS

* encode end of drawing (nothing to add)
enEnd    JMP   clsBits    ; no closeEn

* encode the color currently at CLRBAS1,2
enColor  LDX   #8
         LDA   CLRBAS1
         JSR   stBits
         LDX   #8
         LDA   CLRBAS2
         JSR   stBits
         JMP   closEn

* encode XOR bit from MODE
enMode   LDX   #1
         LDA   MODE
         ROL
         ROL
         JSR   stBits
         JMP   closEn

* encode set cursor or plot at X0,Y0.
enCurs   LDA   X0
         LDX   X0+1
         JSR   setAX
         LDX   #8
         LDA   Y0
         JSR   stBits
         JMP   closEn

* encode line to x1,y1
enLineTo LDA   x1
         LDX   x1+1
         JSR   setAX
         LDX   #8
         LDA   y1
         JSR   stBits
         JMP   closEn

* encode trapezoid
* upper segment is X0,x1,Y0.
* lower segment is x2,x3,y1
enTrap   LDA   X0
         LDX   X0+1
         JSR   setAX

         LDA   x1
         LDX   x1+1
         JSR   setAX

         LDA   x2
         LDX   x2+1
         JSR   setAX

         LDA   x3
         LDX   x3+1
         JSR   setAX

         LDX   #8
         LDA   Y0
         JSR   stBits
         LDX   #8
         LDA   y1
         JSR   stBits

         JMP   closEn

* encode stroke of brush y1 at X0,Y0.
* brush is already referenced to 0.
enStroke LDA   X0
         LDX   X0+1
         JSR   setAX

         LDX   #8
         LDA   Y0
         JSR   stBits

         LDX   #3
         LDA   y1
         JSR   stBits

         JMP   closEn

* following 5 bytes are bitstream struct:
* bytePtr(2),lookahead,lookbehind,bitPtr
encoder  ENT
         DS    5
cmdIdx   HEX   00,00

enTable  DA    enEnd,enColor,enMode,enCurs,enCurs,enLineTo,enTrap,enStroke

         FIN
