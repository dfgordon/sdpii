         XC    OFF
         XC
         REL
         DSK   CORE.L

* Core graphics subroutines.

         PUT   equiv
         USE   macros

* DHR Cursor
* ----------
* ROWPTR - address of screen row
* COLUMN - HGR column (0-39)
* AUXMEM - state of MAIN/AUX soft switch
* BITPOS - bitmap of 7-pixel cell
* clrMask1 - even row pattern
* clrMask2 - odd row pattern
* We re-use some of the HGR cursor locations.

* Use X0 to get COLUMN, BITPOS, clrMask1, clrMask2,
* Pretty wrapping works for -1024<=X0<1024.
* Wrapping constrains cursor to screen buffer for any X0.
* Optimization is to split into 64-pix bins.
setHCurs ENT
         phX0
         DO    _wrap
         LDA   X0+1
         BPL   :pos
         EOR   #$FF
         STA   X0+1
         LDA   X0
         EOR   #$FF
         STA   X0         ; X0=-X0-1
         FIN
:pos     LDA   X0
         LSR   X0+1
         ROR
         LSR   X0+1
         ROR
         LSR
         LSR
         LSR
         LSR
         AND   #$0F
         TAX              ; x=bin
         LDY   colTbl,X   ; y=80col
         LDA   X0
         AND   #$3F
         CLC
         ADC   bitTbl,X   ; A=bit
         SEC
:sb7     INY
         SBC   #$07
         BCS   :sb7
         TAX
         plX0
         DO    _wrap
         BPL   :pos2
         TXA
         EOR   #$FF
         TAX
         LDA   BITTAB,X
         BRA   :clr
         FIN
:pos2    LDA   BITTAB-$F9,X
:clr     STA   BITPOS
         LDA   CLRBAS1
         STA   clrMask1
         LDA   CLRBAS2
         STA   clrMask2
         STY   COLUMN
         wrap80
         DO    _wrap
         LDA   X0+1
         BPL   :pos3
         SEC
         LDA   #$4F
         SBC   COLUMN
         STA   COLUMN
         FIN
:pos3    LDA   COLUMN
         AND   #$07
         TAY
         CPY   #$00
:loop    BEQ   :pg
         rolClr
         DEY
         BRA   :loop
:pg      STZ   AUXMEM
         LSR   COLUMN
         BCC   :fin
         STZ   MAINMEM
:fin     RTS

* Move cursor horizontally with wrap-around. X0 unchanged.
* Direction given by N.  For vertical use ROM.
movHor   BPL   incHor
decHor   LDA   BITPOS
         LSR
         CMP   #%01000000
         BEQ   :new80c
         EOR   #%11000000
         STA   BITPOS
         RTS
:new80c  LDA   #%11000000
         STA   BITPOS
         rorClr
         swBank
         LDA   CHKAUX
         BMI   :fin
         DEC   COLUMN
         wrapL
:fin     RTS
incHor   LDA   BITPOS
         ASL
         CMP   #$80
         BEQ   :new80c
         ORA   #$80
         STA   BITPOS
         RTS
:new80c  LDA   #%10000001
         STA   BITPOS
         rolClr
         swBank
         LDA   CHKAUX
         BPL   :fin
         INC   COLUMN
         wrapR
:fin     RTS

* Set ROWPTR using Y0.
* Only diff from HGR is separating out.
setVCurs ENT
         LDA   Y0
         DO    _wrap
         CMP   #$C0
         BCC   :ok
         SEC
         SBC   #$C0
         FIN
:ok      PHA
         AND   #%11000000
         STA   ROWPTR
         LSR
         LSR
         ORA   ROWPTR
         STA   ROWPTR
         PLA
         STA   ROWPTR+1
         ASL
         ASL
         ASL
         ROL   ROWPTR+1
         ASL
         ROL   ROWPTR+1
         ASL
         ROR   ROWPTR
         LDA   ROWPTR+1
         AND   #%00011111
         ORA   PAGE
         STA   ROWPTR+1
         RTS

