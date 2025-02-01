         XC    OFF
         XC
         REL
         DSK   DHRLIB.L

* Main program, link this first.
* This handles the ampersand interface.

* DHR mode
* --------
* bits 0-2 = last command code
* bits 3-4 = reserved
* bit 5 = scanning
* bit 6 = recording
* bit 7 = XOR

* coordinates
* -----------
* Outward facing ampersand parameters follow
* Applesoft conventions.
* Pixel coordinates
* are indexed from 0, on a 560x192 grid.
* Text and tile coordinates
* are indexed from 1, on a 40x24 grid (14x8 blocks).
* In contrast, core parameters are always indexed from 0.
* Tiles are positioned on a 40x24 grid regardless of size,
* i.e., large tiles can be fractionally positioned.

         PUT   equiv
         USE   macros

* imports from CORE

dhrInit  EXT
         DO    _pics
setHCurs EXT
setVCurs EXT
setClr   EXT
plot     EXT
plotc    EXT
lineTo   EXT
stroke   EXT
trap     EXT
         FIN
         DO    _tile/2
tile     EXT
print    EXT
clear    EXT
         FIN
mod      EXT

* imports from PARSE

parsSeek EXT
parsTell EXT
txtPt    EXT
mapPt    EXT
bitwise8 EXT
binary16 EXT
bound    EXT
boundX   EXT
bndBrsh  EXT
saveByt  EXT
saveInt  EXT
psh      EXT
pul      EXT

* imports from MAP

         DO    _tile/3
submap   EXT
avatar   EXT
         FIN
         DO    _tile
scroll   EXT
         FIN

* imports from DRAW

encExe   EXT              ; always need

         DO    _pics/2

draw     EXT
countdwn EXT

* imports from DECODE

decoder  EXT
seekg    EXT
tellg    EXT
resmg    EXT
chkpg    EXT
doDecode EXT

         FIN

         DO    _pics/3

* imports from ENCODE

encoder  EXT
seekp    EXT
tellp    EXT
resmp    EXT
chkpp    EXT
doEncode EXT

         FIN

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

* &vers - push version numbers to cyclic stack
ampVers  LDX   version+2
         JSR   psh
         LDX   version+1
         JSR   psh
         LDX   version
         JSR   psh
         RTS

* &mod (realvar,aexpr)
ampMod   JSR   binary16
         JSR   mod
         LDY   prod
         LDA   prod+1
         JSR   saveInt
         JMP   ampDone
         
* &bit (realvar,aexpr)
ampBit   JSR   bitwise8
:loop1   BEQ   :and
         LSR
         DEX
         BRA   :loop1
:and     AND   #$01
         JSR   saveByt
         JMP   ampDone

* &and (realvar,aexpr)
ampAnd   JSR   bitwise8
         STX   stat
         AND   stat
         JSR   saveByt
         JMP   ampDone

* &and (realvar,aexpr)
ampOr    JSR   bitwise8
         STX   stat
         ORA   stat
         JSR   saveByt
         JMP   ampDone

* &psh < x
ampPh    JSR   chkLess
         JSR   GETBYT
         JSR   psh
         JMP   ampDone

* &pul > x
ampPl    JSR   chkGtr
         JSR   PTRGET
         LDA   VALTYP
         BNE   :err
         JSR   pul
         TXA
         JSR   saveByt
         JMP   ampDone
:err     LDX   #BADTYP
         JMP   DOERR

* &dhr
ampDHR   JSR   dhrInit
         JMP   ampDone

* &mode=x
ampMode  JSR   chkEq
         JSR   GETBYT
         STX   MODE
         LDX   #2
         JSR   encExe
         JMP   ampDone

         DO    _pics

* &move to x,y
ampMove  JSR   chkTo
         JSR   GETNUM
         JSR   bound
         STX   Y0
         cp16  X00;X0
         LDX   #3
         JSR   encExe
         JMP   ampDone

* &hcolor = c1[,c2,c3,c4]
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

* &hplot [to] x,y {[to xn,yn]}
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

