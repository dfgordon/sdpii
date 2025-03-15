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
* CHKAUX - state of MAIN/AUX soft switch
* BITPOS - bitmap of 7-pixel cell
* clrMask1 - even row pattern
* clrMask2 - odd row pattern
* We re-use some of the HGR cursor locations.

* table of tile row addresses
rowTbHi  ENT
         HEX   202021212222232320202121222223232020212122222323
rowTbLo  ENT
         HEX   008000800080008028a828a828a828a850d050d050d050d0

         DO    _tile/2
* storage for a 14x8 glyph brought in from auxiliary memory
glyph    DS    16
         FIN

         DO    _pics

* table of 64 pixel bins
* colTbl is (64*n/7)%80-1, bitTbl is 64*n%7
* 16 bins, 1024 pixels (padded)
colTbl   HEX   ff,08,11,1a,23,2c,35,3f,48,01,0a,13,1c,25,2f,38
bitTbl   HEX   00,01,02,03,04,05,06,00,01,02,03,04,05,06,00,01

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

* Use X0 to get COLUMN, BITPOS, clrMask1, clrMask2,
* Pretty wrapping works for -1024<=X0<1024.
* Wrapping constrains cursor to screen buffer for any X0.
* Optimization is to split into 64-pix bins.
setHCurs ENT
         phX0
         DO    _wrap*_pics
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
         DO    _wrap*_pics
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
         DO    _wrap*_pics
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
setVCurs ENT
         LDA   Y0
         DO    _wrap*_pics
         CMP   #$C0
         BCC   :ok
         SEC
         SBC   #$C0
         FIN
:ok      PHA
         LSR
         LSR
         LSR
         TAY
         LDA   rowTbLo,Y
         STA   ROWPTR
         LDA   rowTbHi,Y
         STA   ROWPTR+1
         PLA
         AND   #%00000111
         ASL
         ASL
         ORA   PAGE
         TSB   ROWPTR+1
         RTS
*  PHA
*  AND   #%11000000
*  STA   ROWPTR
*  LSR
*  LSR
*  TSB   ROWPTR
*  PLA
*  STA   ROWPTR+1
*  ASL
*  ASL
*  ASL
*  ROL   ROWPTR+1
*  ASL
*  ROL   ROWPTR+1
*  ASL
*  ROR   ROWPTR
*  LDA   ROWPTR+1
*  AND   #%00011111
*  ORA   PAGE
*  STA   ROWPTR+1
*  RTS

         FIN

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
         DO    _pics
         JSR   setHCurs
         JSR   setVCurs
         FIN
         RTS

         DO    _pics

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
         TSB   BITPOS
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

         FIN

         DO    _tile/2

* update MVSRC to the address of tile fac1,
* set prod to bytes per page,
* set prod+1 to normal or inverse mask.
* X00 = column pairs, fac2 = rows, MVSRC = address of first tile.
tileptr  JSR   mulbb
         cp16  prod;glyph ; use glyph as temp
         LDX   X00
:add     DEX
         BEQ   :dbl
         add16 glyph;prod
         BRA   :add
:dbl     ASL   prod
         ROL   prod+1     ; prod = tile offset
         add16 prod;MVSRC
         STZ   prod+1
         LDA   MODE
         BPL   :size
         DEC   prod+1     ; prod+1 = mask
:size    LDA   fac2
         LDX   X00
         CLC
:add2    DEX
         BEQ   :fin
         ADC   fac2
         BRA   :add2
:fin     STA   prod       ; prod = size per page
         RTS

* Load standard 14x8 glyph from stashed font.
* Assumes we are set to read bank 2.
* Glyph number to load is in fac1.
* Glyphs 0-95 are pulled from pages 8-13 of aux-memory.
* Glyphs 96-111 are pulled from page $D0 of main-memory (bank 2).
* `glyph` receives glyph data, `fac2` set to 8, `X00` set to 1.
ldglyph  STZ   MVSRC
         LDA   #$08
         STA   MVSRC+1
         STA   fac2
         LDA   #$01
         STA   X00
         LDA   fac1
         CMP   #$60
         BMI   :prep      ; using aux
         SEC              ; using bank
         SBC   #$60
         STA   fac1
         LDA   #$D0
         STA   MVSRC+1
:prep    JSR   tileptr
         CLC
         LDA   #$0F
         ADC   MVSRC
         STA   MVEND
         LDA   #$00
         ADC   MVSRC+1
         STA   MVEND+1
         mkptr glyph;MVDST
         LDA   MVSRC+1
         BMI   :bank
         CLC
         JSR   AUXMOVE
         RTS
