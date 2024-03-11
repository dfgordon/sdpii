         XC    OFF
         XC
         REL
         DSK   DECODE.L

* subroutines for decoding a picture.
* this is nontrivial since we have an unaligned bitstream.

         PUT   equiv
         USE   macros

* imports from BITSTREAM

rdBits   EXT
resmBits EXT
chkpBits EXT
seek     EXT

* main interface, decode next command.
* update cmdIdx and checkpoint stream record.
* command code is left in MODE bits 0,1,2.
* command parameters are left in ZP.
doDecode ENT
         JSR   resmg
         LDA   MODE
         AND   #%11111000
         STA   MODE
         LDX   #3
         JSR   rdBits
         ORA   MODE
         STA   MODE
         AND   #%00000111
         ASL
         TAX
         JMP   (dcTable,X)
* update count and checkpoint
closDc   inc16 cmdIdx
         JSR   chkpg
         RTS

resmg    ENT
         mkptr decoder;zptr
         JMP   resmBits

chkpg    ENT
         mkptr decoder;zptr
         JMP   chkpBits

* seek by X00 commands.
* if stream=0 seek from current position.
* sets zptr to the decoder descriptor.
seekg    ENT
         mkptr decoder;zptr
         cp16  cmdIdx;prod
         JSR   seek
         cp16  prod;cmdIdx
         RTS

* return command index in Y + 256*A
tellg    ENT
         LDY   cmdIdx
         LDA   cmdIdx+1
         RTS

* unpack 10-bit coord -> A + 256*X.
* includes offset of DX.
getAX    LDX   #8
         JSR   rdBits
         PHA
         LDX   #2
         JSR   rdBits
         TAX
         CLC
         PLA
         ADC   DX
         PHA
         TXA
         ADC   DX+1
         TAX
         PLA
         RTS

* unpack 10-bit coord -> X0
getX0    JSR   getAX
         STA   X0
         STX   X0+1
         RTS

* unpack 10-bit coords -> X0,x1
getX0x1  JSR   getAX
         STA   X0
         STX   X0+1
         JSR   getAX
         STA   x1
         STX   x1+1
         RTS

* unpack 10-bit coords -> x2,x3
getx2x3  JSR   getAX
         STA   x2
         STX   x2+1
         JSR   getAX
         STA   x3
         STX   x3+1
         RTS

* unpack 8-bit coord -> A
getY     LDX   #8
         JSR   rdBits
         CLC
         ADC   X00
         RTS

* decode end
dcEnd    RTS              ; no close

* decode color
dcColor  LDX   #8
         JSR   rdBits
         STA   CLRBAS1
         LDX   #8
         JSR   rdBits
         STA   CLRBAS2
         JMP   closDc

* decode XOR bit into mode
dcMode   ASL   MODE
         LDX   #1
         JSR   rdBits
         ROR
         ROR   MODE
         JMP   closDc

* decode plot (or curs) to X0,Y0
dcPlot   JSR   getX0
         JSR   getY
         STA   Y0
         JMP   closDc

* decode lineTo to x1,y1
dcLineTo JSR   getAX
         STA   x1
         STX   x1+1
         JSR   getY
         STA   y1
         JMP   closDc

* decode trapezoid to X0,x1,x2,x3,Y0,y1
dcTrap   JSR   getX0x1
         JSR   getx2x3
         JSR   getY
         STA   Y0
         JSR   getY
         STA   y1
         JMP   closDc

* decode stroke to X0,Y0,y1
dcStroke JSR   getX0
         JSR   getY
         STA   Y0
         LDX   #3
         JSR   rdBits
         STA   y1
         JMP   closDc

illQ     LDX   #ILLQTY
         JMP   DOERR

* following 5 bytes are bitstream struct:
* bytePtr(2),lookahead,lookbehind,bitPtr
decoder  ENT
         DS    5
cmdIdx   HEX   00,00

dcTable  DA    dcEnd,dcColor,dcMode,dcPlot,dcPlot,dcLineTo,dcTrap,dcStroke
