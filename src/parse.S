         XC    OFF
         XC
         REL
         DSK   PARSE.L

* Routines to help with parsing ampersands

         PUT   equiv
         USE   macros

* parse (address,op-count) into (stream,X00)
parsSeek ENT
         JSR   CHKOPN
         JSR   NUMEVL
         JSR   GETADR
         cp16  X00;stream
         JSR   CHKCOM
         JSR   NUMEVL
         JSR   GETADR
         JSR   CHKCLS
         RTS

* parse (address,bit,op-count) from (stream,bitPtr,prod)
parsTell ENT
         JSR   CHKOPN
         JSR   PTRGET
         LDA   VALTYP
         BNE   :err
         LDY   stream
         LDA   stream+1
         JSR   saveInt
         JSR   CHKCOM
         JSR   PTRGET
         LDA   VALTYP
         BNE   :err
         LDA   bitPtr
         JSR   saveByt
         JSR   CHKCOM
         JSR   PTRGET
         LDA   VALTYP
         BNE   :err
         LDY   prod
         LDA   prod+1
         JSR   saveInt
         JSR   CHKCLS
         RTS
:err     JMP   badTyp

* save A in the last variable
saveByt  ENT
         TAY
         LDA   #$00
* save Y + 256*A in the last variable
saveInt  ENT
         JSR   INT2FP
         LDX   VARPNT
         LDY   VARPNT+1
         JSR   MOVMF
         RTS

* get real into X00 and LE Y,A and stash VARPNT to zptr, consumes `(`
stash    JSR   CHKOPN
         JSR   PTRGET
         LDA   VALTYP
         BNE   badTyp
         LDA   VARPNT
         STA   zptr
         LDY   VARPNT+1   ; must use Y
         STY   zptr+1
         JSR   MOVFM
         JSR   GETADR
         RTS
         
* Parse (realvar,aexpr) to A,X.
* Upon return Z = (X==0).
* Then after some transformation, call `saveByt` to update `realvar`.
bitwise8 ENT
         JSR   stash
         CMP   #$00
         BNE   illQ
         JSR   CHKCOM
         JSR   GETBYT
         PHX
         JSR   CHKCLS
         JSR   unstash
         LDA   X00
         PLX
         RTS

* Parse (realvar,aexpr) to prod,fac.
* Then after some transformation, call `saveInt` to update `realvar`.
binary16 ENT
         JSR   stash
         STY   prod
         STA   prod+1
         JSR   CHKCOM
         JSR   NUMEVL
         JSR   GETADR
         STY   fac1
         STA   fac2
         JSR   CHKCLS
unstash  cp16  zptr;VARPNT
         RTS

* Parse text coordinates to X,Y
* and transform to 0-indexing.
* Bounds check if `_bound`.
txtPt    ENT
         JSR   GETBYT
         PHX
         JSR   CHKCOM
         JSR   GETBYT
         TXA
         TAY
         PLX
         DEX
         DEY
         DO    _bound
         CPX   #40
         BCS   illQ
         CPY   #24
         BCS   illQ
         FIN
         RTS

* Parse a signed expression to Y.
* Bounds check if `_bound`.
* If unchecked, the low byte is returned without transformation.
parse_i8 JSR   NUMEVL
         JSR   GETADR
         DO    _bound
         BIT   #%10000000
         BNE   :neg
         CMP   #$00
         BNE   illQ
         BRA   :ok
:neg     CMP   #$FF
         BNE   illQ
         FIN
:ok      RTS

illQ     LDX   #ILLQTY
         JMP   DOERR

badTyp   LDX   #BADTYP
         JMP   DOERR

* Parse signed coordinates to X,Y.
* Bounds check if `_bound`.
mapPt    ENT
         JSR   parse_i8
         PHY
         JSR   CHKCOM
         JSR   parse_i8
         PLX
         RTS

* check X00,X within 560x192 DHR grid
bound    ENT
         DO    _bound
         CPX   #$C0
         BCS   illQ
         FIN
boundX   ENT
         DO    _bound
         LDA   X00+1
         CMP   #$02
         BCC   :ok
         BNE   illQ
         LDA   X00
         CMP   #$30
         BCS   illQ
         FIN
:ok      RTS

* check brush in X
bndBrsh  ENT
         CPX   #maxBrsh+1
         BCS   illQ
         RTS

* push X onto cyclic stack.
psh      ENT
         LDA   stkptr
         INC
         AND   #%00011111
         TAY
         TXA
         STA   stkdat,Y
         STY   stkptr
         RTS

* pull from cyclic stack into A.    
pul      ENT
         LDY   stkptr
         LDA   stkdat,Y
         DEC   stkptr
         BMI   :roll
         RTS
:roll    LDY   #%00011111
         STY   stkptr
         RTS

* cyclic stack
stkptr   HEX   00
stkdat   DS    $20