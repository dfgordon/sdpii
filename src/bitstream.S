         XC    OFF
         XC
         REL
         DSK   BITSTREAM.L

* subroutines for handling bitstream.
* usually called indirectly by encoder/decoder.

         PUT   equiv
         USE   macros

cmdBits  EXT

* Initialize a bitstream at `stream`.
* old bitstream is lost, unless `suspBits` called first.
iniBits  ENT
         LDA   (stream)
         STA   lkAhed
         STZ   lkBack
         LDY   #$08
         STY   bitPtr
         RTS

* resume a bitstream, restoring from descriptor at zptr
resmBits ENT
         LDY   #$00
:loop    LDA   (zptr),Y
         STA   stream,Y
         INY
         CPY   #$05
         BNE   :loop
         RTS

* suspend a bitstream, saving to descriptor at zptr
suspBits ENT
         LDY   #$00
:loop    LDA   stream,Y
         STA   (zptr),Y
         INY
         CPY   #$05
         BNE   :loop
         RTS

* advance by X00 commands, for stream with descriptor at zptr.
* if `stream=0` relative move, otherwise init at `stream`.
* for relative move set prod = current command count.
* updated command count returned in prod, which
* will be clamped to actual commands processed.
seek     ENT
         LDA   stream+1
         BEQ   :rel
         JSR   iniBits
         STZ   prod
         STZ   prod+1
         BRA   :cmdLoop
:rel     JSR   resmBits
:cmdLoop LDA   X00
         BNE   :nxt
         LDA   X00+1
         BNE   :nxt
         JMP   suspBits   ; exit, done
:nxt     LDX   #4
         JSR   rdBits
         CMP   #$00
         BNE   :ok1
         JMP   suspBits   ; exit, no more cmds
:ok1     CMP   #$09
         BCC   :ok2
         JMP   illQ
:ok2     TAX
         LDA   cmdBits,X
         TAX
         JSR   advBits
         dec16 X00
         inc16 prod
         BRA   :cmdLoop

* advance seek pointer by X bits (X<248),
* prepare for either read or write.
advBits  ENT
* let A = bit count relative to byte boundary
         CLC
         TXA
         ADC   #$08
         SEC
         SBC   bitPtr     ; n.b. bitPtr is a countdown
         PHA
* advance pointer by A/8
         LSR
         LSR
         LSR
         CLC
         ADC   stream
         STA   stream
         BCC   :rmndr
         INC   stream+1
:rmndr   LDA   (stream)
         STA   lkAhed
         PLA
         AND   #$07
         STA   bitPtr     ; tbd
:loop    BEQ   :fin
         LSR   lkAhed
         ROR   lkBack
         DEC
         BRA   :loop
:fin     SEC
         LDA   #$08
         SBC   bitPtr
         STA   bitPtr
         RTS

* Read bits from bitstream into A.
* X=number of bits to process, X>0.
* X>8 ok but only last 8 are saved.
* Cannot switch to writing.
rdBits   ENT
         LDY   bitPtr
         PHX
:loop    LSR   lkAhed
         ROR
         DEY
         BEQ   :nxtByt
:chk     DEX
         BEQ   :fin
         BRA   :loop
:nxtByt  PHA
         inc16 stream
         LDA   (stream)
         STA   lkAhed
         LDY   #$08
         PLA
         BRA   :chk
:fin     STY   bitPtr
         PLX
:loop2   CPX   #$08
         BCS   :ret
         INX
         LSR
         BRA   :loop2
:ret     RTS

* Save bits from A into bitstream.
* X=number of bits to process, X>0.
* X>8 ok, trailing bits will be 0.
* Last bits only saved when stream is closed.
* OK to switch to reading.
stBits   ENT
         LDY   bitPtr
:loop    LSR   lkAhed
         LSR
         ROR   lkBack
         DEY
         BEQ   :nxtByt
:chk     DEX
         BEQ   :fin
         BRA   :loop
:nxtByt  PHA
         LDA   lkBack
         STA   (stream)
         inc16 stream
         LDA   (stream)
         STA   lkAhed
         LDY   #$08
         PLA
         BRA   :chk
:fin     STY   bitPtr
         RTS

illQ     LDX   #ILLQTY
         JMP   DOERR

