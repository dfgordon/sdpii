1 lomem: 8*4096: if peek(-1088)=234 then text: home: print chr$(7);"65C02 PROCESSOR REQUIRED": end
2  print chr$(4);"bload dhrlib": print  chr$ (4);"pr#3"
3  poke 1013,76: poke 1014,0: poke 1015,64
4 gosub 800: goto 850

10 rem edit prompt
11 poke 49236,0: home: vtab 21
12 print "spc=stroke, 1=line, 2=trapezoid, x=xor ";spc(27);"brush ";br
13 print "(apple)b=brush, c=color, d=dither, z=undo ";spc(24);"mode ";pm
15 print "(apple)arrows=movement, esc=menu";
16 poke 49237,0: htab 67: vtab 24: print "pos ";x;",";y;"  ";: return

20 rem get upper
21 a = peek(49152): if a<128 then 21
22 a$ = chr$(a-128): if asc(a$)>96 then a$ = chr$(asc(a$)-32)
23 poke 49168,0: return

30 rem poke 16
31 if w<0 then w = w + 65536
32 poke addr,w-256*int(w/256): poke addr+1,int(w/256): addr = addr + 2: return
33 rem poke 8
34 poke addr,b: addr = addr + 1: return

40  TEXT : HOME : PRINT "SDP II Painter v-dev": VTAB 13: PRINT "bytes=";addr-a0+1:L = 3:P = 4:W$ = "Select- ":B$ =  CHR$ (13)
41 PN$(0) = "New Pic":PN$(1) = "Load Pic":PN$(2) = "Save Pic":PN$(3) = "Edit": PN$(4) = "Exit": GOSUB 50
42  ON M + 1 GOTO 45,650,600,860,870
45  home: print "Erase? ": gosub 20: if a$="Y" then 850
46  print: print "canceled. ";: gosub 20: goto 40

50  rem menu subroutine
51 N = 0:M = 0: HTAB 1: VTAB L: PRINT "1) ";: INVERSE : PRINT PN$(0): NORMAL : IF P > 0 THEN  FOR I = 1 TO P: PRINT I + 1;") ";PN$(I): NEXT 
52  HTAB 1: VTAB L + P + 2: PRINT W$;: GET A$: IF A$ =  CHR$ (13) OR A$ = B$ THEN  RETURN 
53  IF  VAL (A$) >  = 1 AND  VAL (A$) <  = P + 1 THEN M =  VAL (A$) - 1: RETURN 
54  IF A$ =  CHR$ (8) OR A$ =  CHR$ (11) THEN N = M:M = M - 1: IF M < 0 THEN M = P
55  IF A$ =  CHR$ (10) OR A$ =  CHR$ (21) THEN N = M:M = M + 1: IF M > P THEN M = 0
56  HTAB 4: VTAB N + L: PRINT PN$(N): INVERSE : HTAB 4: VTAB M + L: PRINT PN$(M): NORMAL : GOTO 52

60 rem edit loop
61  gosub 110: gosub 20: gosub 110: gosub 90
62  if a$ = "B" then gosub 120: goto 60
63  if a$ = "C" then gosub 200: goto 60
64  if a$ = "1" then gosub 300: goto 60
65  if a$ = "2" then gosub 400: goto 60
66  if a$ = " " then ps = 1: gosub 110: ps = 0: goto 60
67  if a$ = "D" then gosub 210: goto 60
68  if a$ = "X" then gosub 130: goto 60
69  if a$ = "Z" then gosub 500: goto 60
72  if a$ = chr$(27) then 40
73  goto 60

90 rem move cursor
91  ds = 1: if peek(49249)>127 then ds = 10
92  if a$ = chr$(8) then x = x - ds
93  if a$ = chr$(11) then y = y - ds
94  if a$ = chr$(21) then x = x + ds
95  if a$ = chr$(10) then y = y + ds
100  if x<0 then x = 0
101  if x>559 then x = 559
102  if y<0 then y = 0
103  if y>191 then y = 191
104  gosub 16: return

