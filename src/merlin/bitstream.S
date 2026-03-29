         XC    OFF
         XC
         REL
         DSK   BITSTREAM.L

* Subroutines for handling bitstream.
* Usually called indirectly by encoder/decoder.
* N.b. bitPtr is a countdown from 8 to 1, indicating
* bits remaining to read at the current byte.  It should
* never be left with the value 0.

* Stream Descriptors
* ------------------
* The stream descriptor is 5 bytes: [address low, address high, look ahead, look back, bit pointer].
* The working descriptor is stream[0..5], but there are aliases as follows:
* lkAhed = stream+2
* lkBack = stream+3
* bitPtr = stream+4

         PUT   equiv
         USE   macros

         DO       _pics/2

cmdBits  EXT

* Initialize the working bitstream.
* * inputs
*   - stream[0..2] - address of stream data
* * outputs
*   - stream[2..5] and aliases
* * dirty - A
iniBits  ENT
         LDA   (stream)
         STA   lkAhed
         STZ   lkBack
         LDA   #$08
         STA   bitPtr
         RTS

* Resume a checkpointed bitstream.
* * inputs
*   - zptr - pointer to the descriptor checkpoint
* * outputs
*   - stream[0..5]
* * dirty - A,Y
resmBits ENT
         LDY   #$00
:loop    LDA   (zptr),Y
         STA   stream,Y
         INY
         CPY   #$05
         BNE   :loop
* following permits seekg(A,0) to precede loading picture
         LDA   bitPtr
         CMP   #$08
         BNE   :fin
         LDA   (stream)
         STA   lkAhed
:fin     RTS

* rewind 3 bits then fall into chkpBits
* * inputs
*   - zptr - pointer to descriptor checkpoint
* * outputs
*   - (zptr)[0..5]
* * dirty - A,Y
rewind   CLC
         LDA   bitPtr
         ADC   #3
         CMP   #9
         BPL   :dec
         STA   bitPtr
         BRA   chkpBits
:dec     AND   #7
         STA   bitPtr
         dec16 stream
* checkpoint a bitstream, saving to descriptor at zptr
chkpBits ENT
         LDY   #$00
:loop    LDA   stream,Y
         STA   (zptr),Y
         INY
         CPY   #$05
         BNE   :loop
         RTS

* Set stream position by counting commands.
* Command codes are assumed 3 bits.
* * inputs
*   - stream[0..2] - if ZP resume zptr, otherwise init working stream
*   - zptr - checkpoint to resume (if stream+1 = 0)
*   - X00 - count of commands to pass over
*   - cmdBits - table of command argument lengths
* * outputs
*   - stream[0..5] if resuming, stream[2..5] otherwise
*   - prod - index of the command actually arrived at
* * dirty - A,X,Y,X00
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
         JMP   chkpBits   ; exit, done
:nxt     LDX   #3
         JSR   rdBits
         CMP   #$00
         BNE   :ok
         JMP   rewind     ; exit, no more cmds
:ok      TAX
         LDA   cmdBits,X
         TAX
         JSR   advBits
         dec16 X00
         inc16 prod
         BRA   :cmdLoop

* advance seek pointer by bits.
* * inputs
*   - X - bits to advance from 0..248
* * outputs
*   - stream is ready for reading or writing
* * dirty - A
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

* Read bits from working stream. Cannot switch to writing without new seek.
* * inputs
*   - X - bits to process from 0..128
* * outputs
*   - A - up to the last 8 bits that were read
* * dirty - X,Y
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

* Write to bit stream.  OK to switch immediately to reading.
* * inputs
*   - A - up to 8 bits to write, further bits are assumed 0
*   - X - bits to write from 0..128
* * outputs
*   - stream is updated except for remainder bits which are written upon closing the stream
* * dirty - A,X,Y
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

* Save the last few bits when done
* * dirty - A,Y
clsBits  ENT
         LDA   bitPtr
         AND   #$07
         TAY
         BEQ   :fin
         LDA   lkBack
         PHA
:loop    LSR
         DEY
         BNE   :loop
         STA   (stream)
         PLA
         STA   lkBack
:fin     RTS

         FIN