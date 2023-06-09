         XC
         ORG   $4000

* Ampersand commands for double-hi-res.
* Also an interpreter for binary encoded drawing commands.

* DHR Cursor Notes
* consists of ROWPTR,BITPOS,COLUMN, and state of
* TXTPAGE soft switch (MAIN/AUX memory).
* We re-use some of the HGR cursor locations.

* Token overloads

hcolor_t =     146
hplot_t  =     147
draw_t   =     148
to_t     =     193
at_t     =     197
step_t   =     199
eq_t     =     208
print_t  =     186
less_t   =     $d1
gtr_t    =     $cf

* ZP non-overlapping

zptr     =     $06        ; general ptr
clrMask1 =     $08
clrMask2 =     $09
byt      =     $1e
x1       =     $ce        ; word
y1       =     $d7
byt2     =     $e3
x2       =     $eb        ; word
x3       =     $ed        ; word
byt3     =     $ef
fac1     =     $fa
fac2     =     $fb
prod     =     $fc        ; word
stat     =     $fe        ; AUX flag and general local

* ZP re-using Applesoft HGR locations

CLRBAS1  =     $1c        ; base color mask 1
ROWPTR   =     $26        ; same, word
BITPOS   =     $30        ; same
X0       =     $e0        ; doubled
Y0       =     $e2        ; same
CLRBAS2  =     $e4        ; base color mask 2
COLUMN   =     $e5        ; same (dhr x/14)
PAGE     =     $e6        ; same
DRAWPTR  =     $e8        ; similar
LINNUM   =     $50        ; same, word
DX       =     $d0        ; same, word
DY       =     $d2        ; same
HGRQUAD  =     $d3        ; same
HGRE     =     $d4        ; same, word
HCOUNT   =     $1d        ; same, word
MODE     =     $f9        ; drawing mode

* ROM pointers used by Applesoft

ILLQTY   =     $35        ; ILLEGAL QUANTITY
STRLNG   =     $B0        ; STRING TOO LONG
BADSUB   =     $6B        ; BAD SUBSCRIPT
NODATA   =     $2A        ; OUT OF DATA
ERRFLG   =     $D8
DSCTMP   =     $9D        ; STRING DESC = LEN,LO,HI
INDEX    =     $5E        ; STR PTR
FAC      =     $9D        ; FP ACCUMULATOR
VARPNT   =     $83
LOWTR    =     $9B
TXTPTR   =     $B8
VALTYP   =     $11        ; $00=NUM, $FF=STR
INTFLG   =     $12        ; $00=NO, $80=YES

* ROM routines for parsing and variables

BELL     =     $FF3A
PRBYTE   =     $FDDA
COUT     =     $FDED
DATA     =     $D995
CHRGET   =     $B1
CHRGOT   =     $B7
CHKCOM   =     $DEBE
CHKOPN   =     $DEBB
CHKCLS   =     $DEB8
PTRGET   =     $DFE3
ARYGET   =     $F7D9
FRMEVL   =     $DD7B
NUMEVL   =     $DD67
GETNUM   =     $E746
GETADR   =     $E752
GETBYT   =     $E6F8
STRINI   =     $E3D5
MOVSTR   =     $E5E2
GETSTR   =     $E6DC
SNERR    =     $DEC9
DOERR    =     $D412

* ROM routines for FP

MOVMF    =     $EB2B
MOVFM    =     $EAF9
FLOAT2   =     $EBA0
INT2FP   =     $E2F2

* ROM routines for HGR

HPOSN    =     $F411
MOVUPDWN =     $F4D3
INCRY    =     $F504
DECRY    =     $F4D5
HGR      =     $F3E2
HGRCLR   =     $F3F2

* Other ROM routines

RESTART  =     $D43C
STKINI   =     $D683

* Soft switches

COL80    =     $C00D
RDMAIN   =     $C002
WRMAIN   =     $C004
MAINZP   =     $C008
STOR80   =     $C001
DHR      =     $C05E
GRAPHICS =     $C050
HIRES    =     $C057
MIXED    =     $C053
FULLSCR  =     $C052
MAINMEM  =     $C054
AUXMEM   =     $C055
CHKAUX   =     $C01C

div      MAC
         LDA   ]1
         STA   prod
         LDA   ]2
         STA   prod+1
         LDA   ]3
         STA   fac1
         JSR   divwb
         <<<

