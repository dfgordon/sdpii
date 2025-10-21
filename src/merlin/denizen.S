         XC    OFF
         XC
         REL
         DSK   DENIZEN.L

* Subroutines for handling denizen records.
* The high bit in a map byte indicates there is something "on top" of the tile.
* The map renderer then has to lookup this denizen and render its tile in place
* of the terrain underneath.  Denizens are sorted by their offset into the map.
* 
* Denizen count is assumed to be at most 63.
* At this level denizens are static, if movement is needed higher level code must provide.
*
* DENIZEN HEADER AND RECORDS
* offset | data | length
* -------|------|-------
* 0 | denizen count | 1
* 1 | reserved | 3
* 4 | record 1 | 4
* ... | ... | ...
* 4*n | record n | 4
* 
* ONE DENIZEN RECORD
* offset | data | length
* -------|------|-------
* 0 | offset-lo | 1
* 1 | offset-hi | 1
* 2 | tile | 1
* 3 | aux | 1

         PUT   equiv
         USE   macros

         DO    _tile/2

denizens ENT              ; variable pointer to denizen records
         DA    $0000
xmap     ENT              ; variable pointer to extended map
         DA    $0000

* Setup for denizen operations. Returns:
* zptr points to denizens,
* prod=zptr+A, where A is signed
* A=stat=denizen count,
* status bits reflect denizen count
setup    STA   stat
         cp16 denizens;zptr
         cp16 zptr;prod
         addi8 stat;prod
         LDA   (zptr)
         STA   stat
         RTS

* Delete a denizen at map offset X00.
* Changes zptr, prod, stat.
del_den  ENT
         JSR   search
         BMI   :fin
         LDA   stat
         ASL
         ASL
         STA   X00        ; re-use as offset to last record
         addu8 #2;prod
:loop    CPY   X00
         BEQ   :dec
         LDA   (prod),Y
         STA   (zptr),Y
         INY
         BRA   :loop
:dec     LDA   stat
         DEC
         STA   (zptr)
:fin     RTS

* Insert or replace denizen record.
* X00=map offset, fac1=tile#, fac2=aux.
* Changes zptr, prod, stat, byt.
ins_den  ENT
         LDA   #$FC
         JSR   setup
         BEQ   :first
         TAX              ; denizen count before insertion
         INC              ; skip header
         ASL
         ASL
         STA   byt        ; offset to new last record
         TAY
:try     DEY
         DEY
         DEY
         LDA   X00+1
         CMP   (zptr),Y
         BEQ   :refine
:test    BCS   :insert    ; insert after record X, at offset Y+3
         DEX
         BEQ   :insert0   ; insert at beginning
         DEY
         BRA   :try
:refine  DEY
         LDA   X00
         CMP   (zptr),Y
         BEQ   :replace
         INY              ; restore Y
         BRA   :test
:replace INY
         INY
         INY
         BRA   :write
:first   LDY   #$07
:inc     LDA   stat
         INC
         STA   (zptr)
:write   LDA   fac2
         STA   (zptr),Y
         DEY
         LDA   fac1
         STA   (zptr),Y
         DEY
         LDA   X00+1
         STA   (zptr),Y
         DEY
         LDA   X00
         STA   (zptr),Y
         RTS
:insert0 LDY   #$01
:insert  TYA
         CLC
         ADC   #6
         TAX
         LDY   byt
         INY
         INY
         INY              ; offset to last byte of new last record
         STX   byt        ; offset to last byte of inserted record
:loop    CPY   byt
         BEQ   :inc
         LDA   (prod),Y
         STA   (zptr),Y
         DEY
         BRA   :loop

* Put `stream - xmap` into `X00` and fall into `search`. Changes zptr, prod, stat, byt, X00.
* Returns offset to record in Y, and tile index in A, or if search fails A=$ff.
* Records must be sorted by offset, maximum record count is 63.
get_den  ENT
         SEC
         LDA   stream
         SBC   xmap
         STA   X00
         LDA   stream+1
         SBC   xmap+1
         STA   X00+1
* Search denizen records for offset `X00`. Changes zptr, prod, stat, byt.
* Returns offset to record in Y, and tile index in A, or if search fails A=$ff.
* Records must be sorted by offset, maximum record count is 63.
search   LDA   #2
         JSR   setup
         LSR
         STA   byt        ; current displ in units of records
:go      PHA              ; current record using 0-indexing
         INC
         ASL
         ASL
         TAY              ; offset to start of record
         INY
         LDA   X00+1
         CMP   (zptr),Y
         BNE   :cont
         DEY
         LDA   X00
         CMP   (zptr),Y
         BNE   :cont

         PLA
         LDA   (prod),Y
         RTS

:cont    LDA   byt
         BMI   :dec
         BEQ   :inc
         BCS   :pos

         LDA   byt
         LSR
         BEQ   :beg_dec
         STA   byt
         SEC
         PLA
         SBC   byt
         BRA   :go

:pos     LDA   byt
         LSR
         BEQ   :beg_inc
         STA   byt
         CLC
         PLA
         ADC   byt
         BRA   :go

:beg_dec LDA   #$FF
         STA   byt
:dec     PLA
         DEC
         BMI   :fail
         BRA   :go

:beg_inc STZ   byt
:inc     PLA
         INC
         CMP   stat
         BCC   :go

:fail    LDA   #$FF
         RTS

         FIN