* &trap at x0,x1,y0 to x2,x3,y1
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

* &stroke #brush at x,y
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

         FIN

         DO    _pics/2
         
* &draw [n] at dx,dy.
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

         FIN

         DO    _tile/2

* &aux. copy 6 pages starting at (DRAWPTR),2 to aux/0x800.
* copy 1 page starting at (DRAWPTR),$602 to main/2/0xD000.
ampAux   cp16  DRAWPTR;MVSRC
         add16 #2;MVSRC
         cp16  MVSRC;MVEND
         add16 #$05ff;MVEND ; persistent to MEMMOV,AUXMOV
         STZ   MVDST
         LDA   #$08
         STA   MVDST+1
         SEC
         JSR   AUXMOVE
         cp16  MVEND;MVSRC
         inc16 MVSRC
         INC   MVEND+1
         STZ   MVDST
         LDA   #$D0
         STA   MVDST+1
         LDA   RDROM
         LDA   RDROM      ; must do twice
         LDY   #$00
         JSR   MEMMOVE
         JMP   ampDone

* &tile #A at X,Y (units of 14x8 blocks, one-indexing).
* size of tile can be any multiple of 14x8.
ampTile  JSR   chkPnd
         JSR   GETBYT
         PHX
         JSR   chkAt
         JSR   txtPt
         PLA
         JSR   tile
         JMP   ampDone

         FIN

         DO    _tile/3

* &av #n
ampAvtr  JSR   chkPnd
         JSR   GETBYT
         STX   avatar
         RTS

* &bank.
* swap 12 pages starting at (DRAWPTR),2 with $D400-$E000, bank 2.
ampBank  cp16  DRAWPTR;MVSRC
         add16 #2;MVSRC
         mkptr $D400;MVDST
         LDA   RWBNK2
         LDA   RWBNK2     ; do it twice
:loop    LDA   (MVSRC)
         TAX
         LDA   (MVDST)
         TAY
         TXA
         STA   (MVDST)
         TYA
         STA   (MVSRC)
         inc16 MVSRC
         inc16 MVDST
         LDA   MVDST+1
         CMP   #$E0
         BCC   :loop
         LDA   RDROM
         RTS

* &map at x1,y1 to x2,y2 at x,y
* x,y are where to start on the screen in units of 14x8 blocks, one-indexed.
* x1,y1 and x2,y2 define the submap.
* x1,y1 should be in [-128,127].  x2,y2 should be in [0,255].
* Submap can be partially out of bounds, but not completely out of bounds.
ampMap   JSR   chkAt
         JSR   mapPt
         STX   x1
         STY   x1+1
         JSR   chkTo
         JSR   GETBYT
         STX   x2
         JSR   CHKCOM
         JSR   GETBYT
         STX   x2+1
         JSR   chkAt
         JSR   txtPt
         STX   X0
         STY   X0+1
:go      JSR   submap
         JMP   ampDone

         FIN

         DO    _tile

* &scroll at x1,y1 to x2,y2 step dx,dy (units of 14x8 blocks, one-indexing)
ampScrol JSR   chkAt
         JSR   txtPt
         STX   x1
         STY   x1+1
         JSR   chkTo
         JSR   txtPt
         STX   x2
         STY   x2+1
         JSR   chkStep
         JSR   mapPt
         STX   DX
         STY   DX+1
         JSR   scroll
         JMP   ampDone

         FIN

         DO    _tile/2

* &print sexpr at X,Y (units of 14x8 tiles, one-indexing)
ampPrint JSR   FRMEVL
         JSR   GETSTR
         ph16  INDEX
         STY   stat
         JSR   chkAt
         JSR   txtPt
         pl16  INDEX
         LDA   stat
         JSR   print
         JMP   ampDone

* &clear x0,y0 [to x1,y1] (units of 14x8 tiles, one-indexing)
ampClear JSR   txtPt
         STX   X0
         STY   Y0
         LDA   (TXTPTR)
         CMP   #to_t
         BEQ   :to
         LDA   #39
         LDY   Y0
         BRA   :go