swBank   MAC
         LDA   CHKAUX
         EOR   #$80
         ROL
         LDA   #$00
         ROL
         PHX
         TAX
         STA   MAINMEM,X
         PLX
         <<<

swap     MAC
         LDA   ]1
         PHA
         LDA   ]2
         STA   ]1
         PLA
         STA   ]2
         <<<

mkptr    MAC
         LDA   #<]1
         STA   ]2
         LDA   #>]1
         STA   ]2+1
         <<<

cp16     MAC
         LDA   ]1
         STA   ]2
         LDA   ]1+1
         STA   ]2+1
         <<<

inc16    MAC
         INC   ]1
         BNE   incdone
         INC   ]1+1
incdone  <<<

add16    MAC
         CLC
         LDA   ]1
         ADC   ]2
         STA   ]2
         LDA   ]1+1
         ADC   ]2+1
         STA   ]2+1
         <<<

rolClr   MAC
         LDA   clrMask1
         ROL
         ROL   clrMask1
         LDA   clrMask2
         ROL
         ROL   clrMask2
         <<<

rorClr   MAC
         LDA   clrMask1
         ROR
         ROR   clrMask1
         LDA   clrMask2
         ROR
         ROR   clrMask2
         <<<

phCurs   MAC
         LDA   X0
         PHA
         LDA   X0+1
         PHA
         LDA   Y0
         PHA
         <<<

plCurs   MAC
         PLA
         STA   Y0
         PLA
         STA   X0+1
         PLA
         STA   X0
         <<<

* Main Ampersand dispatcher
* KEEP THIS AS THE FIRST ADDRESSABLE ITEM
dispatch LDA   #$80
         BIT   #$02       ; if 65c02 Z=1, 6502 passes over
         BEQ   :cmos
         JMP   cmosErr
:cmos    STA   MAINMEM
         LDA   stat
         BPL   :bit
         STA   AUXMEM

* bit (n,x)
:bit     mkptr ampBit;zptr
         JSR   tryCmd
         BEQ   :iniStk
         JSR   CHKOPN
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
         RTS
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
:err     JMP   SNERR
:ill     LDX   #ILLQTY  
         JMP   DOERR

* inistk
:iniStk  mkptr ampIni;zptr
         JSR   tryCmd
         BEQ   :stkptr
         STZ   stack
         RTS

* stkptr > x
:stkptr  mkptr ampPtr;zptr
         JSR   tryCmd
         BEQ   :psh
         JSR   chkGtr
         JSR   PTRGET
         LDA   VALTYP
         BNE   :err
         LDA   stack
         JSR   saveByt
         RTS

* psh < x
:psh     mkptr ampPh;zptr
         JSR   tryCmd
         BEQ   :pul
         JSR   chkLess
         JSR   GETBYT
         LDY   stack
         INY
         CPY   #$20
         BCC   :goPh
         LDY   #$01
:shftS   LDA   stack+1,Y
         STA   stack,Y
         INY
         CPY   #$1F
         BEQ   :goPh
         BRA   :shftS
:goPh    TXA
         STA   stack,Y
         STY   stack
         RTS

* pul > x
:pul     mkptr ampPl;zptr
         JSR   tryCmd
         BEQ   :stroke
         JSR   chkGtr
         JSR   PTRGET
         LDA   VALTYP
         BNE   :err
         LDY   stack
         BEQ   :noData
         LDA   stack,Y
         DEC   stack
         JSR   saveByt
         RTS
:noData  LDX   #NODATA
         JMP   DOERR
         
* stroke#brush at x,y
:stroke  mkptr ampStk;zptr
         JSR   tryCmd
         BEQ   :mode
         JSR   chkPnd
         JSR   GETBYT
         PHX
         JSR   chkAt
         JSR   GETNUM
         STX   Y0
         cp16  LINNUM;X0
         PLX
         BEQ   :point
         DEX              ; ref brush to 0
         JSR   stroke
         JMP   :close
:point   JSR   plot
         JMP   :close

* mode=x
:mode   mkptr ampMode;zptr
         JSR   tryCmd
         BEQ   :hplot
         JSR   chkEq
         JSR   GETBYT
         STX   MODE
         RTS

* hplot syntax same as HGR
:hplot   mkptr ampLin;zptr
         JSR   tryCmd
         BEQ   :dhr
         LDA   #to_t
         CMP   (TXTPTR)
         BNE   :iniCurs
