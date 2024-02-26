         XC    OFF
         XC
         REL
         DSK   ENCODE.L

* subroutines for encoding a picture.
* this is all conditional assembly.
* encoders usually need to preserve inputs.

         PUT   equiv
         USE   macros

stBits   EXT
resmBits EXT
suspBits EXT
seek     EXT

         DO    _builder

* encode command indexed by X
doEncode ENT
         LDA   record
         BNE   :cont
         RTS
:cont    TXA
         PHA
         LDX   #4
         JSR   stBits
         PLA
         ASL
         TAX
         JMP   (enTable,X)
closEn   inc16 cmdCount
         RTS

resmp    ENT
         mkptr encoder;zptr
         JMP   resmBits

suspp    ENT
         mkptr encoder;zptr
         JMP   suspBits

* seek by X00 commands.
* if stream=0 seek from current position.
* sets zptr to the decoder descriptor.
seekp    ENT
         mkptr encoder;zptr
         cp16  cmdCount;prod
         JSR   seek
         cp16  prod;cmdCount
         RTS

* return command count in Y + 256*A
tellp    ENT
         LDY   cmdCount
         LDA   cmdCount+1
         RTS

* pack 10-bit coord from A + 256*X.
setAX    PHX
         LDX   #8
         JSR   stBits
         LDX   #2
         PLA
         JSR   stBits
         RTS

* encode end of drawing
enEnd    LDA   bitPtr
         AND   #$07
         BEQ   :close
:loop    TAX
         LDA   #$00
         JSR   stBits
:close   RTS              ; no closeEn

* encode the color currently at CLRBAS1,2
enColor  LDX   #8
         LDA   CLRBAS1
         JSR   stBits
         LDX   #8
         LDA   CLRBAS2
         JSR   stBits
         JMP   closEn

* encode mode as current MODE
enMode   LDX   #8
         LDA   MODE
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

* encode horizontal line from X0,Y0 to x1,Y0.
enHline  LDA   X0
         LDX   X0+1
         JSR   setAX
         LDA   x1
         LDA   x1+1
         JSR   setAX
         LDX   #8
         LDA   Y0
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

* encode stroke of brush byt at X0,Y0.
* brush is already referenced to 0.
enStroke LDA   X0
         LDX   X0+1
         JSR   setAX

         LDX   #8
         LDA   Y0
         JSR   stBits

         LDX   #4
         LDA   byt
         JSR   stBits

         JMP   closEn

illQ     LDX   #ILLQTY
         JMP   DOERR

* following 5 bytes are bitstream struct:
* bytePtr(2),lookahead,lookbehind,bitPtr
encoder  ENT
         DS    5
cmdCount HEX   00,00

record   ENT
         HEX   00

enTable  DA    enEnd,enColor,enMode,enCurs,enCurs
         DA    enLineTo,enHline,enTrap,enStroke

         FIN
