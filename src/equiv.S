* Conditional assembly

_safe    =     1          ; protect memory
_wrap    =     1          ; wrap cursor
_bound   =     1          ; bounds check &s
_builder =     1          ; enable pic encoding
maxBrsh  =     7

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
new_t    =     $bf
end_t    =     $80
del_t    =     $85
pop_t    =     $a1
stop_t   =     $b3

* ZP non-overlapping (0-5 ok for temp)
stream   =     $00        ; stream ptr
lkAhed   =     $02
lkBack   =     $03
bitPtr   =     $04
byt      =     $05
zptr     =     $06        ; general ptr
clrMask1 =     $08
clrMask2 =     $09
byt2     =     $1e
x1       =     $ce        ; word
y1       =     $d7
byt3     =     $e3
x2       =     $eb        ; word
x3       =     $ed        ; word
byt4     =     $ef
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
X00      =     $50        ; LINNUM, word
DX       =     $d0        ; same, word
DY       =     $d2        ; same
HGRQUAD  =     $d3        ; same
HGRE     =     $d4        ; same, word
HCOUNT   =     $1d        ; same, word
MODE     =     $f9        ; drawing mode

* ZP used by Applesoft

ILLQTY   =     $35        ; ILLEGAL QUANTITY
STRLNG   =     $B0        ; STRING TOO LONG
BADSUB   =     $6B        ; BAD SUBSCRIPT
NODATA   =     $2A        ; OUT OF DATA
BADTYP   =     $A3        ; TYPE MISMATCH
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
CHRGET   =     $00B1
CHRGOT   =     $00B7
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
BITTAB   =     $F5B2

* Other ROM routines

RESTART  =     $D43C
STKINI   =     $D683
WAITRET  =     $FD5A

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