:loop    JSR   CHRGET
         JSR   GETNUM
         TXA
         TAY
         LDA   LINNUM
         LDX   LINNUM+1
         JSR   lineTo
         LDA   #to_t
         CMP   (TXTPTR)
         BEQ   :loop
         JMP   :close
:iniCurs JSR   GETNUM
         STX   Y0
         cp16  LINNUM;X0
         JSR   setPos
         LDA   #to_t
         CMP   (TXTPTR)
         BEQ   :loop
         JSR   plotc
         JMP   :close

* dhr
:dhr     mkptr ampDHR;zptr
         JSR   tryCmd
         BEQ   :color
         JSR   dhrInit
         RTS

* hcolor = c1[,c2,c3,c4]
:color   mkptr ampClr;zptr
         JSR   tryCmd
         BEQ   :trap
         JSR   GETBYT
         PHX
         CMP   #','
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
         JMP   :close

* trap at x0,x1,y0 to x2,x3,y1
:trap    mkptr ampTrap;zptr
         JSR   tryCmd
         BEQ   :draw

         JSR   chkAt

         JSR   NUMEVL
         JSR   GETADR
         cp16  LINNUM;X0
         JSR   CHKCOM
         JSR   GETNUM
         STX   Y0
         cp16  LINNUM;x1

         JSR   chkTo

         JSR   NUMEVL
         JSR   GETADR
         cp16  LINNUM;x2
         JSR   CHKCOM
         JSR   GETNUM
         STX   y1
         cp16  LINNUM;x3

         JSR   trap
         JMP   :close

* draw at x0,y0
:draw    mkptr ampDraw;zptr
         JSR   tryCmd
         BEQ   :tile
         JSR   chkAt
         JSR   NUMEVL
         JSR   GETADR
         cp16  LINNUM;DX
         JSR   CHKCOM
         JSR   NUMEVL
         JSR   GETADR     ; promote DY to 16 bits
                          ; because we want negative offsets
         STY   DY
         STA   HGRQUAD    ; high, not needed?
         JSR   draw
         JMP   :close

* tile #A at X,Y (X=X0/14+1, Y=Y0/8+1)
:tile    mkptr ampTile;zptr
         JSR   tryCmd
         BEQ   :print
         JSR   chkPnd
         JSR   GETBYT
         PHX
         JSR   chkAt
         JSR   GETNUM
         TXA
         TAY
         LDA   LINNUM
         TAX
         PLA
         DEX
         DEY
         JSR   tile
         JMP   :close

* print sexpr at X,Y (X=X0/14+1, Y=Y0/8+1)
:print   mkptr ampPrint;zptr
         JSR   tryCmd
         BEQ   :none
         JSR   FRMEVL
         JSR   GETSTR
         LDA   INDEX
         PHA
         LDA   INDEX+1
         PHA
         STY   stat
         JSR   chkAt
         JSR   GETNUM
         TXA
         TAY
         LDA   LINNUM
         TAX
         DEX
         DEY
         PLA
         STA   INDEX+1
         PLA
         STA   INDEX
         LDA   stat
         JSR   print
         JMP   :close

:close   LDA   CHKAUX
         STA   stat
         STZ   MAINMEM
         RTS
:none    JMP   SNERR      ; no command was recognized


* Check for command, str at (zptr) must terminate in null
* If no match TXTPTR is rewound
tryCmd   LDA   TXTPTR
         PHA
         LDA   TXTPTR+1
         PHA
         LDY   #$00
         JSR   CHRGOT
:loop    BMI   :chk
         CMP   #$61
         BCC   :chk
         AND   #%11011111 ; to upper (must be letter)
:chk     CMP   (zptr),Y
         BEQ   :match
         PLA
         STA   TXTPTR+1
         PLA
         STA   TXTPTR
         LDA   #$00
         RTS
:match   INY
         LDA   (zptr),Y
         BEQ   :fin
         JSR   CHRGET
         JMP   :loop
:fin     PLA
         PLA
         JSR   CHRGET     ; advance to next
         LDA   #$01
         RTS

chkPnd   LDA   #'#'
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

* save A in the last variable
saveByt  TAY
         LDA   #$00
         JSR   INT2FP
         LDX   VARPNT
         LDY   VARPNT+1
         JSR   MOVMF
         RTS

