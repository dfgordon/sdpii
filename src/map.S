         XC    OFF
         XC
         REL
         DSK   MAP.L

* Subroutines for rendering a map view.
* Map encoding at this level is deliberately simple: one byte, one tile.
* We have in mind that in a final application, the input to this module is
* a submap buffer that is populated by higher level code.
* Maximum width of screen window is 16 tiles (448 pixels).
* Rendering a map causes any picture drawing state to be lost.

* Beware of the following confusing situation.
* Tile coordinates are stored in a word,
* with x in the low byte, and y in the high byte.
* As a result, things like x1+1 often refer to a y-coordinate.

         PUT   equiv
         USE   macros

tile     EXT
mulbb    EXT
abs8     EXT
rowTbHi  EXT
rowTbLo  EXT

begMVw   DFB   0,0        ; start of view in map coords
endMVw   DFB   0,0        ; end of view in map coords
endMap   DFB   0,0        ; end of all map data
endScrn  DFB   0,0        ; end of view in screen coords
colCount DFB   0
rowCount DFB   0
rowAdv   DA    0

paint14  MAC
         STZ   AUXMEM
         LDA   (zptr)
         STA   (ROWPTR),Y
         inc16 zptr
         STZ   MAINMEM
         LDA   (zptr)
         STA   (ROWPTR),Y
         inc16 zptr
         <<<

scroll14 MAC
         STZ   AUXMEM
         LDA   (zptr),Y
         STA   (ROWPTR),Y
         STZ   MAINMEM
         LDA   (zptr),Y
         STA   (ROWPTR),Y
         <<<

* draw tile A at X=x/14,Y=y/8, 0-indexed.
* optimized version of core::tile, only works for 28x16 tiles.
* DRAWPTR = pointer to tile data.  zptr,prod,ROWPTR modified.
* Returns starting X in COLUMN.
fstTile  STX   COLUMN
         STA   prod
         STZ   prod+1
         cp16  DRAWPTR;zptr
         LUP   6
         ASL   prod
         ROL   prod+1
         --^
         LDA   #$02
         TSB   prod
         add16 prod;zptr
         LDX   #$10       ; y-pixels
:iniRow  LDA   rowTbLo,Y
         STA   ROWPTR
         LDA   rowTbHi,Y
:nxtRow  STA   ROWPTR+1
         PHY
         LDY   COLUMN
         paint14
         INY
         paint14
         PLY
         DEX
         BEQ   :fin
         CLC
         LDA   ROWPTR+1
         ADC   #$04
         BIT   #$1C
         BNE   :nxtRow
         INY
         BRA   :iniRow
:fin     RTS

* Draw map row starting at (stream) for colCount columns at X,Y.
* It is OK if (stream) points to a ghost cell.
* fac1 and fac2 are a 16-bit mask, 0 = normal cell, 1 = ghost cell.
* Y is preserved.  X,fac1,fac2,colCount,byt modified.
mkrow    STY   byt
:loop    LSR   fac2
         ROR   fac1
         BCS   :bound
         LDA   (stream)
         BRA   :tile
:bound   LDA   #$06
:tile    JSR   fstTile
         inc16 stream
         LDX   COLUMN     ; set by fstTile
         LDY   byt
         INX
         INX
         DEC   colCount
         BNE   :loop
         RTS

* move one row of 14x8 blocks via in-place copy.
* X0,Y is the starting block coordinate.
* DX,DX+1 are offsets to the source blocks.
* colCount is count of columns.
* ROWPTR, zptr, colCount, byt2 are modified.
mvrow    LDA   rowTbLo,Y
         CLC
         ADC   X0
         STA   ROWPTR
         LDA   rowTbHi,Y
         STA   ROWPTR+1
         TYA
         ADC   DX+1
         TAY
         LDA   rowTbLo,Y
         STA   zptr
         LDA   rowTbHi,Y
         STA   zptr+1
         ad816 X0;zptr
         ad816 DX;zptr
         LDX   #$08       ; y-pixels/block
         LDA   DX
         BMI   :nbeg
         SEC
         LDA   colCount
         SBC   DX
         STA   colCount
:prow    LDY   #$00       ; source right, ascending order
:ploop   scroll14
         INY
         CPY   colCount
         BMI   :ploop
         BRA   :nxtrow
:nbeg    DEC   colCount
         LDA   DX
         EOR   #$FF
         INC
         STA   byt2
:nrow    LDY   colCount   ; source left, descending order
:nloop   scroll14
         DEY
         CPY   byt2
         BPL   :nloop
:nxtrow  DEX
         BEQ   :fin
         CLC
         LDA   ROWPTR+1
         ADC   #$04
         STA   ROWPTR+1
         LDA   zptr+1
         ADC   #$04
         STA   zptr+1
         LDA   DX
         BMI   :nrow
         BRA   :prow
