         XC    OFF
         XC
         REL
         DSK   DRAW.L

* Module for rendering and encoding a drawing.

         PUT   equiv
         USE   macros

* imports from ENCODE

         DO    _pics/3
doEncode EXT
         FIN

* imports from DECODE

         DO    _pics/2         
doDecode EXT
         FIN

* imports from CORE

         DO    _pics
setHCurs EXT
setVCurs EXT
plot     EXT
lineTo   EXT
trap     EXT
stroke   EXT
         FIN

* jmp table for execution
exeTbl   DA    exEnd,exEnd,exEnd
         DO    _pics
         DA    exCurs,plot,exLineTo,trap,exStroke
         FIN

* encode and/or execute command X.
* MODE determines action.
encExe   ENT
         DO    _pics/3
         LDA   MODE
         AND   #%01000000
         BEQ   :exe
         PHX
         JSR   doEncode
         PLX
         FIN
:exe     LDA   MODE
         AND   #%00100000
         BNE   exEnd
         TXA
         ASL
         TAX
         JMP   (exeTbl,X)

exEnd    RTS

         DO    _pics

exCurs   JSR   setHCurs
         JMP   setVCurs

exLineTo LDA   x1
         LDX   x1+1
         LDY   y1
         JMP   lineTo

exStroke LDX   y1
         JMP   stroke

         FIN

         DO    _pics/2

* Render a binary coded drawing with offset DX,X00.
* Execute a maximum of `countdwn` commands.
draw     ENT
         LDA   countdwn
         BNE   :go
         LDA   countdwn+1
         BNE   :go
         RTS
:go      JSR   doDecode
         LDA   MODE
         AND   #%00000111
         BEQ   :fin
         TAX
         ph16  DX
         JSR   encExe
         pl16  DX
         dec16 countdwn
         JMP   draw
:fin     RTS

countdwn ENT
         HEX   00,00

         FIN