* Initialize double hi-res and DHRLIB.
* Assumes PR#3 already done.
dhrInit  JSR   HGR
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
         RTS

* Set color mask at ZP address Y to A + 16*X.
* If X>15 or A>15 throw error.
setClr   CPX   #$10
         BCS   :err
         CMP   #$10
         BCS   :err
         STA   $00,Y
         TXA
         ASL
         ASL
         ASL
         ASL
         ORA   $00,Y    
         STA   $00,Y
         RTS
:err     LDX   #ILLQTY
         JMP   DOERR

* plot one pixel with color and mode mask
plot     JSR   setPos     ; plot at X0,Y0 (slow)
plotc    PHP              ; plot at cursor (faster)
         PHX
         PHY
         LDY   COLUMN
         LDA   MODE
         BPL   :dither
         LDA   #$FF
         BRA   :pix
:dither  LDA   ROWPTR+1
         AND   #%100
         LSR
         LSR
         TAX              ; X selects color by row
         LDA   (ROWPTR),Y
         EOR   clrMask1,X ; 0 ^ 1=wanted -> 1=flip
                          ; 0 ^ 0=unwanted -> 0=leave
                          ; 1 ^ 1=wanted -> 0=leave
                          ; 1 ^ 0=unwanted -> 1=flip
:pix     AND   BITPOS
         EOR   (ROWPTR),Y
         STA   (ROWPTR),Y
         PLY
         PLX
         PLP
         RTS

* Prepare line from cursor to A+X*256,Y.
* Sets X, Y, X0, Y0, DX, DY, HGRQUAD, HGRE, HCOUNT.
iniLine  PHA              ; x1 low
         SEC              ; prepare dx
         SBC   X0
         PHA              ; dx low
         TXA              ; x1 high
         SBC   X0+1
         STA   HGRQUAD    ; dx high
         BCS   :dxpos
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
         JSR   setPos
         PLY
         PLX
         PLA
* Draw line from cursor to A+X*256,Y.
* Cursor,X0,Y0 are updated.
* adapted from similar HGR routine
lineTo   JSR   iniLine
         BRA   :movx2
:movx1l1 ASL              ; iterate main loop
         JSR   movHor
         SEC
:movx2   LDA   HGRE       ; init main loop
         ADC   DY
         STA   HGRE
         LDA   HGRE+1
         SBC   #$00
:movx3l2 STA   HGRE+1
         JSR   plotc
         INX
         BNE   :movx4
         INC   HCOUNT
         BEQ   :fin
:movx4   LDA   HGRQUAD
         BCS   :movx1l1
         JSR   MOVUPDWN
         CLC
         LDA   HGRE
         ADC   DX
         STA   HGRE
         LDA   HGRE+1     
         ADC   DX+1
         BRA   :movx3l2
:fin     RTS

* Calculate x-offsets for trapezoid.
* Same as lineTo, but save data instead of drawing.
* Destroys stat and byt, data goes to (zptr)
calcOff  JSR   iniLine
         STZ   byt
         STZ   stat
         BRA   :movx2
:movx1l1 ASL              ; iterate main loop
         BMI   :dec
         INC   byt
         BRA   :cont
:dec     DEC   byt
:cont    SEC
:movx2   LDA   HGRE       ; init main loop
         ADC   DY
         STA   HGRE
         LDA   HGRE+1
         SBC   #$00
:movx3l2 STA   HGRE+1
         INX
         BNE   :movx4
         INC   HCOUNT
         BEQ   :fin
:movx4   LDA   HGRQUAD
         BCS   :movx1l1
         PHY
         LDY   stat
         LDA   byt
         STA   (zptr),Y  ; TODO: bounds check
         INC   stat
         PLY
         CLC
         LDA   HGRE
         ADC   DX
         STA   HGRE
         LDA   HGRE+1     
         ADC   DX+1
         BRA   :movx3l2
:fin     RTS

* draw horizontal line from X0,Y0 to A+X*256,Y0.
* cursor updated. X0,Y0 unchanged. DX has A+X*256-X0+1
hline    SEC
         SBC   X0
         STA   DX
         TXA
         SBC   X0+1
         STA   DX+1
         inc16 DX
         JSR   setPos
