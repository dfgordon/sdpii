         XC    OFF
         XC
         REL
         DSK   DHRLIB.L

* Main program, link this first.
* This handles the ampersand interface to the core
* module, and manages picture encoding/decoding.

* DHR mode
* --------
* bits 0-2 = last command code
* bits 3-4 = reserved
* bit 5 = scanning
* bit 6 = recording
* bit 7 = XOR

         PUT   equiv
         USE   macros

* imports from CORE

setHCurs EXT
setVCurs EXT
dhrInit  EXT
setClr   EXT
plot     EXT
plotc    EXT
lineTo   EXT
stroke   EXT
trap     EXT
tile     EXT
print    EXT
clear    EXT

* imports from DRAW

encExe   EXT

* imports from DECODE

decoder  EXT
seekg    EXT
tellg    EXT
resmg    EXT
chkpg    EXT
doDecode EXT

* imports from ENCODE

encoder  EXT
seekp    EXT
tellp    EXT
resmp    EXT
chkpp    EXT
doEncode EXT

* Main Ampersand dispatcher
* KEEP THIS AS THE FIRST ADDRESSABLE ITEM
dispatch LDA   #$80
         BIT   #$02       ; if 65c02 Z=1, 6502 passes over
         BEQ   :cmos
         JMP   cmosErr
:cmos    STA   MAINMEM
         LDA   stat
         BPL   :disptch
         STA   AUXMEM
:disptch mkptr ampTbl;zptr
:loop    JSR   tryCmd
         BNE   :match
         LDA   (zptr)
         BNE   :loop
         JMP   SNERR      ; no match
:match   LDA   (zptr)
         STA   absPtr
         LDY   #$01
         LDA   (zptr),Y
         STA   absPtr+1
         JMP   (absPtr)

* Test TXTPTR for match with zptr.
* if matching return A=1/Z=0, else rewind TXTPTR and
* advance zptr to next command.
* string at (zptr) must terminate in [0,jmp_addr]
tryCmd   LDA   #$01       ; suppose matched
         STA   stat
         ph16  TXTPTR
         JSR   CHRGOT
:loop    CMP   #$00
         BMI   :chk
         CMP   #$61
         BCC   :chk
         AND   #%11011111 ; to upper (must be letter)
:chk     CMP   (zptr)
         BEQ   :match
:nomtch  LDA   #$00       ; not matched
         STA   stat
:match   inc16 zptr
         LDA   (zptr)
         BEQ   :fin
         JSR   CHRGET
         JMP   :loop
:fin     inc16 zptr
         JSR   CHRGET     ; advance to next
         LDA   stat
         BEQ   :rewind
         PLA
         PLA
         LDA   #$01
         RTS
:rewind  pl16  TXTPTR
         inc16 zptr
         inc16 zptr
         LDA   #$00
         RTS

chkPnd   LDA   #35        ; pound
         DFB   $2C        ; fake BIT to skip next line
chkAt    LDA   #at_t
         DFB   $2C
chkTo    LDA   #to_t
         DFB   $2C
chkLess  LDA   #less_t
         DFB   $2C
chkGtr   LDA   #gtr_t
         DFB   $2C
chkEq    LDA   #eq_t
         DFB   $2C
chkStep  LDA   #step_t
         CMP   (TXTPTR)
         BNE   :err
         JMP   CHRGET
:err     JMP   SNERR

* bit (n,x)
ampBit   JSR   CHKOPN
         JSR   GETBYT
         PHX
         JSR   CHKCOM
         JSR   :parse
         PLX
:loop1   BEQ   :and
         LSR
         DEX
         BRA   :loop1
:and     AND   #$01
         JSR   saveByt
         JSR   CHKCLS
         JMP   ampDone
:parse   JSR   PTRGET
         LDA   VALTYP
         BNE   :err
         LDA   VARPNT
         LDY   VARPNT+1
         JSR   MOVFM
         JSR   GETADR
         CMP   #$00
         BNE   :ill
         TYA
         RTS
:err     JMP   badTyp
:ill     LDX   #ILLQTY
         JMP   DOERR

* psh < x
ampPh    JSR   chkLess
         JSR   GETBYT
         JSR   psh
         JMP   ampDone

* pul > x
ampPl    JSR   chkGtr
         JSR   PTRGET
         LDA   VALTYP
         BNE   :err
         JSR   pul
         JSR   saveByt
         JMP   ampDone
:err     JMP   badTyp

* dhr
ampDHR   JSR   dhrInit
         JMP   ampDone

* hcolor = c1[,c2,c3,c4]
ampColor JSR   GETBYT
         PHX
         CMP   #44        ; comma
         BEQ   :dither
         PHX
         PHX
         PHX
         JMP   :set
:dither  JSR   CHRGET
         JSR   GETBYT
         PHX
         JSR   CHKCOM
         JSR   GETBYT
         PHX
         JSR   CHKCOM
         JSR   GETBYT
         PHX
