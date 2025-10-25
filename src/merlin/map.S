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

* We also have to distinguish between screen cells (14x8) and
* map tiles (28x16).  A map tile can be thought of as composed of
* four screen cells.  The tile's coordinate on the map, and location
* on the screen, must not be confused.

         PUT   equiv
         USE   macros

mulbb    EXT
rowTbHi  EXT
rowTbLo  EXT
get_den  EXT

         DO    _tile/2
begMVw   DFB   0,0        ; start of view in map coords (tiles)
endMVw   DFB   0,0        ; end of view in map coords (tiles)
sizMVw   DFB   0,0        ; size of view in tiles
cntMVw   DFB   0,0        ; countdown of tiles in view
endMap   DFB   0,0        ; total map dimensions in tiles
endScrn  DFB   0,0        ; end of view in screen coords (cells)
rowAdv   DA    0
avatar   ENT
         DFB   0
ghost    DFB   0
* order matters : west,east,south,north
west     DFB   0
east     DFB   8
south    DFB   4
north    DFB   9
         FIN

         DO    _tile/2

* draw tile A at X=x/14,Y=y/8, 0-indexed.
* optimized version of core::tile, only works for 28x16 tiles.
* DRAWPTR = pointer to tile data without header, must be aligned.
* prod,ROWPTR modified.
* If DRAWPTR in ZP use stashed tiles in bank 2.
* Returns starting X in COLUMN, preserves Y.
fstTile  STX   COLUMN
         STA   prod+1
         STZ   prod
         LDA   RDBNK2
         cp16  DRAWPTR;:addr1+1
         BNE   :offset
         mkptr $D400;:addr1+1
:offset  LUP   2
         LSR   prod+1
         ROR   prod
         --^
         add16 prod;:addr1+1
         cp16  :addr1+1;:addr2+1
         CLC
         STZ   AUXMEM
         LDX   #$1F
         JSR   :dopage
         STZ   MAINMEM
         CLC
         LDA   :addr1+1
         ADC   #$20
         STA   :addr1+1
         STA   :addr2+1
         LDX   #$1F
         JSR   :dopage
         LDA   RDROM
         RTS

:dopage  PHY
:iniRow  LDA   rowTbLo,Y
         STA   ROWPTR
         LDA   rowTbHi,Y
         LDY   COLUMN
:nxtRow  STA   ROWPTR+1
:addr1   LDA   $FFFF,X    ; variable operand
         STA   (ROWPTR),Y
         INY
         DEX
:addr2   LDA   $FFFF,X    ; variable operand
         STA   (ROWPTR),Y
         DEY
         DEX
         BMI   :ret
         LDA   ROWPTR+1
         ADC   #$04
         BIT   #$1C
         BNE   :nxtRow
         PLY
         PHY
         INY
         BRA   :iniRow
:ret     PLY
         RTS

* Draw map row starting at (stream) for cntMVw+0 tiles at X,Y.
* It is OK if (stream) points to a ghost cell.
* fac1 and fac2 are a 16-bit mask, 0 = normal cell, 1 = ghost cell.
* Y is preserved.  X,fac1,fac2,cntMVw+0 modified.
mkrow
:loop    LSR   fac2
         ROR   fac1
         BCS   :bound
         LDA   cntMVw+1
         BNE   :normal
         LDA   sizMVw+0
         LSR
         INC
         CMP   cntMVw+0
         BNE   :normal
         LDA   avatar
         BRA   :tile
:normal  LDA   (stream)
         BMI   :denizen
         BRA   :tile
:denizen PHY
         JSR   get_den
         PLY
         BRA   :tile
:bound   LDA   ghost
:tile    JSR   fstTile
         inc16 stream
         LDX   COLUMN     ; set by fstTile
         INX
         INX
         DEC   cntMVw+0
         BNE   :loop
         RTS

* Prepare to render a map view from x1,x1+1 to x2,x2+1,
* starting at screen cell X0,X0+1 (14x8 blocks, 0-based).
* Advances stream to the upper-left cell in the view.
* Sets begMVw,endMVw,endMap,endScrn+1,cntMVw+1.
* Increments x2,x2+1, then sets rowAdv to endMap + x1 - x2.
inimap   LDA   (stream)
         STA   endMap
         STA   rowAdv
         STZ   rowAdv+1
         STA   fac1
         inc16 stream
         LDA   (stream)
         STA   endMap+1
         inc16 stream

         LDX   #3
:rdbnd   LDA   (stream)
         STA   west,X
         inc16 stream
         DEX
         BPL   :rdbnd

         INC   x2
         INC   x2+1
         LDA   x1+1
         STA   fac2
         BPL   :posy
:negy    subu8 rowAdv;stream
         INC   fac2
         BNE   :negy
         BRA   :horadj
:posy    JSR   mulbb
         add16 prod;stream
:horadj  addi8 x1;stream
         addi8 x1;rowAdv
         SEC
         LDA   rowAdv
         SBC   x2
         STA   rowAdv
         LDA   rowAdv+1
         SBC   #$00
         STA   rowAdv+1
         cp16  x1;begMVw
         cp16  x2;endMVw
         SEC
         LDA   x2+1
         SBC   x1+1
         STA   cntMVw+1
         ASL
         CLC
         ADC   X0+1
         STA   endScrn+1  ; start_row + rowCount*2
         RTS

* Reset X, x1, x2, endScrn+0, cntMVw+0, sizMVw+0,
* and set up the ghost cell bitmask per row.
* For any row there can be only one ghost type.
* The ghost type is set to north, south, east, or west.
* X is set to X0, Y is preserved.
inirow   
         cp16  begMVw;x1
         cp16  endMVw;x2
         LDX   X0
         SEC
         LDA   x2
         SBC   x1
         STA   cntMVw+0
         STA   sizMVw+0
         ASL
         CLC
         ADC   X0
         STA   endScrn
         STZ   fac1
         STZ   fac2
         SEC
         TYA
         SBC   X0+1
         LSR
         CLC
         ADC   x1+1       ; A = vertical map coord
         CMP   endMap+1
         BCC   :chkEW
         CMP   #$F0
         BCC   :south
*north
         LDA   north
         STA   ghost
         BRA   :allout
:south   LDA   south
         STA   ghost
:allout  LDA   #$FF
         STA   fac1
         STA   fac2
         RTS

:chkEW   LDA   x1
         BMI   :west
         LDA   x2
         DEC
         CMP   endMap
         BCS   :east
         RTS
:west    SEC
         ROL   fac1
         ROL   fac2
         INC
         BMI   :west
         LDA   west
         STA   ghost
         RTS
:east    LDA   endMap
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
         LDA   east
         STA   ghost
         RTS

* Draw portion of map at (stream) from x1,x1+1 to x2,x2+1,
* starting at the screen location X0,X0+1 (14x8 blocks, 0-based).
* Map coords are signed 8-bit, negative numbers are OK.
* Map dimensions are expected to be at (stream),(stream)+1.
* Inputs are undefined upon completion.
submap   ENT
         JSR   inimap
         LDY   X0+1
         LSR   cntMVw+1
:loop    JSR   inirow
         JSR   mkrow
         DEC   cntMVw+1
         INY
         INY
         CPY   endScrn+1
         BPL   :fin
         add16 rowAdv;stream
         BRA   :loop
:fin     RTS

         FIN