hlineTo  cp16  DX;HCOUNT
         LDA   HCOUNT+1
         STA   HGRQUAD
         BMI   :go
         EOR   #$FF
         STA   HCOUNT+1
         LDA   HCOUNT
         EOR   #$FF
         STA   HCOUNT
         inc16 HCOUNT
:go      JSR   plotc
         inc16 HCOUNT
         LDA   HCOUNT
         BNE   :cont
         LDA   HCOUNT+1
         BNE   :cont
         RTS
:cont    LDA   HGRQUAD    ; set N
         JSR   movHor
         BRA   :go

* Move cursor horizontally. No bounds check. X0 unchanged.
* Direction given by N.  For vertical use ROM.
movHor   BMI   decHor
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
         LDA   CHKAUX
         BMI   :same40c
         INC   COLUMN
:same40c swBank
         RTS
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
         LDA   CHKAUX
         BPL   :same40c
         DEC   COLUMN
:same40c swBank
         RTS
     
* Set DHR cursor using X0,Y0.
* Cursor means ROWPTR, COLUMN, BITPOS, clrMask1, clrMask2.
setPos   LDA   X0
         PHA
         LDA   X0+1
         PHA
         LDA   CLRBAS1    ; HPOSN will corrupt
         PHA
         STA   AUXMEM
         div   X0;X0+1;#$07
         STA   X0         ; save remainder
         LDA   fac2       ; x/7 = column 0..79
         AND   #$07
         PHA              ; save column%8
         LDA   fac2
         BIT   #$01
         BEQ   :even
         STA   MAINMEM
* Use HPOSN to set compatible cursor elements
:even    LSR   fac2       ; column 0..39
         LDA   fac2
         JSR   mul7
         CLC
         LDA   prod
         ADC   X0
         TAX
         LDA   prod+1
         ADC   #$00
         TAY
         LDA   Y0
         JSR   HPOSN      ; sets ROWPTR, BITPOS, COLUMN
* Setup the DHR color mask.
         PLA              ; column%8
         TAY
         PLA
         STA   CLRBAS1
         STA   clrMask1
         LDA   CLRBAS2
         STA   clrMask2
         CPY   #$00
:loop    BEQ   :cleanup
         rolClr
         DEY
         BRA   :loop
:cleanup PLA
         STA   X0+1
         PLA
         STA   X0
         RTS

* Fill a trapezoid using horizontal lines
* upper segment is X0,x1,Y0.
* lower segment is x2,x3,y1
trap     phCurs
         JSR   setPos
         mkptr leftBuf;zptr
         LDA   x2
         LDX   x2+1
         LDY   y1
         JSR   calcOff
         cp16  x1;X0
         PLA
         STA   Y0
         PHA
         JSR   setPos
         mkptr rightBuf;zptr
         LDA   x3
         LDX   x3+1
         LDY   y1
         JSR   calcOff
         plCurs

* use x2,x3 to save starting X0,x1
         cp16  X0;x2
         cp16  x1;x3

         LDY   #$00
:loop    PHY
         LDA   x1
         LDX   x1+1
         LDY   Y0
         JSR   hline
         PLY
         STZ   fac1
         LDA   leftBuf,Y
         BPL   :adjLeft
         LDA   #$FF
         STA   fac1
:adjLeft CLC
         LDA   x2
         ADC   leftBuf,Y
         STA   X0
         LDA   x2+1
         ADC   fac1
         STA   X0+1
         STZ   fac1
         LDA   rightBuf,Y
         BPL   :adjRght
         LDA   #$FF
         STA   fac1
:adjRght CLC
         LDA   x3
         ADC   rightBuf,Y
         STA   x1
         LDA   x3+1
         ADC   fac1
         STA   x1+1
         INC   Y0
         INY
         LDA   y1
         CMP   Y0
         BCS   :loop
         RTS

* Stroke brush X at X0,Y0
stroke   PHX              ; brush
         JSR   setPos
* setup zptr
         mkptr brushes;zptr
         PLA
         ASL
         TAY
         CLC
         LDA   brushTbl+1,Y
         ADC   zptr
         STA   zptr
         LDA   brushTbl,Y
         ADC   zptr+1
         STA   zptr+1
* setup iterations
         LDY   #$00
         LDA   (zptr),Y
         STA   DX
         INY
         LDA   (zptr),Y
         STA   DY
:loopy   LDX   #$00
:nextCol INY
         LDA   (zptr),Y
         STA   stat
