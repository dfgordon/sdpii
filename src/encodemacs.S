         DO    0

enEnd    MAC
         DO    _builder
         LDX   #0
         JSR   doEncode
         FIN
         <<<

enColor  MAC
         DO    _builder
         LDX   #1
         JSR   doEncode
         FIN
         <<<

enMode   MAC
         DO    _builder
         LDX   #2
         JSR   doEncode
         FIN
         <<<

enCurs   MAC
         DO    _builder
         LDX   #3
         JSR   doEncode
         FIN
         <<<

enPlot   MAC
         DO    _builder
         LDX   #4
         JSR   doEncode
         FIN
         <<<

enLineTo MAC
         DO    _builder
         PHA
         PHX
         PHY
         STA   x1
         STX   x1+1
         STY   y1
         LDX   #5
         JSR   doEncode
         PLY
         PLX
         PLA
         FIN
         <<<

enHline  MAC
         DO    _builder
         PHA
         PHX
         STA   x1
         STX   x1+1
         LDX   #6
         JSR   doEncode
         PLX
         PLA
         FIN
         <<<

enTrap   MAC
         DO    _builder
         LDX   #7
         JSR   doEncode
         FIN
         <<<

enStroke MAC
         DO    _builder
         PHX
         STX   byt
         LDX   #8
         JSR   doEncode
         PLX
         FIN
         <<<

         FIN