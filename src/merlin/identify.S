* Program to check hardware dependencies.
* Assumes ProDOS MACHID is available, but also
* uses ROM identifiers, and resets bank switches.
* Strategy:
* Apple II, II Plus, III - reject
* Apple //e - accept on conditions
* Anything else - accept

         XC    OFF

result   =     $00        ; return value, 0=ok, 1=bad
MACHID   =     $BF98
ROMID1   =     $FBB3
ROMID2   =     $FBC0
CHK_GS   =     $fe1f      ; clears carry if IIgs
RDROM    =     $C081

         ORG   $300
         PHP
         SEI
         LDA   RDROM      ; be sure we are reading ROM
         LDA   RDROM      ; do it twice
         LDA   ROMID1
         CMP   #$38       ; Apple II
         BEQ   reject
         CMP   #$ea       ; Apple II Plus or Apple III
         BEQ   reject
         CMP   #$06       ; maybe Apple //e
         BNE   accept     ; accept as unknown late model
         LDA   ROMID2
         CMP   #$ea       ; unenhanced //e
         BEQ   reject
         CMP   #$e0       ; enhanced //e or IIgs
         BEQ   maybe_gs
         JMP   accept     ; Apple //c variant or unknown

maybe_gs SEC
         JSR   CHK_GS
         BCC   accept     ; Apple IIgs

* We have an enhanced //e, check aux card
         LDA   #%00000010
         AND   MACHID
         BEQ   reject     ; no card
         LDA   #%00110000
         AND   MACHID
         CMP   #%00110000
         BNE   reject     ; less than 128K
accept   LDA   #$00
         JMP   fin
reject   LDA   #$01
fin      STA   result
         PLP
         RTS