:loopx   ASL   stat
         BCC   :nextx
         JSR   plotc
:nextx   INX
         CPX   DX
         BEQ   :nexty
         JSR   incHor
         TXA
         BIT   #$07
         BEQ   :nextCol
         BRA   :loopx
:nexty   DEC   DY
         BEQ   :fin
         INC   Y0
         PHY
         JSR   setPos
         PLY
         BRA   :loopy
:fin     RTS
         
* Render a binary coded drawing with offset DX,DY.
* Can call itself recursively.
draw     cp16  DRAWPTR;zptr
:go      LDA   DY         ; stash data
         PHA
         LDA   DX
         PHA
         LDA   DX+1
         PHA
         LDA   zptr
         PHA
         LDA   zptr+1
         PHA
         LDY   #$00
         LDA   (zptr),Y
         BNE   :mode
:color   INY              ; code,mask1,mask2
         LDA   (zptr),Y
         STA   CLRBAS1
         INY
         LDA   (zptr),Y
         STA   CLRBAS2
         JMP   :next
:mode    CMP   #$01
         BNE   :draw
         INY              ; code,flags
         LDA   (zptr),Y
         STA   MODE
         JMP   :next
:draw    CMP   #$02
         BNE   :plot
         INY              ; TBD
         LDA   (zptr),Y
         PHA
         INY
         LDA   (zptr),Y
         STA   zptr+1
         PLA
         STA   zptr
         JSR   :go
         JMP   :next
:plot    CMP   #$03
         BNE   :hline
         JSR   :getxy     ; code,xl,xh,y
         JSR   plot
         JMP   :next
:hline   CMP   #$04
         BNE   :line
         JSR   :getxy     ; code,x1l,x1h,y,x2l,x2h 
         JSR   :getx
         JSR   hline
         JMP   :next
:line    CMP   #$05
         BNE   :trap
         JSR   :getxy     ; code,x21,x2h,y2,x1l,x1h,12
         LDA   X0
         PHA
         LDA   X0+1
         PHA
         LDA   Y0
         PHA
         JSR   :getxy
         PLY
         PLX
         PLA
         JSR   line
         JMP   :next
:trap    CMP   #$06
         BNE   :stroke
         JSR   :getxy     ; code,x0l,x0h,y0,x1l,x1h,x2l,x2h,y1,x3l,x3h
         JSR   :getx
         STA   x1
         STX   x1+1
         phCurs
         JSR   :getxy
         cp16  X0;x2
         LDA   Y0
         STA   y1
         JSR   :getx
         STA   x3
         STX   x3+1
         plCurs
         JSR   trap
         JMP   :next
:stroke  CMP   #$07
         BNE   :err
         JSR   :getxy     ; code,xl,xh,y,brush
         INY
         LDA   (zptr),Y
         TAX
         DEX
         JSR   stroke
         JMP   :next
:err     LDX   #ILLQTY
         JMP   DOERR
:getx    INY              ; get into A+256*X
         CLC
         LDA   (zptr),Y
         ADC   DX
         PHA
         INY
         LDA   (zptr),Y
         ADC   DX+1
         TAX
         PLA
         RTS
:getxy   INY              ; get into Y0,X0
         CLC
         LDA   (zptr),Y
         ADC   DX
         STA   X0
         INY
         LDA   (zptr),Y
         ADC   DX+1
         STA   X0+1
         INY
         CLC
         LDA   (zptr),Y
         ADC   DY
         STA   Y0
         RTS
:next    PLA
         STA   zptr+1
         PLA
         STA   zptr
         PLA              ; restore offset
         STA   DX+1
         PLA
         STA   DX
         PLA
         STA   DY
         LDA   (zptr)
         TAX
         CLC
         LDA   zptr
         ADC   cmdLen,X
         STA   zptr
         LDA   zptr+1
         ADC   #$00
         STA   zptr+1
         LDA   (zptr)
         BMI   :exit
         JMP   :go
:exit    RTS

* draw tile A at X=x/14,Y=y/8, tile size <= 255
* x1 = pointer to map data, DRAWPTR = pointer to tile data
* expect 0-indexing by this point
tile     PHA
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
         LDX   #ILLQTY
         JSR   DOERR
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

