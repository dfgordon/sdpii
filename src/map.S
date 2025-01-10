         XC    OFF
         XC
         REL
         DSK   MAP.L

* Subroutines for rendering a map view.
* Rendering a map causes any picture drawing state to be lost.
* Scrolling routines can also be used for DHR text.

         PUT   equiv
         USE   macros

tile     EXT
mulbb    EXT
rowTbHi  EXT
rowTbLo  EXT

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

* draw tile A at X=x/14,Y=y/8.
* optimized version of core::tile, only works for 28x16 tiles.
* DRAWPTR = pointer to tile data.
* expect 0-indexing by this point.
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

* TODO:modify this to work more like mvrow, use 16-bit mask to handle ghost cells.
* Draw map row from column x1 ..< x2, at screen cell X0,X0+1.
* stream should point to the starting map cell.
* x1+1,saveXN, and saveYN are used to handle ghost cells.
mkrow    LDA   x1
:loop    CMP   saveXN
         BCS   :bound
         LDA   x1+1
         CMP   saveYN
         BCS   :bound
         LDA   (stream)
         BRA   :tile
:bound   LDA   #$06
:tile    LDX   X0
         LDY   X0+1
         JSR   fstTile
         inc16 stream
         CLC
         LDA   X0
         ADC   (DRAWPTR)  ; tile width
         STA   X0
         INC   x1
         LDA   x1
         CMP   x2
         BMI   :loop
         RTS

* move one row of 14x8 blocks via in-place copy.
* zptr contains source address, ROWPTR contains destination address.
* COLUMN is count of columns.
* DX sign-bit determines update order.
mvrow    LDA   DX
         BMI   mvneg
mvpos    LDX   #$08       ; y-pixels/tile
:dorow   LDY   #$00       ; source right, ascending order
:loop    scroll14
         INY
         CPY   saveXN
         BNE   :loop
         DEX
         BEQ   :fin
         CLC
         LDA   ROWPTR+1
         ADC   #$04
         STA   ROWPTR+1
         LDA   zptr+1
         ADC   #$04
         STA   zptr+1
         BRA   :dorow
:fin     RTS
mvneg    LDX   #$08       ; y-pixels/tile
:dorow   LDY   saveXN     ; source left, descending order
:loop    DEY
         scroll14
         TYA
         BNE   :loop
         DEX
         BEQ   :fin
         CLC
         LDA   ROWPTR+1
         ADC   #$04
         STA   ROWPTR+1
         LDA   zptr+1
         ADC   #$04
         STA   zptr+1
         BRA   :dorow
:fin     RTS

* Prepare to render a map view from x1,x1+1 to x2,x2+1,
* starting at screen cell X0,X0+1 (14x8 blocks, 0-based).
* Advances stream to the upper-left cell in the view.
* Sets saveXN, saveYN to maximum map coordinates.
* Sets saveX0, savex1 to starting screen/map coordinates.
* Increments x2,x2+1
* Sets rowAdv to saveXN + x1 - x2 (after inc)
inimap   LDA   (stream)
         STA   saveXN
         STA   rowAdv
         STA   fac1
         inc16 stream
         LDA   (stream)
         STA   saveYN
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
         LDA   X0
         STA   saveX0
         LDA   x1
         STA   savex1
         RTS

* Draw portion of map at (stream) from x1,x1+1 to x2,x2+1,
* starting at the screen location X0,X0+1 (14x8 blocks, 0-based).
* Map coords are signed 8-bit, negative numbers are OK.
* Map dimensions are expected to be at (stream),(stream)+1.
* Inputs are undefined upon completion.
submap   ENT
         JSR   inimap
:loop    JSR   mkrow
         CLC
         LDA   X0+1
         LDY   #$01
         ADC   (DRAWPTR),Y
         STA   X0+1
         INC   x1+1
         LDA   x1+1
         CMP   x2+1
         BPL   :fin
         LDA   saveX0
         STA   X0
         LDA   savex1
         STA   x1
         add16 rowAdv;stream
         BRA   :loop
:fin     RTS


* Scroll in window from x1,x1+1 to x2,x2+1 by DX,DX+1 (14x8 blocks).
* DX,DX+1 are offsets to the *source* memory.
* There is no automatic clearing or updating of the boundary tiles.
* Inputs and X00,byt are undefined upon completion.
scroll   ENT
         LDA   DX
         BPL   :p1
         EOR   #$FF
         INC
:p1      STA   X00        ; |DX|
         SEC
         LDA   x2
         SBC   x1
         SBC   X00
         INC
         STA   saveXN     ; horizontal count

         LDA   DX+1
         BPL   :p2
         EOR   #$FF
         INC
:p2      STA   X00+1      ; |DX+1|
         SEC
         LDA   x2+1
         SBC   x1+1
         SBC   X00+1
         INC
         STA   saveYN     ; vertical count

         CLC
         LDA   DX
         BPL   :p3
         LDA   x1
         STA   byt        ; src column 1
         ADC   X00
         STA   x1         ; dest column 1
         BRA   :rowLup
:p3      LDA   x1         ; dest unchanged
         ADC   X00
         STA   byt        ; src column 1

:rowLup  LDA   DX+1
         BPL   :pos
         LDY   x2+1
         DEC   x2+1
         BRA   :go
:pos     LDY   x1+1
         INC   x1+1
:go      LDA   rowTbLo,Y
         STA   ROWPTR
         LDA   rowTbHi,Y
         STA   ROWPTR+1
         ad816 x1;ROWPTR
         TYA
         CLC
         ADC   DX+1
         TAY
         LDA   rowTbLo,Y
         STA   zptr
         LDA   rowTbHi,Y
         STA   zptr+1
         ad816 byt;zptr
         JSR   mvrow
         DEC   saveYN
         BEQ   :fin
         BRA   :rowLup
:fin     RTS

saveXN   DFB   0
saveYN   DFB   0
saveX0   DFB   0
savex1   DFB   0
rowAdv   DA    0