:set     PLX
         PLA
         LDY   #CLRBAS1
         JSR   setClr
         PLX
         PLA
         LDY   #CLRBAS2
         JSR   setClr
         LDX   #1
         JSR   encExe
         JMP   ampDone

* mode=x
ampMode  JSR   chkEq
         JSR   GETBYT
         STX   MODE
         LDX   #2
         JSR   encExe
         JMP   ampDone

ampMove  JSR   chkTo
         JSR   GETNUM
         JSR   bound
         STX   Y0
         cp16  X00;X0
         LDX   #3
         JSR   encExe
         JMP   ampDone

* hplot syntax same as HGR
ampPlot  LDA   #to_t
         CMP   (TXTPTR)
         BNE   :iniCurs
:loop    JSR   CHRGET
         JSR   GETNUM
         JSR   bound
         cp16  X00;x1
         STX   y1
         LDX   #5
         JSR   encExe
         LDA   #to_t
         CMP   (TXTPTR)
         BEQ   :loop
         JMP   ampDone
:iniCurs JSR   GETNUM
         JSR   bound
         cp16  X00;X0
         STX   Y0
         LDA   #to_t
         CMP   (TXTPTR)
         BEQ   :curs
         LDX   #4
         JSR   encExe
         JMP   ampDone
:curs    LDX   #3
         JSR   encExe
         BRA   :loop

* trap at x0,x1,y0 to x2,x3,y1
ampTrap  JSR   chkAt

         JSR   NUMEVL
         JSR   GETADR
         JSR   boundX
         cp16  X00;X0
         JSR   CHKCOM
         JSR   GETNUM
         JSR   bound
         STX   Y0
         cp16  X00;x1

         JSR   chkTo

         JSR   NUMEVL
         JSR   GETADR
         JSR   boundX
         cp16  X00;x2
         JSR   CHKCOM
         JSR   GETNUM
         JSR   bound
         STX   y1
         cp16  X00;x3

         lte8  Y0;y1
         lte16 X0;x1
         lte16 x2;x3

         LDX   #6
         JSR   encExe
         JMP   ampDone

* stroke#brush at x,y
ampStrk  JSR   chkPnd
         JSR   GETBYT
         PHX
         JSR   bndBrsh
         JSR   chkAt
         JSR   GETNUM
         JSR   bound
         STX   Y0
         cp16  X00;X0
         PLX
         BEQ   :point
         DEX              ; ref brush to 0
         STX   y1
         LDX   #7
         JSR   encExe
         JMP   ampDone
:point   LDX   #4
         JSR   encExe
         JMP   ampDone

* draw [n] at dx,dy.
* cannot bounds check at this level.
* dx,dy are treated as int16.
ampDraw  LDA   #at_t
         CMP   (TXTPTR)
         BEQ   :max
         JSR   NUMEVL
         JSR   GETADR
         cp16  X00;countdwn
         BRA   :at
:max     STZ   countdwn
         LDA   #$10
         STA   countdwn+1
:at      JSR   chkAt
         JSR   NUMEVL
         JSR   GETADR
         cp16  X00;DX
         JSR   CHKCOM
         JSR   NUMEVL
         JSR   GETADR     ; use X00 for 16 bit DY
         JSR   draw
         JMP   ampDone

* tile #A at X,Y (X=X0/14+1, Y=Y0/8+1)
ampTile  JSR   chkPnd
         JSR   GETBYT
         PHX
         JSR   chkAt
         JSR   GETNUM
         JSR   bndTxt
         TXA
         TAY
         LDA   X00
         TAX
         PLA
         DEX
         DEY
         JSR   tile
         JMP   ampDone

* print sexpr at X,Y (X=X0/14+1, Y=Y0/8+1)
ampPrint JSR   FRMEVL
         JSR   GETSTR
         ph16  INDEX
         STY   stat
         JSR   chkAt
         JSR   GETNUM
         JSR   bndTxt
         TXA
         TAY
         LDX   X00
         DEX
         DEY
         pl16  INDEX
         LDA   stat
         JSR   print
         JMP   ampDone

* clear x0,y0 [to x1,y1]
ampClear JSR   GETNUM
         JSR   bndTxt
         LDA   X00
         STA   X0
         STX   Y0
         LDA   (TXTPTR)
         CMP   #to_t
         BEQ   :to
         LDA   #40
         LDY   Y0
         BRA   :go
:to      JSR   chkTo
         JSR   GETNUM
         JSR   bndTxt
         TXA
         TAY
         LDA   X00   
:go      SEC
         SBC   X0
         BPL   :ok
         JMP   illQ
:ok      INC
         LDX   X0
         DEX
:loop    DEY
         PHY
         PHX
         PHA
         JSR   clear
         PLA
         PLX
         PLY
         CPY   Y0
         BPL   :loop
         JMP   ampDone

* seekg(address,commands)
ampSeekg JSR   parsSeek
         JSR   seekg
         JMP   ampDone

* tellg(addr,bit,cmds)
ampTellg JSR   resmg
         JSR   tellg
         STY   prod
         STA   prod+1
         JSR   parsTell
         JSR   chkpg
         JMP   ampDone

         DO    _builder