* Initialize double hi-res and DHRLIB.
* Assumes PR#3 already done.
dhrInit  ENT
         JSR   HGR
         STA   MAINZP
         STA   RDMAIN
         STA   WRMAIN
         STA   STOR80
         STA   HIRES
         STA   DHR
         STA   GRAPHICS
         STA   MIXED
         STA   AUXMEM
         JSR   HGRCLR
         STA   MAINMEM
         STZ   X0
         STZ   X0+1
         STZ   Y0
         STZ   MODE
         LDA   #$FF
         STA   CLRBAS1
         STA   CLRBAS2
         LDA   #$20
         STA   PAGE
         JSR   setHCurs
         JSR   setVCurs
         RTS

* Set color mask at ZP address Y to A + X*16.
* If X>15 or A>15 throw error.
setClr   ENT
         CPX   #$10
         BCS   :illQ
         CMP   #$10
         BCS   :illQ
         STA   $00,Y
         TXA
         ASL
         ASL
         ASL
         ASL
         ORA   $00,Y
         STA   $00,Y
         RTS
:illQ    JMP   illQ

* plot one pixel with color and mode mask
* (really plots all pixels in BITPOS)
plot     ENT
         JSR   setHCurs   ; plot at X0,Y0 (slow)
         JSR   setVCurs
plotc    ENT
         PHY              ; plot at cursor (faster)
         LDY   COLUMN
         LDA   MODE
         BPL   :dither
         LDA   #$FF
         BRA   :pix
:dither  LDA   ROWPTR+1
         AND   #%100
         BNE   :clr2
         LDA   (ROWPTR),Y
         EOR   clrMask1
         BRA   :pix
:clr2    LDA   (ROWPTR),Y
         EOR   clrMask2   ; 0 ^ 1=wanted -> 1=flip
                          ; 0 ^ 0=unwanted -> 0=leave
                          ; 1 ^ 1=wanted -> 0=leave
                          ; 1 ^ 0=unwanted -> 1=flip
:pix     AND   BITPOS
         EOR   (ROWPTR),Y
         paint
         PLY
         RTS

* Prepare line from cursor to A+X*256,Y.
* X0, Y0 are used to work out deltas.
* Sets X, Y, X0, Y0, DX, DY, HGRQUAD, HGRE, HCOUNT.
iniLine  PHA              ; x1 low
         SEC              ; prepare dx
         SBC   X0
         PHA              ; dx low
         TXA              ; x1 high
         SBC   X0+1
         STA   HGRQUAD    ; dx high
         BPL   :dxpos
         PLA              ; dx low
         EOR   #$FF
         ADC   #$01
         PHA              ; dx low inverted
         LDA   #$00
         SBC   HGRQUAD
:dxpos   STA   DX+1
         STA   HGRE+1
         PLA              ; dx low
         STA   DX
         STA   HGRE
         PLA
         STA   X0
         STX   X0+1       ; finish horizontal setup
                          ; X0 = target
                          ; DX and HGRE = |dx|
                          ; HGRQUAD = direction
         TYA
         CLC              ; prepare dy
         SBC   Y0
         BCC   :dyneg
         EOR   #%11111111
         ADC   #%11111110
:dyneg   STA   DY
         STY   Y0         ; finish dy, prepare HCOUNT,HGRQUAD
         ROR   HGRQUAD    ; sgn = -sgn(dy), bit 6 = sgn(dx)
         SEC
         SBC   DX
         TAX              ; X = -abs(dy)-abs(dxlow)
         LDA   #%11111111
         SBC   DX+1
         STA   HCOUNT     ; -1-abs(dxh)-borrow
         LDY   COLUMN
         RTS

* draw line from X0,Y0 to A+X*256,Y
* Cursor,X0,Y0 are updated.
line     PHA
         PHX
         PHY
         JSR   setHCurs
         JSR   setVCurs
         PLY
         PLX
         PLA