:fin     RTS

* Prepare to render a map view from x1,x1+1 to x2,x2+1,
* starting at screen cell X0,X0+1 (14x8 blocks, 0-based).
* Advances stream to the upper-left cell in the view.
* Sets begMVw,endMVw,endMap,endScrn+1,rowCount.
* Increments x2,x2+1, then sets rowAdv to endMap + x1 - x2.
inimap   LDA   (stream)
         STA   endMap
         STA   rowAdv
         STA   fac1
         inc16 stream
         LDA   (stream)
         STA   endMap+1
         inc16 stream
         INC   x2
         INC   x2+1
         LDA   x1+1
         STA   fac2
         BPL   :posy
:negy    sb816 rowAdv;stream
         INC   fac2
         BNE   :negy
         BRA   :horadj
:posy    JSR   mulbb
         add16 prod;stream
:horadj  ad816 x1;stream
         ad816 x1;rowAdv
         sb816 x2;rowAdv
         cp16  x1;begMVw
         cp16  x2;endMVw
         SEC
         LDA   x2+1
         SBC   x1+1
         STA   rowCount
         ASL
         CLC
         ADC   X0+1
         STA   endScrn+1  ; start_row + rowCount*2
         RTS

* Reset X, x1, x2, colCount, and set up the ghost cell bitmask per row.
* X is set to X0, Y is preserved.
inirow   
         cp16  begMVw;x1
         cp16  endMVw;x2
         LDX   X0
         SEC
         LDA   x2
         SBC   x1
         STA   colCount
         STZ   fac1
         STZ   fac2
         SEC
         TYA
         SBC   X0+1
         LSR
         CLC
         ADC   x1+1       ; A = vertical map coord
         BMI   :allout
         CMP   endMap+1
         BPL   :allout
         LDA   x1
         BMI   :lout
         LDA   x2
         DEC
         CMP   endMap
         BPL   :rout
         RTS
:lout    SEC
         ROL   fac1
         ROL   fac2
         INC
         BMI   :lout
         RTS
:rout    LDA   endMap
         SEC
         SBC   #16        ; width of bit mask
         SEC
         SBC   x1         ; A = endMap-16-x1 = -|shifts|
                          ; assumes column count < 16
:rloop   SEC
         ROR   fac2
         ROR   fac1
         INC
         BMI   :rloop
         RTS
:allout  LDA   #$FF
         STA   fac1
         STA   fac2
         RTS

* Draw portion of map at (stream) from x1,x1+1 to x2,x2+1,
* starting at the screen location X0,X0+1 (14x8 blocks, 0-based).
* DX word non-zero triggers an update via scrolling via mvmap.
* Map coords are signed 8-bit, negative numbers are OK.
* Map dimensions are expected to be at (stream),(stream)+1.
* Inputs are undefined upon completion.
submap   ENT
         JSR   inimap
         LDA   DX
         ORA   DX+1
         BNE   mvmap
         LDY   X0+1
:loop    JSR   inirow
         JSR   mkrow
         INY
         INY
         CPY   endScrn+1
         BPL   :fin
         add16 rowAdv;stream
         BRA   :loop
:fin     RTS

* update map by scrolling
mvmap    LDA   DX+1
         BMI   :n1
         LDY   X0+1
         LDA   endScrn+1
         BRA   :bound
:n1      LDY   endScrn+1
         DEY
         LDA   X0+1
:bound   SEC
         SBC   DX+1
         STA   byt
:loop    JSR   inirow
         ASL   colCount
         PHY
         JSR   mvrow
         PLY
         LDA   DX+1
         BMI   :n2
         INY
         CPY   byt
         BMI   :loop
         RTS
:n2      DEY
         CPY   byt
         BPL   :loop
         RTS


* Scroll in window from x1,x1+1 to x2,x2+1 by DX,DX+1 (14x8 blocks).
* DX,DX+1 are offsets to the *source* memory.
* There is no automatic clearing or updating of the boundary tiles.
* DX preserved, other inputs modified, as well as byt.
scroll   ENT
         LDA   x1
         STA   X0
         LDA   DX+1
         JSR   abs8
         STA   byt

         SEC
         LDA   x2+1
         SBC   x1+1
         SBC   byt
         INC
         STA   rowCount

:rowLup  SEC
         LDA   x2
         SBC   x1
         INC
         STA   colCount
         LDA   DX+1
         BMI   :neg
         LDY   x1+1
         INC   x1+1
         BRA   :go
:neg     LDY   x2+1
         DEC   x2+1
:go      JSR   mvrow
         DEC   rowCount
         BEQ   :fin
         BRA   :rowLup
:fin     RTS