* seekp(address,commands)
ampSeekp JSR   parsSeek
         JSR   seekp
         JMP   ampDone

* tellp(addr,bit,cmds)
ampTellp JSR   resmp
         JSR   tellp
         STY   prod
         STA   prod+1
         JSR   parsTell
         JSR   chkpp
         JMP   ampDone

* rec - record subsequent commands
ampRec   LDA   #%01000000
         ORA   MODE
         STA   MODE
         JMP   ampDone

* scan - record commands but do not render
ampScan  LDA   #%00100000
         ORA   MODE
         STA   MODE
         JMP   ampDone

* cancels both REC and SCAN
ampStop  LDA   #%10011111
         AND   MODE
         STA   MODE
         JMP   ampDone

* end - write end of drawing marker
ampEnd   LDX   #0
         JSR   encExe
         JMP   ampDone

         FIN

ampDone  LDA   CHKAUX
         STA   stat
         STZ   MAINMEM
         RTS

* get expressions into stream and X00
parsSeek JSR   CHKOPN
         JSR   NUMEVL
         JSR   GETADR
         cp16  X00;stream
         JSR   CHKCOM
         JSR   NUMEVL
         JSR   GETADR
         JSR   CHKCLS
         RTS

parsTell JSR   CHKOPN
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
saveByt  TAY
         LDA   #$00
* save Y + 256*A in the last variable
saveInt  JSR   INT2FP
         LDX   VARPNT
         LDY   VARPNT+1
         JSR   MOVMF
         RTS

* push X onto cyclic stack.
psh      LDA   stkptr
         INC
         AND   #%00011111
         TAY
         TXA
         STA   stkdat,Y
         STY   stkptr
         RTS

* pull from cyclic stack into A.    
pul      LDY   stkptr
         LDA   stkdat,Y
         DEC   stkptr
         BMI   :roll
         RTS
:roll    LDY   #%00011111
         STY   stkptr
         RTS

illQ     LDX   #ILLQTY
         JMP   DOERR

badTyp   LDX   #BADTYP
         JMP   DOERR

* check X00,X within 560x192 DHR grid
bound    DO    _bound
         CPX   #$C0
         BCS   illQ
         FIN
boundX   DO    _bound
         LDA   X00+1
         CMP   #$02
         BCC   :ok
         BNE   illQ
         LDA   X00
         CMP   #$30
         BCS   illQ
         FIN
:ok      RTS

* check X00,X within 40x24 text grid.
* assumes indexing from 1.
* this is the *only* guard for text commands.
bndTxt   DEX
         CPX   #$18
         BCS   illQ
         INX
         LDA   X00+1
         BNE   illQ
         LDA   X00
         DEC
         CMP   #$28
         BCS   illQ
         INC
         RTS

* check brush in X
bndBrsh  CPX   #maxBrsh+1
         BCS   illQ
         RTS

* Render a binary coded drawing with offset DX,X00.
* Execute a maximum of `countdwn` commands.
draw     LDA   countdwn
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

cmosErr  JSR   BELL
         LDY   #$00
:PR      LDA   noCMOS,Y
         CMP   #$00
         BEQ   :restart
         JSR   COUT
         INY
         JMP   :PR
:restart JSR   STKINI
         JMP   RESTART

* Table of ampersands.
* If strings overlap, longer string must go first.
ampTbl   ASC   'DHR',00
         DA    ampDHR
         DFB   hcolor_t,0
         DA    ampColor
         ASC   'MODE',00
         DA    ampMode
         ASC   'MOVE',00
         DA    ampMove
         DFB   hplot_t,0
         DA    ampPlot
         ASC   'TRAP',00
         DA    ampTrap
         ASC   'STROKE',00
         DA    ampStrk
         ASC   'TILE',00
         DA    ampTile
         DFB   print_t,0
         DA    ampPrint
         DFB   clear_t,0
         DA    ampClear
         DFB   draw_t,0
         DA    ampDraw

         DO    _builder
         DFB   end_t,0
         DA    ampEnd
         ASC   'REC',00
         DA    ampRec
         ASC   'SCAN',00
         DA    ampScan
         DFB   stop_t,0
         DA    ampStop         
         ASC   'SEEKP',00
         DA    ampSeekp
         ASC   'TELLP',00
         DA    ampTellp
         FIN
         
         ASC   'SEEKG',00
         DA    ampSeekg
         ASC   'TELLG',00
         DA    ampTellg

         ASC   'BIT',00
         DA    ampBit
         ASC   'PSH',00
         DA    ampPh
         ASC   'PUL',00
         DA    ampPl

         HEX   00         ; end table

absPtr   HEX   00,00
countdwn HEX   00,00

noCMOS   ASC   "DHRLIB REQUIRES 65C02",00

* bits after the command code
cmdBits  ENT
         HEX   00,10,01,12,12,12,38,15

* cyclic stack
stkptr   HEX   00
stkdat   DS    $20