* Draw line from cursor to A+X*256,Y.
* Cursor,X0,Y0 must be consistent.
* Cursor,X0,Y0 are updated.
* adapted from similar HGR routine
lineTo   ENT
         JSR   iniLine
:ini     SEC
         LDA   HGRE
         ADC   DY
         STA   HGRE
         LDA   HGRE+1
         SBC   #$00
         STA   HGRE+1
:plt     JSR   plotc
         INX
         BNE   :mov
         INC   HCOUNT
         BEQ   :fin
:mov     LDA   HGRQUAD
         BCC   :ud
         ASL
         JSR   movHor
         BRA   :ini
:ud      JSR   MOVUPDWN
         add16 DX;HGRE
         BRA   :plt
:fin     RTS

* Start incremental line advance for trapezoid bounds.
iniTrap  phXY
* gather left boundary params
         LDA   x2
         LDX   x2+1
         LDY   y1
         JSR   iniLine
         cp16  HGRE;hgre1
         cp16  DX;dx1
         STX   count1
         LDA   HCOUNT
         STA   count1+1
         LDA   HGRQUAD
         ASL
         STA   quad1
* gather right boundary params
         plXY
         phXY
         cp16  x1;X0
         LDA   x3
         LDX   x3+1
         LDY   y1
         JSR   iniLine
         cp16  HGRE;hgre2
         cp16  DX;dx2
         STX   count2
         LDA   HCOUNT
         STA   count2+1
         LDA   HGRQUAD
         ASL
         STA   quad2

         plXY
         JSR   setHCurs
         JSR   setVCurs
         SEC
         LDA   x1
         SBC   X0
         STA   HCOUNT
         LDA   x1+1
         SBC   X0+1
         STA   HCOUNT+1
         inc16 HCOUNT
         RTS

* start trapezoid left boundary
iniTrap1 SEC
         LDA   hgre1
         ADC   DY
         STA   hgre1
         LDA   hgre1+1
         SBC   #$00
         STA   hgre1+1
* continue trapezoid left boundary
trapMov1 INC   count1
         BNE   :mov
         INC   count1+1
         BEQ   :fin
:mov     BCC   :fin
         LDA   quad1
         JSR   movHor
         LDA   quad1
         BMI   :lft
         dec16 HCOUNT
         BRA   iniTrap1
:lft     inc16 HCOUNT
         BRA   iniTrap1
:fin     RTS

* start trapezoid right boundary
iniTrap2 SEC
         LDA   hgre2
         ADC   DY
         STA   hgre2
         LDA   hgre2+1
         SBC   #$00
         STA   hgre2+1
* continue trapezoid right boundary
trapMov2 INC   count2
         BNE   :mov
         INC   count2+1
         BEQ   :fin
:mov     BCC   :fin
         LDA   quad2
         BMI   :lft
         inc16 HCOUNT
         BRA   iniTrap2
:lft     dec16 HCOUNT
         BRA   iniTrap2
:fin     RTS

* Fill a trapezoid using horizontal lines
* upper segment is X0,x1,Y0.
* lower segment is x2,x3,y1
trap     ENT
         JSR   iniTrap
         JSR   hlinet
         JSR   iniTrap1
         JSR   iniTrap2
:loop    LDA   count1
         BNE   :nxt
         LDA   count1+1
         BEQ   :fin
:nxt     JSR   INCRY
         JSR   hlinet
         add16 dx1;hgre1
         JSR   trapMov1
         add16 dx2;hgre2
         JSR   trapMov2
         BRA   :loop
:fin     RTS

* draw horizontal line from X0,Y0 to A+X*256,Y0.
* requires X0<A+X*256.
* cursor updated. X0,Y0 unchanged.
hline    ENT
         SEC
         SBC   X0
         STA   HCOUNT
         TXA
         SBC   X0+1
         STA   HCOUNT+1
         inc16 HCOUNT
         JSR   setHCurs
         JSR   setVCurs
