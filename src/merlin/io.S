         XC    OFF
         XC
         REL
         DSK   INPUT.L

         USE   macros
         PUT   equiv

get      MAC
         TXA
         CMP   #]1
         BNE   done
         LDA   #]2
         STA   DX
         LDA   #]3
         STA   DY
         JMP   parseget
done     <<<

saveInt  EXT
tile     EXT

* Update 80 column cursor.  This is in firmware also, but is there a stable entry point?
* This is a compact version that does not protect against CH>39.
* * inputs
*   - cursor control - CH, CH_OLD, CH_80
* * outputs
*   - cursor control - Y=CH=CH_OLD=CH_80
* * dirty - none
get_cur  LDY   CH
         CPY   CH_OLD
         BNE   sav_cur   ; if CH changed use it
use_80   LDY   CH_80      ; otherwise use 80 column cursor
sav_cur  STY   CH_80
         STY   CH
         STY   CH_OLD
         RTS

* handle output redirection to the DHGR screen.
* * inputs
*   - A - character to output
*   - cursor control - CH or CH_80, CV, WLEFT, WWIDTH, WBOT
*   - DRAWPTR - address of font, if ZP use stashed font
* * outputs
*   - cursor control - CH, CH_OLD, CH_80, CV
* * dirty - same as `tile` except all registers clean
gout     ENT
         CLD              ; required per Apple
         PHX
         PHY
         PHA
         TAX              ; save char
         LDA   CHKAUX
         PHA
         STZ   MAINMEM
         JSR   get_cur
         LDA   DRAWPTR+1
         PHA
         BNE   :go
         LDA   #$08
         STA   DRAWPTR+1
:go      TXA              ; restore char
         EOR   #$80
         CMP   #$0D
         BEQ   :nxtRow
         LDX   CH_80
         LDY   CV
         SEC
         SBC   #$20
         BPL   :render
         ADC   #$7B       ; 5 -> 96, 6 -> 97, ...
:render  JSR   tile
         LDX   CH_80
         INX
         TXA
         SEC
         SBC   WLEFT
         CMP   WWIDTH
         BCS   :nxtRow
         STX   CH_80
         BRA   :cleanup
:nxtRow  LDA   WLEFT
         STA   CH_80
         LDY   CV
         INY
         CPY   WBOT
         BCS   :cleanup
         STY   CV
* important to restore state as this is called by entities we do not control
:cleanup STZ   MAINMEM    ; normally should not be needed
         JSR   use_80     ; some things in DHRLIB assume CH is up to date
         PLA
         STA   DRAWPTR+1
         PLA
         BPL   :mainmem
         STZ   AUXMEM
:mainmem PLA
         PLY
         PLX
         RTS

         DO    _game

* echo input characters (or not)
* * inputs
*   - A - character to echo
*   - byt2 - if 0 do not echo, otherwise echo to COUT
*   - C - if carry set and byt2 > 0, advance cursor
* * dirties - A
echo     PHA
         LDA   byt2
         BEQ   :plrts
         PLA
         PHP
         JSR   COUT
         PLP
         BCS   :rts
         DEC   CH_80
         PHA
:plrts   PLA
:rts     RTS

* set A=0 if A should not be accepted, otherwise clear high bit of A.
* * inputs
*   - byt2 - filter or maximum length
*   - X - length of current string
filter   AND   #%01111111
         PHA
         LDA   byt2
         BNE   :length
         PLA
         RTS
:length  DEC
         BEQ   :prodos
         PLA
         CPX   byt2
         BPL   :ignore
         RTS
:prodos  PLA
         CPX   #$0D       ; max length check
         BPL   :ignore
         CPX   #$00
         BEQ   :first     ; skip those not allowed first
         CMP   #'.'
         BEQ   :ok
         CMP   #'0'
         BCS   :may_dec
         BRA   :ignore
:may_dec CMP   #'9'+1
         BCC   :ok
:first   CMP   #'a'
         BCS   :may_lc
         CMP   #'A'
         BCC   :ignore
         CMP   #'Z'+1
         BCS   :ignore
         RTS
:may_lc  CMP   #'z'+1
         BCS   :ignore
         SEC
         SBC   #$20       ; make upper case
:ok      RTS
:ignore  LDA   #0
         RTS

* &input(svar,filter) get input with DHGR echo.
* * arguments
*   - svar - string variable to receive the input
*   - filter - expression resolving to 8 bit value
*     - 0 - any input source, echo is suppressed
*     - 1 - keyboard only, ProDOS filename with maximum length reduced by 2
*     - n - keyboard only, maximum length n
*
* This bypasses the firmware's usual parsing, i.e., commas and colons are accepted.
* However, when filter = 0 we are using RDKEY, which may invoke some firmware
* cursor handling code, which in turn can cause writes to the textual display pages.
ampInput ENT
         JSR   CHKOPN
         JSR   PTRGET
         JSR   COMBYT
         STX   byt2
         JSR   CHKCLS

         LDX   #0
:loop    LDA   #"_"
         CLC
         JSR   echo
:key     LDA   byt2
         BNE   :kloop
         JSR   RDKEY
         BRA   :chk
:kloop   LDA   $C000
         BPL   :kloop
         STA   $C010
:chk     CMP   #$8D
         BEQ   :fin
         CMP   #$88
         BEQ   :back
         JSR   filter
         CMP   #$00
         BEQ   :loop
         STA   $200,X
         ORA   #%10000000
         SEC
         JSR   echo
         INX
         BRA   :loop
:back    CPX   #0
         BEQ   :key
         LDA   #" "
         CLC
         JSR   echo
         DEC   CH_80
         DEX
         BRA   :loop
:fin     TXA
         PHA
         JSR   STRINI
         LDY   #0
         LDA   DSCTMP,Y
         STA   (VARPNT),Y
         INY
         LDA   DSCTMP,Y
         STA   (VARPNT),Y
         INY
         LDA   DSCTMP,Y
         STA   (VARPNT),Y
         PLA
         LDX   #0
         LDY   #2
         JSR   MOVSTR
         RTS

* &get a[,dx,dy]
* get ascii keypress into a, and test all direction keys to fill dx,dy
ampGet   ENT
         LDA   $C000
         BPL   ampGet
         STZ   $C010
         AND   #$7F
* uppercase
         CMP   #97
         BCC   :pshk
         SBC   #32
:pshk    TAX
         PHA
         STZ   DX
         STZ   DY
* arrow keys
         get   8;255;0
         get   21;1;0
         get   10;0;1
         get   11;0;255
* numeric keypad
         get   49;255;1
         get   50;0;1
         get   51;1;1
         get   52;255;0
         get   54;1;0
         get   55;255;255
         get   56;0;255
         get   57;1;255
parseget JSR   PTRGET
         PLY
         LDA   #0
         JSR   saveInt
         LDA   (TXTPTR)
         CMP   #44
         BNE   :rts
         JSR   CHKCOM
         JSR   PTRGET
         LDY   DX
         JSR   :svint
         JSR   CHKCOM
         JSR   PTRGET
         LDY   DY
         JSR   :svint
:rts     RTS
:svint   BMI   :neg
         LDA   #0
         BRA   :ret
:neg     LDA   #$ff
:ret     JMP   saveInt

         FIN