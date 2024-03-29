         XC    OFF
         XC
         REL
         DSK   DRAW.L

* Module for rendering and encoding a drawing.

         PUT   equiv

* imports from ENCODE

         DO    _builder
doEncode EXT
         FIN

* imports from CORE

setHCurs EXT
setVCurs EXT
plot     EXT
lineTo   EXT
trap     EXT
stroke   EXT

* encode and/or execute command X.
* MODE determines action.
encExe   ENT
         DO    _builder
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

exCurs   JSR   setHCurs
         JMP   setVCurs

exLineTo LDA   x1
         LDX   x1+1
         LDY   y1
         JMP   lineTo

exStroke LDX   y1
         JMP   stroke

* jmp table for execution
exeTbl   DA    exEnd,exEnd,exEnd,exCurs,plot,exLineTo,trap,exStroke