110  rem stroke
111  if ps = 0 then &mode=128: &stroke#br at x,y: &mode=pm: return
112  &stroke#br at x,y: if br = 0 then l$ = "121": c(0) = 3: c(1) = x: c(2) = y: goto 114
113  l$ = "1211": c(0) = 7: c(1) = x: c(2) = y: c(3) = br
114  gosub 700: return

120 rem brush
121 if peek(49249)>127 then br = br - 1: if br < 0 then br = 11
122 if peek(49249)<128 then br = br + 1: if br > 11 then br = 0
123  gosub 10: return

130 rem mode
131 pm = 128*(pm<128): &mode=pm: lastCmd = 1: gosub 550
132 l$ = "11": c(0) = 1: c(1) = pm: gosub 700: gosub 10: return

200 rem color
201 p$ = "color: ": gosub 900: c1 = b: &hcolor=c1: lastCmd = 0: gosub 550
202 c2 = c1: c3 = c1: c4 = c1: goto 214

210 rem dither
211 p$ = "Dither color r1c1: ": gosub 900: c1 = b: p$ = "Dither color r1c2: ": gosub 900: c2 = b
212 p$ = "Dither color r2c1: ": gosub 900: c3 = b: p$ = "Dither color r2c2: ": gosub 900: c4 = b
213 &hcolor=c1,c2,c3,c4: lastCmd = 0: gosub 550
214 l$ = "111": c(0) = 0: c(1) = c1+16*c2: c(2) = c3+16*c4: gosub 700: gosub 10: return

300 rem line mode
310 x0 = x: y0 = y: home: htab 1: vtab 21: print "Line Mode"
311 print "(apple)arrows=movement, space=draw line, esc=exit"
320 gosub 110: gosub 20: gosub 110: gosub 90
330 if a$ = " " then &hplot x0,y0 to x,y: l$ = "12121": c(0) = 5: c(1) = x: c(2) = y: c(3) = x0: c(4) = y0: gosub 700: x0 = x: y0 = y: goto 320
331 if a$ = chr$(27) then gosub 10: return
340 goto 320

400 rem trapezoid mode
401 curs(0,0) = x-3: curs(0,1) = x+3: curs(0,2) = y: n = 0
402 curs(1,0) = x-3: curs(1,1) = x+3: curs(1,2) = y+2:
410 home: vtab 21: print "Trapezoid Mode"
411 print "(apples)arrows=adjust, tab=upper/lower, spc=fill, esc=done"
412 print "(apple)a,d,j,l=alternate adjust"
420 &mode=128:gosub 495: gosub 20: gosub 495: &mode=pm
421 ds = 1: if peek(49249)>127 then ds = 10
430 if a$ = " " then gosub 490: goto 420
440 if a$ = chr$(9) then n = n + 1: if n > 1 then n = 0
441 if a$ = chr$(10) then curs(n,2) = curs(n,2) + ds
442 if a$ = chr$(11) then curs(n,2) = curs(n,2) - ds
443 if a$ = chr$(8) then curs(n,0) = curs(n,0) - ds: if peek(49250)>127 then curs(n,1) = curs(n,1) - ds
444 if a$ = chr$(21) then curs(n,0) = curs(n,0) + ds: if peek(49250)>127 then curs(n,1) = curs(n,1) + ds
445 if a$ = "A" then curs(n,0) = curs(n,0) - ds
446 if a$ = "D" then curs(n,0) = curs(n,0) + ds
447 if a$ = "J" then curs(n,1) = curs(n,1) - ds
448 if a$ = "L" then curs(n,1) = curs(n,1) + ds
480 if a$ = chr$(27) then gosub 10: return
489 goto 420
490 if curs(0,2)=curs(1,2) then &hplot curs(0,0),curs(0,2) to curs(0,1),curs(0,2): l$ = "1212": c(0) = 4: c(1) = curs(0,0): c(2) = curs(0,2): c(3) = curs(0,1): goto 492 
491 &trap at curs(0,0),curs(0,1),curs(0,2) to curs(1,0),curs(1,1),curs(1,2): l$ = "1212212": c(0) = 6: c(1) = curs(0,0): c(2) = curs(0,2): c(3) = curs(0,1)
492 c(4) = curs(1,0): c(5) = curs(1,2): c(6) = curs(1,1): gosub 700: for i = 0 to 2: curs(0,i) = curs(1,i): next: return
495 if curs(1,2)<curs(0,2) then curs(1,2) = curs(0,2)
496 &hplot curs(0,0),curs(0,2) to curs(0,1),curs(0,2) to curs(1,1),curs(1,2) to curs(1,0),curs(1,2) to curs(0,0),curs(0,2): return