* hline assuming cursor and HCOUNT already setup
hlinec   JSR   fastLn
         LDA   HCOUNT+1
         BEQ   :fin
         DEC   HCOUNT
         DEC   HCOUNT+1
         BRA   hlinec
:fin     RTS
* hlinec wrapped in code to restore HCOUNT and horizontal cursor
hlinet   ph16  HCOUNT
         phHorCrs
         JSR   hlinec
         plHorCrs
         pl16  HCOUNT
         RTS

* Draw horizontal line assuming cursor is set, we are moving
* right, and number of pixels to set is in low byte of HCOUNT.
fastLn   LDA   HCOUNT
         BNE   :ok
:fin     RTS
:ok      CMP   #$07
         BCC   :rmndr
         LDA   BITPOS
         CMP   #%10000001
         BNE   :rmndr

:do7     LDY   COLUMN
         LDA   MODE
         BPL   :dither
         LDA   #$FF
         BRA   :pix
:dither  LDA   ROWPTR+1
         AND   #%100
         LSR
         LSR
         TAX
         LDA   (ROWPTR),Y
         EOR   clrMask1,X
:pix     EOR   (ROWPTR),Y
         paint
         SEC
         LDA   HCOUNT
         SBC   #$07
         STA   HCOUNT
:adv     rolClr
         swBank
         LDA   CHKAUX
         BPL   :nxt
         INC   COLUMN
         wrapR
:nxt     LDA   HCOUNT
         BEQ   :fin
         CMP   #$07
         BCC   :rmndr
         BRA   :do7

:rmndr   LDX   BITPOS
         TXA
:loop    DEC   HCOUNT
         BEQ   :go
         BIT   #%01000000
         BNE   :go
         TXA
         ASL
         TAX
         ORA   BITPOS
         STA   BITPOS
         BRA   :loop
:go      JSR   plotc
         STX   BITPOS
         JSR   incHor
         BRA   :nxt

* Stroke brush X at X0,Y0.
* X=0 is not a point, but the smallest brush.
stroke   ENT
         JSR   setVCurs
         mkptr brushes;zptr
         TXA
         TAY
         CLC
         LDA   brushTbl,Y
         ADC   zptr
         STA   zptr
         LDA   #$00
         ADC   zptr+1
         STA   zptr+1
         LDA   (zptr)
         STA   DY         ; rows
         STA   x1         ; use as ptr
         STZ   x1+1
         inc16 zptr
         add16 zptr;x1
         STZ   y1         ; counter
:nextLn  phXY
         LDY   y1
         CLC
         LDA   (zptr),Y
         ADC   X0
         STA   X0
         LDA   #$00
         ADC   X0+1
         STA   X0+1
         LDA   (x1),Y
         STA   HCOUNT
         JSR   setHCurs
         JSR   fastLn
         plXY
         INC   Y0
         INC   y1
         LDA   y1
         CMP   DY
         BEQ   :fin
         JSR   INCRY
         BRA   :nextLn
:fin     RTS

* draw tile A at X=x/14,Y=y/8, tile size <= 255
* DRAWPTR = pointer to tile data
* expect 0-indexing by this point
tile     ENT
         PHA
         LDA   rowTbLo,Y
         STA   ROWPTR
         LDA   rowTbHi,Y
         STA   ROWPTR+1
         STX   COLUMN
         cp16  DRAWPTR;zptr

         PLA              ; tile num
         STA   fac1
         LDA   (zptr)     ; col pairs
         ASL
         STA   fac2       ; bytes across
         JSR   mulbb
         LDA   prod+1
         BEQ   :ok
         JMP   illQ
:ok      LDA   prod
         STA   fac1
         LDY   #$01
         LDA   (zptr),Y
         ASL
         ASL
         ASL
         STA   fac2       ; y pixels
         JSR   mulbb      ; tile offset

         LDA   (zptr)
         TAX
         inc16 zptr
         LDA   (zptr)
         ASL
         ASL
         ASL
         TAY              ; y pixels
         inc16 zptr
         add16 prod;zptr
         LDA   COLUMN
         STA   fac1