:loopx   LDA   (zptr)
         PHY
         LDY   COLUMN
         STZ   AUXMEM
         STA   (ROWPTR),Y
         PLY
         inc16 zptr

         LDA   (zptr)
         PHY
         LDY   COLUMN
         STZ   MAINMEM
         STA   (ROWPTR),Y
         PLY
         inc16 zptr

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
print    STA   stat
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
         INC   byt
         DEC   stat
         BNE   :loop
         RTS
         
* Divide a word by a byte, assuming result is a byte
* fac2 = prod / fac1, A = prod % fac1, prod is destroyed
divwb    STZ   fac2
         LDA   prod+1
         LDY   #$08
         SEC
         SBC   fac1
:loop    PHP
         ROL   fac2
         ASL   prod
         ROL
         PLP
         BCC   :clr
         SBC   fac1
         BRA   :set1
:clr     ADC   fac1
:set1    DEY
         BNE   :loop
         BCS   :set2
         ADC   fac1
         CLC
:set2    ROL   fac2
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

* prod = 7*A, saves A in fac1, destroys A
mul7     STA   fac1
         STA   prod
         STZ   prod+1
         CLC
         ROL   prod
         ROL   prod+1
         ROL   prod
         ROL   prod+1
         ROL   prod
         ROL   prod+1     ; prod = 8*A
         SEC
         LDA   prod
         SBC   fac1
         STA   prod
         LDA   prod+1
         SBC   #$00
         STA   prod+1
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

ampDHR   ASC   'DHR',00
ampStk   ASC   'STROKE',00
ampMode  ASC   'MODE',00
ampLin   DFB   hplot_t,0
ampClr   DFB   hcolor_t,0
ampTrap  ASC   'TRAP',00
ampDraw  DFB   draw_t,0
ampTile  ASC   'TILE',00
ampPrint DFB   print_t,0
ampBit   ASC   'BIT',00
ampIni   ASC   'INISTK',00
ampPtr   ASC   'STKPTR',00
ampPh    ASC   'PSH',00
ampPl    ASC   'PUL',00

noCMOS   ASC   "DHRLIB REQUIRES 65C02",00

* Offset to the next draw code.
* (color,mode,draw,plot,hline,line,fill,stroke)
cmdLen   HEX   03,02,03,04,06,07,0B,05

brushTbl HEX   00000005000b001700310051009e0118012e016c017a
brushes  HEX   0403f0f0f0
         HEX   0804ffffffff
         HEX   0c057fe0fff0fff0fff07fe0
         HEX   12081ffe007fff80ffffc0ffffc0ffffc0ffffc07fff
         HEX   801ffe00
         HEX   180a07ffe03ffffc7ffffeffffffffffffffffffffff
         HEX   ff7ffffe3ffffc07ffe0
         HEX   240f007fffe00003fffffc000fffffff003fffffffc0
         HEX   7fffffffe0fffffffff0fffffffff0fffffffff0ffff
         HEX   fffff0fffffffff07fffffffe03fffffffc00fffffff
         HEX   0003fffffc00007fffe000
         HEX   30140003ffffc000003ffffffc0001ffffffff8007ff
         HEX   ffffffe01ffffffffff83ffffffffffc7ffffffffffe
         HEX   ffffffffffffffffffffffffffffffffffffffffffff
         HEX   ffffffffffffffffffffffffffff7ffffffffffe3fff
         HEX   fffffffc1ffffffffff807ffffffffe001ffffffff80
         HEX   003ffffffc000003ffffc000
         HEX   0c0a3fc07fe0fff0fff0fff0fff0fff0fff07fe03fc0
         HEX   181401ff8007ffe01ffff83ffffc7ffffe7ffffeffff
         HEX   ffffffffffffffffffffffffffffffffffffffffffff
         HEX   7ffffe7ffffe3ffffc1ffff807ffe001ff80
         HEX   18043ffffcffffffffffff3ffffc
         HEX   3008007ffffffe000ffffffffff07ffffffffffeffff
         HEX   ffffffffffffffffffff7ffffffffffe0ffffffffff0
         HEX   007ffffffe00

* buffers for trapezoid fills and undo stack
         
leftBuf  DS    $100
rightBuf DS    $100
stack    DS    $20

* table of tile row addresses

rowTbHi  HEX   202021212222232320202121222223232020212122222323
rowTbLo  HEX   008000800080008028a828a828a828a850d050d050d050d0