500 rem undo
501 if addr = a0 + cmdLn(0) then return
510 if undoDepth=0 then gosub 1000: if undoDepth=0 then gosub 10: return
520 &dhr: addr = addr - cmdLn(stack%(undoDepth-1)): poke addr,255: undoDepth = undoDepth - 1: &draw at 0,0: gosub 10: return

550 rem pop vestigial cmd
551 if undoDepth=0 then return
552 if stack%(undoDepth-1) = lastCmd then addr = addr - cmdLn(lastCmd): undoDepth = undoDepth - 1
553 return

600 rem save
610 home: poke addr,255: input "save path: ";a$
620 print: print chr$(4);"bsave ";a$;",A";a0;",L";addr-a0+1
630 goto 40

650 rem load
660 home: input "load path: ";a$
670 print: print chr$(4);"bload ";a$;",A";addr
680 addr = addr + peek (48840) + 256 * peek (48841) - 1: poke addr,255: undoDepth = 0: goto 40

700 rem record
710 stack%(undoDepth) = c(0): i = 0: undoDepth = undoDepth+1: if undoDepth=33 then gosub 760
720 if i = len(l$) then return
730 if mid$(l$,i+1,1)="1" then b = c(i): gosub 33
740 if mid$(l$,i+1,1)="2" then w = c(i): gosub 30
750 i = i + 1: goto 720
760 rem roll stack
770 for i = 0 to 31: stack%(i) = stack%(i+1): next: undoDepth = 32: i = 0: return

800 rem array setup
810 dim cl$(15): dim cmdLn(7): dim c(9): dim stack%(32): dim curs(1,2): dim pn$(9)
820 restore: for i = 0 to 15: read cl$(i): next
830 for i = 0 to 7: read cmdLn(i): next
840 return

850 rem new pic
851 x = 280: y = 80: ps = 0: pm = 0: br = 0: a0 = 96*256: addr = a0: c1 = 15: undoDepth = 0: gosub 202: poke 232,0: poke 233,a0/256: poke addr,255: goto 40

860 rem edit
861 &dhr: &draw at 0,0: gosub 10: goto 60

870 rem quit
871 poke addr,255: vtab 21: end

900 rem color picker
910 b = 0
911 if b>15 then b = 0
912 if b<0 then b = 15
920 home: vtab 21: print p$;cl$(b): print "use arrows, return": get a$
930 if a$ = chr$(13) then return
940 if a$ = chr$(8) then b = b - 1: goto 911
950 if a$ = chr$(21) then b = b + 1: goto 911
960 goto 911

1000 rem rebuild undo stack
1010 home: vtab 21: print "rebuilding undo stack...": poke addr,255: addr = a0
1030 if peek(addr) > 127 then return
1040 if peek(addr) > 7 then print chr$(7);"ILLEGAL QUANTITY ERROR": end
1050 stack%(undoDepth) = peek(addr): addr = addr + cmdLn(peek(addr)): undoDepth = undoDepth + 1
1060 if undoDepth=33 then gosub 760
1070 goto 1030

9990 data black,blue,green,cyan,brown,grey-brown,light green,aquamarine,magenta,purple,grey-green,blue-grey,red,pink,yellow,white
9991 data 3,2,3,4,6,7,11,5: rem cmd code lengths