* loop assumes source data within page
:bank
:loop    LDA   (MVSRC)
         STA   (MVDST)
         inc16 MVDST
         LDA   MVSRC
         CMP   MVEND
         INC   MVSRC
         BCC   :loop
         RTS

* Draw tile A at X=x/14,Y=y/8. zero-indexing.
* DRAWPTR = pointer to tile data.
* If DRAWPTR in ZP, assume packed tiles, no header.
* If DRAWPTR in page 8, assume a packed font, no header.
* This is built to be general, not fast, see also map::fstTile.
tile     ENT
         PHY
         STA   fac1
         STX   COLUMN
         LDA   RDBNK2
* setup pointer to this tile
         LDA   DRAWPTR+1
         BEQ   :ldbank
         CMP   #$08
         BEQ   :ldglyph
         cp16  DRAWPTR;MVSRC
         BRA   :offset
:ldbank  mkptr $D400;MVSRC
         LDA   #2
         STA   X00
         LDA   #16
         STA   fac2
         BRA   :off2
:ldglyph JSR   ldglyph
         mkptr glyph;:rep+1
         BRA   :iniLup
:offset  LDA   (MVSRC)
         inc16 MVSRC
         STA   X00
         LDA   (MVSRC)
         inc16 MVSRC
         ASL
         ASL
         ASL
         STA   fac2       ; pixel-rows
:off2    JSR   tileptr
         cp16  MVSRC;:rep+1
* tile is loaded and/or referenced
:iniLup  PLY
         STZ   AUXMEM
         LDX   prod
         DEX
         JSR   :dopage
         STZ   MAINMEM
         addu8 prod;:rep+1
         LDX   prod
         DEX
         JSR   :dopage
         LDA   RDROM
         RTS
* subroutine to paint current page
:dopage  PHY
         PHY
:iniRow  LDA   rowTbLo,Y
         STA   ROWPTR
         LDA   rowTbHi,Y
:ezRow   LDY   COLUMN
         STA   ROWPTR+1
         LDA   X00
         STA   fac1
* loop over columns
:rep     LDA   $FFFF,X    ; variable operand
         EOR   prod+1
         paint
         INY
         DEX
         BMI   :fin
         DEC   fac1
         BNE   :rep
* prepare for next row
:nxtRow  CLC
         LDA   ROWPTR+1
         ADC   #$04
         BIT   #$1C
         BNE   :ezRow
         PLY
         INY
         PHY
         BRA   :iniRow
:fin     PLY
         PLY
         RTS

* print str with length A and ptr INDEX at X,Y. zero-indexing.
* font must be 14 pixels wide.  destroys stat and byt.
print    ENT
         STA   stat
         LDA   DRAWPTR+1
         BNE   :go
         LDA   #$08
         STA   DRAWPTR+1
         JSR   :go
         STZ   DRAWPTR+1
         RTS
:go      LDA   #$00
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

         FIN

* absolute value of accumulator
abs8     ENT
         ASL
         BCC   :pos
         ROR
         EOR   #$FF
         INC
         RTS
:pos     ROR
         RTS

* Multiply two bytes to get a word
* prod = fac1 * fac2, fac1 is destroyed, fac2 is preserved
mulbb    ENT
         STZ   prod
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

* get remainder of prod/fac for u16
* mod_u16  ENT
*          LDA   #$00       ; lo-remainder
*          LDY   #$00       ; hi-remainder
*          LDX   #$10       ; bits
* :loop    ASL   prod
*          ROL   prod+1
*          ROL
*          PHA
*          TYA
*          ROL
*          TAY
*          PLA

*          PHX
*          TAX
*          SEC
*          SBC   fac1
*          PHA
*          TYA
*          SBC   fac2
*          PHA
*          BCS   :reset
*          PLA
*          PLA
*          TXA
*          BRA   :cont
* :reset   PLY
*          PLA
* :cont    PLX

*          DEX
*          BNE   :loop
*          STA   prod
*          STY   prod+1
*          RTS
         
* Get remainder allowing for signed numerator by a simple method.
* This is fast if quotient is small, slow if quotient is large.
* prod = numerator, LE fac1,fac2 = denominator.
* result is in prod.
mod      ENT
         LDA   prod+1
         BMI   :neg
:loop    SEC
         LDA   prod
         SBC   fac1
         STA   prod
         LDA   prod+1
         SBC   fac2
         STA   prod+1
         BCS   :loop
:add     CLC
         LDA   prod
         ADC   fac1
         STA   prod
         LDA   prod+1
         ADC   fac2
         STA   prod+1
         RTS
:neg     JSR   :add
         BMI   :neg
         RTS