         XC    OFF
         XC
         REL
         DSK   SCROLL.L

         PUT   equiv
         USE   macros

scroll14 MAC
         STZ   AUXMEM
         LDA   (zptr),Y
         STA   (ROWPTR),Y
         STZ   MAINMEM
         LDA   (zptr),Y
         STA   (ROWPTR),Y
         <<<

         DO    _scroll

abs8     EXT
rowTbLo  EXT
rowTbHi  EXT
cntMVw   DFB   0,0        ; countdown of tiles in view

* move one row of 14x8 cells via in-place copy.
* X0,Y is the starting block coordinate.
* DX,DX+1 are offsets to the source blocks.
* cntMVw+0 is count of cells (not tiles).
* ROWPTR, zptr, cntMVw+0, byt are modified.
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
         addu8 X0;zptr
         addi8 DX;zptr
         LDX   #$08       ; y-pixels/block
         LDA   DX
         BMI   :nbeg
         SEC
         LDA   cntMVw+0
         SBC   DX
         STA   cntMVw+0
:prow    LDY   #$00       ; source right, ascending order
:ploop   scroll14
         INY
         CPY   cntMVw+0
         BMI   :ploop
         BRA   :nxtrow
:nbeg    DEC   cntMVw+0
         LDA   DX
         EOR   #$FF
         INC
         STA   byt
:nrow    LDY   cntMVw+0   ; source left, descending order
:nloop   scroll14
         DEY
         CPY   byt
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
         STA   cntMVw+1

:rowLup  SEC
         LDA   x2
         SBC   x1
         INC
         STA   cntMVw+0
         LDA   DX+1
         BMI   :neg
         LDY   x1+1
         INC   x1+1
         BRA   :go
:neg     LDY   x2+1
         DEC   x2+1
:go      JSR   mvrow
         DEC   cntMVw+1
         BEQ   :fin
         BRA   :rowLup
:fin     RTS

         FIN