:to      JSR   chkTo
         JSR   txtPt
         TXA
:go      SEC
         SBC   X0
         BPL   :ok
         LDX   #ILLQTY
         JMP   DOERR
:ok      INC
         LDX   X0
:loop    PHY
         PHX
         PHA
         JSR   clear
         PLA
         PLX
         PLY
         DEY
         CPY   Y0
         BPL   :loop
         JMP   ampDone

         FIN

         DO    _pics/2

* &seekg(address,commands)
ampSeekg JSR   parsSeek
         JSR   seekg
         JMP   ampDone

* &tellg(addr,bit,cmds)
ampTellg JSR   resmg
         JSR   tellg
         STY   prod
         STA   prod+1
         JSR   parsTell
         JSR   chkpg
         JMP   ampDone

         FIN

         DO    _pics/3

* &seekp(address,commands)
ampSeekp JSR   parsSeek
         JSR   seekp
         JMP   ampDone

* &tellp(addr,bit,cmds)
ampTellp JSR   resmp
         JSR   tellp
         STY   prod
         STA   prod+1
         JSR   parsTell
         JSR   chkpp
         JMP   ampDone

* &rec - record subsequent commands
ampRec   LDA   #%01000000
         TSB   MODE
         JMP   ampDone

* &scan - record commands but do not render
ampScan  LDA   #%00100000
         TSB   MODE
         JMP   ampDone

* &stop - cancels both REC and SCAN
ampStop  LDA   #%01100000
         TRB   MODE
         JMP   ampDone

* &end - write end of drawing marker
ampEnd   LDX   #0
         JSR   encExe
         JMP   ampDone

         FIN

ampDone  LDA   CHKAUX
         STA   stat
         STZ   MAINMEM
         RTS

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
* If one is a left-substring of another, longer string must go first.
* Whenever one is added put it here alphabetically and check:
* AV,AUX,BANK,BIT,DHR,MAP,MOD,MODE,MOVE,PSH,PUL,REC,SCAN,SEEKG,SEEKP,SCROLL,STROKE,TELLG,TELLP,TRAP,TILE,VERS
ampTbl   ASC   'VERS',00
         DA    ampVers
         ASC   'DHR',00
         DA    ampDHR
         ASC   'MODE',00
         DA    ampMode

         DO    _pics
         DFB   hcolor_t,0
         DA    ampColor
         ASC   'MOVE',00
         DA    ampMove
         DFB   hplot_t,0
         DA    ampPlot
         ASC   'TRAP',00
         DA    ampTrap
         ASC   'STROKE',00
         DA    ampStrk
         FIN

         DO    _pics/2
         DFB   draw_t,0
         DA    ampDraw
         ASC   'SEEKG',00
         DA    ampSeekg
         ASC   'TELLG',00
         DA    ampTellg         
         FIN         

         DO    _pics/3
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

         DO    _tile
         ASC   'SCROLL',00
         DA    ampScrol         
         FIN

         DO    _tile/2
         ASC   'TILE',00
         DA    ampTile
         ASC   'AUX',00
         DA    ampAux
         DFB   print_t,0
         DA    ampPrint
         DFB   clear_t,0
         DA    ampClear
         FIN

         DO    _tile/3
         ASC   'AV',00
         DA    ampAvtr
         ASC   'BANK',00
         DA    ampBank
         ASC   'MAP',00
         DA    ampMap
         FIN

         ASC   'MOD',00
         DA    ampMod
         DFB   and_t,0
         DA    ampAnd
         DFB   or_t,0
         DA    ampOr
         ASC   'BIT',00
         DA    ampBit
         ASC   'PSH',00
         DA    ampPh
         ASC   'PUL',00
         DA    ampPl

         HEX   00         ; end table

absPtr   HEX   00,00

version  DFB   0,0,0

noCMOS   ASC   "DHRLIB REQUIRES 65C02",00

* bits after the command code
cmdBits  ENT
         HEX   00,10,01,12,12,12,38,15
