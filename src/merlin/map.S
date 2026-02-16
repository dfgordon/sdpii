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

* These are saved in the input buffer with the submap,
* this way external code can more easily find them.
endSub   EQU   $200       ; word
begPtr   EQU   $202       ; word
endMap   EQU   $204       ; word
subDat   EQU   $206

         DO    _tile/2
avCell   DFB   0,0        ; cell indices of the avatar
endCell  DFB   0,0        ; cell indices at end of view
avatar   ENT
         DFB   0
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
* TODO: maybe can simplify, no longer need to return anything
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

* Replace tile with avatar or denizen as needed.
replace  PHA              ; stash terrain
         LDA   x1
         INC
         CMP   avCell
         BNE   :noAv
         LDA   x1+1
         INC
         CMP   avCell+1
         BNE   :noAv
         PLA
         LDA   avatar
         RTS
:noAv    PLA
         BMI   :denizen
         RTS
:denizen addu8 fac1;stream
         JSR   get_den
         PHA
         subu8 fac1;stream
         PLA
         RTS

* Multiply fac1:u8 by fac2:i8 using a naive method,
* actually should be effective for the case we have.
mului    LDA   fac2
         BMI   :neg
         JSR   mulbb
         RTS
:neg     STZ   prod
         STZ   prod+1
         LDX   fac2
:loop    subu8 fac1;prod
         INX
         BMI   :loop
         RTS

* Copy submap from x1,x1+1 to x2,x2+1 into the input buffer,
* where (stream) should point to the map level header.
* The submap view is allowed to be partly out of bounds, in which
* case the N, S, E, W boundary tiles will be used as needed.
* Sets endMap, increments x2/x2+1, disturbs stream.
* Handling boundaries requires care since we have 8-bit signed
* integers in an environment with up to 128x128 maps.
makemap  ENT
         LDA   (stream)
         STA   endMap
         inc16 stream
         LDA   (stream)
         STA   endMap+1
         inc16 stream
* header for submap (hdim,vdim)
         INC   x2
         INC   x2+1
         SEC
         LDA   x2
         SBC   x1
         STA   endSub
         SEC
         LDA   x2+1
         SBC   x1+1
         STA   endSub+1
* load the boundary conditions
         LDX   #3
:rdbnd   LDA   (stream)
         STA   west,X
         inc16 stream
         DEX
         BPL   :rdbnd
* advance stream to starting row and set begPtr
         LDA   endMap
         STA   fac1       ; u8
         LDA   x1+1
         STA   fac2       ; i8
         JSR   mului
         add16 prod;stream
         cp16  stream;begPtr
         addi8 x1;begPtr
* start main loop over y
         LDX   #0
         LDY   x1+1
:loopy   CPY   #$F0
         BCS   :north
         CPY   x2+1
         BCS   :fin
         CPY   endMap+1
         BCS   :south
         PHY              ; save outer loop Y
         LDY   x1         ; init inner loop Y
:loopx   CPY   #$F0
         BCS   :west
         CPY   x2
         BCS   :nexty
         CPY   endMap
         BCS   :east
         LDA   (stream),Y
:wrt     STA   subDat,X
         INX
         INY
         BRA   :loopx
:west    LDA   west
         BRA   :wrt
:east    LDA   east
         BRA   :wrt
:nexty   addu8 endMap;stream
         PLY              ; restore outer loop y
         INY              ; advance *and* set flags
         BRA   :loopy
:fin     RTS
* handle full rows of ghost cells
:north   LDA   north
         BRA   :ghosts
:south   LDA   south
:ghosts  PHY
         LDY   x1
:loopx2  STA   subDat,X
         INX
         INY
         CPY   x2
         BMI   :loopx2
         BRA   :nexty

* Draw the submap currently in the input buffer
* at screen coordinate X0,X0+1 (14x8 cells, 0-based).
drawmap  ENT
         cp16  begPtr;stream
         cp16  endSub;endCell
         cp16  endSub;avCell
         add16 X0;avCell  ; 2 8-bit adds
         ASL   endCell
         ASL   endCell+1
         add16 X0;endCell ; 2 8-bit adds
         cp16  X0;x1
         LDX   #0
         STZ   fac1       ; track column offset in tile units
:loop    LDA   subDat,X
         PHX
         JSR   replace
         LDX   x1
         LDY   x1+1
         JSR   fstTile
         PLX
         INX
         INC   fac1
         LDA   x1
         INC
         INC
         STA   x1
         CMP   endCell
         BMI   :loop
         addu8 endMap;stream
         STZ   fac1
         LDA   X0
         STA   x1
         LDA   x1+1
         INC
         INC
         STA   x1+1
         CMP   endCell+1
         BMI   :loop
         RTS

         FIN
