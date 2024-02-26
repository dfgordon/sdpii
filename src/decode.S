         XC    OFF
         XC
         REL
         DSK   DECODE.L

* subroutines for decoding a picture.
* this is nontrivial since we have an unaligned bitstream.

         PUT   equiv
         USE   macros

rdBits   EXT
resmBits EXT
suspBits EXT
seek     EXT

closDc   inc16 cmdCount
         RTS

resmg    ENT
         mkptr decoder;zptr
         JMP   resmBits

suspg    ENT
         mkptr decoder;zptr
         JMP   suspBits

* seek by X00 commands.
* if stream=0 seek from current position.
* sets zptr to the decoder descriptor.
seekg    ENT
         mkptr decoder;zptr
         cp16  cmdCount;prod
         JSR   seek
         cp16  prod;cmdCount
         RTS

* return command count in Y + 256*A
tellg    ENT
         LDY   cmdCount
         LDA   cmdCount+1
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

* decode command code
dcCmd    ENT
         LDX   #4
         JSR   rdBits
         RTS

* decode color
dcColor  ENT
         LDX   #8
         JSR   rdBits
         STA   CLRBAS1
         LDX   #8
         JSR   rdBits
         STA   CLRBAS2
         JSR   closDc
         RTS

* decode mode
dcMode   ENT
         LDX   #8
         JSR   rdBits
         STA   MODE
         JSR   closDc
         RTS

* decode plot (or curs) to X0,Y0
dcPlot   ENT
         JSR   getX0
         JSR   getY
         STA   Y0
         JSR   closDc
         RTS

* decode lineTo to A + 256*X,Y
dcLineTo ENT
         JSR   getAX
         PHA
         PHX
         JSR   getY
         PHA
         JSR   closDc
         PLY
         PLX
         PLA
         RTS

* decode hline to X0,A,X,Y0
dcHline  ENT
         JSR   getX0x1
         PHA
         PHX
         JSR   getY
         STA   Y0
         JSR   closDc
         PLX
         PLA
         RTS

* decode trapezoid to X0,x1,x2,x3,Y0,y1
dcTrap   ENT
         JSR   getX0x1
         JSR   getx2x3
         JSR   getY
         STA   Y0
         JSR   getY
         STA   y1
         JSR   closDc
         RTS

* decode stroke to X0,Y0,X
dcStroke ENT
         JSR   getX0
         JSR   getY
         STA   Y0
         LDX   #4
         JSR   rdBits
         TAX
         JSR   closDc
         RTS

illQ     LDX   #ILLQTY
         JMP   DOERR

* following 5 bytes are bitstream struct:
* bytePtr(2),lookahead,lookbehind,bitPtr
decoder  ENT
         DS    5
cmdCount HEX   00,00