:loopy   LDA   (DRAWPTR)
         TAX
         LDA   fac1
         STA   COLUMN

:loopx   PHX
         PHY

         STZ   AUXMEM
:rep     LDY   COLUMN
         LDA   (zptr)
         LDX   MODE
         BPL   :norm
         EOR   #$FF
:norm    paint
         inc16 zptr
         LDA   CHKAUX
         BPL   :cont
         STZ   MAINMEM
         BRA   :rep

:cont    PLY
         PLX
         DEX
         BEQ   :nxtRow
         INC   COLUMN
         BRA   :loopx
:nxtRow  JSR   INCRY
         DEY
         BEQ   :fin
         BRA   :loopy
:fin     RTS

* print str with length A and ptr INDEX at X,Y.
* destroys stat and byt.
print    ENT
         STA   stat
         LDA   #$00
         STA   byt
:loop    PHY
         LDY   byt
         LDA   (INDEX),Y
         SEC
         SBC   #$20
         PLY
         PHY
         PHX
         JSR   tile
         PLX
         PLY
         INX
         CPX   #$28
         BCS   :wrap
:nxt     INC   byt
         DEC   stat
         BNE   :loop
         RTS
:wrap    LDX   #$00
         INY
         CPY   #$18
         BCC   :nxt
         RTS

* clear A columns at X=x/14,Y=y/8
clear    ENT
         STA   HCOUNT
         STX   COLUMN
         LDA   rowTbLo,Y
         STA   ROWPTR
         LDA   rowTbHi,Y
         STA   ROWPTR+1
         
         LDA   #$08
         STA   byt
:loopy   LDX   HCOUNT
         LDY   COLUMN
:loopx   LDA   #$00
         STZ   AUXMEM
         STA   (ROWPTR),Y
         STZ   MAINMEM
         STA   (ROWPTR),Y
         INY
         DEX
         BNE   :loopx
         JSR   INCRY
         DEC   byt
         BNE   :loopy
         RTS
         
* Multiply two bytes to get a word
* prod = fac1 * fac2
mulbb    STZ   prod
         STZ   prod+1
         LDX   #$08
:loop    LSR   fac1
         BCC   :clr1
         CLC
         LDA   prod+1
         ADC   fac2
         STA   prod+1
:clr1    ROR   prod+1
         ROR   prod
         DEX
         BNE   :loop
         RTS

illQ     LDX   #ILLQTY
         JMP   DOERR

brushTbl
         HEX   00,07,10,1b,2c,41,60
brushes
         HEX   03
         HEX   000000
         HEX   040404
         HEX   04
         HEX   00000000
         HEX   08080808
         HEX   05
         HEX   0100000001
         HEX   0a0c0c0c0a
         HEX   08
         HEX   0301000000000103
         HEX   0c1012121212100c
         HEX   0a
         HEX   05020100000000010205
         HEX   0e14161818181816140e
         HEX   0f
         HEX   090604020100000000000102040609
         HEX   12181c2022242424242422201c1812
         HEX   14
         HEX   0e0a070503020100000000000001020305070a0e
         HEX   141c22262a2c2e3030303030302e2c2a26221c14

* trapezoid advance
hgre1    DDB   0000
hgre2    DDB   0000
count1   DDB   0000
count2   DDB   0000
quad1    DFB   00
quad2    DFB   00
dx1      DDB   0000
dx2      DDB   0000

* table of tile row addresses
rowTbHi  HEX   202021212222232320202121222223232020212122222323
rowTbLo  HEX   008000800080008028a828a828a828a850d050d050d050d0

* table of 64 pixel bins
* colTbl is (64*n/7)%80-1, bitTbl is 64*n%7
* 16 bins, 1024 pixels (padded)
colTbl   HEX   ff,08,11,1a,23,2c,35,3f,48,01,0a,13,1c,25,2f,38
bitTbl   HEX   00,01,02,03,04,05,06,00,01,02,03,04,05,06,00,01