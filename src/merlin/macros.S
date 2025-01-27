         DO    0

swBank   MAC
         LDA   CHKAUX
         BMI   main
         LDA   AUXMEM
         BRA   cont
main     LDA   MAINMEM
cont     <<<

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

dec16    MAC
         LDA   ]1
         BNE   cont
         DEC   ]1+1
cont     DEC   ]1
         <<<

ph16     MAC
         LDA   ]1
         PHA
         LDA   ]1+1
         PHA
         <<<

pl16     MAC
         PLA
         STA   ]1+1
         PLA
         STA   ]1
         <<<

add16    MAC
         CLC
         LDA   ]1
         ADC   ]2
         STA   ]2
         IF    #=]1
         LDA   ]1/$100
         ELSE
         LDA   ]1+1
         FIN
         ADC   ]2+1
         STA   ]2+1
         <<<

addu8    MAC
         CLC
         LDA   ]1
         ADC   ]2
         STA   ]2
         BCC   fin
         INC   ]2+1
fin      <<<

addi8    MAC
         CLC
         LDA   ]1
         BPL   pos
         DEC   ]2+1
pos      ADC   ]2
         STA   ]2
         BCC   fin
         INC   ]2+1
fin      <<<

subu8    MAC
         SEC
         LDA   ]2
         SBC   ]1
         STA   ]2
         BCS   fin
         DEC   ]2+1
fin      <<<

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

phXY     MAC
         LDA   X0
         PHA
         LDA   X0+1
         PHA
         LDA   Y0
         PHA
         <<<

plXY     MAC
         PLA
         STA   Y0
         PLA
         STA   X0+1
         PLA
         STA   X0
         <<<

phX0     MAC
         LDA   X0+1
         PHA
         LDA   X0
         PHA
         <<<
         
plX0     MAC
         PLA
         STA   X0
         PLA
         STA   X0+1
         <<<

phHorCrs MAC
         LDA   COLUMN
         PHA
         LDA   BITPOS
         PHA
         LDA   clrMask1
         PHA
         LDA   clrMask2
         PHA
         LDA   CHKAUX
         PHA
         <<<

plHorCrs MAC
         PLA
         BMI   aux
         STZ   MAINMEM
         BRA   cont
aux      STZ   AUXMEM
cont     PLA
         STA   clrMask2
         PLA
         STA   clrMask1
         PLA
         STA   BITPOS
         PLA
         STA   COLUMN
         <<<

lte8     MAC
         DO    _bound
         LDA   ]2
         CMP   ]1
         BCS   cont
         LDX   #ILLQTY
         JMP   DOERR
         FIN
cont     <<<

lte16    MAC
         DO    _bound
         LDA   ]2+1
         CMP   ]1+1
         BMI   err
         BNE   cont
         LDA   ]2
         CMP   ]1
         BCS   cont
err      LDX   #ILLQTY
         JMP   DOERR
         FIN
cont     <<<

* paint screen, protecting memory if safe=1
paint    MAC
         DO    _safe
         PHA
         PHP
         LDA   ROWPTR+1
         CMP   #$20
         BCC   bad
         CMP   #$40
         BCS   bad
         CPY   #$28
         BCC   ok
bad      PLP
         PLA
         BRA   cont
ok       PLP
         PLA
         FIN
         STA   (ROWPTR),Y
cont     <<<

wrap80   MAC              ; + only
         DO    _wrap
         LDA   COLUMN
tst      CMP   #$50
         BCC   cont
         SBC   #$50
         BRA   tst
cont     STA   COLUMN         
         FIN
         <<<

wrapL    MAC
         DO    _wrap
         LDA   COLUMN
         BPL   cont
         LDA   #$27
         STA   COLUMN
         FIN
cont     <<<

wrapR    MAC
         DO    _wrap
         LDA   COLUMN
         CMP   #$28
         BCC   cont
         STZ   COLUMN
         FIN
cont     <<<

         FIN