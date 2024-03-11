1 lomem: 8*4096: if peek(-1088)=234 then text: home: print chr$(7);"65C02 REQUIRED": end
2  print chr$(4);"bload dhrlib": print  chr$ (4);"pr#3"
3  poke 1013,76: poke 1014,0: poke 1015,64: def fn mod8 (x) = 8*((x/8) - int(x/8))
4  gosub 800: goto 850

10 rem edit prompt
11 poke 49236,0: home: vtab 21: &tellp(addr,bit,cnt)
12 print "spc=stroke, 1=line, 2=trapezoid, m=mode ";spc(26);"brush ";br
13 print "(apple)b=brush, c=color, d=dither, cz=undo ";spc(23);"mode ";pm
15 print "(apple)arrows=movement, cx=cut, esc=menu ";spc(25);"len ";addr-a0;".";8-bit;
16 htab 67: vtab 24: print "cmd ";cnt;
17 poke 49237,0: htab 1: vtab 24: print "col "c1","c2","c3","c4" pos "x","y"  ";: return

20 rem get upper
21 a = peek(49152): if a<128 then 21
22 a = a - 128: a$ = chr$(a): if a>96 then a$ = chr$(a-32)
23 poke 49168,0: return

40  TEXT : HOME : ? "SDP II Painter v-dev": VTAB 13: &tellp(addr,bit,cnt): ? "length=";addr-a0;".";8-bit:L = 3:P = 5:W$ = "Select- ":B$ =  CHR$ (13)
41 PN$(0) = "New Pic":PN$(1) = "Load Pic":PN$(2) = "Save Pic":PN$(3) = "Append Pic": PN$(4) = "Edit": PN$(5) = "Exit": GOSUB 50
42  ON M + 1 GOTO 45,670,600,650,860,870
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
68  if a$ = "M" then gosub 130: goto 60
69  if a = 26 then gosub 500: goto 60
70  if a = 24 then gosub 1100: goto 60
72  if a = 27 then &rec: &end: &stop: goto 40
73  goto 60

90 rem move cursor
91  ds = 1: if peek(49249)>127 then ds = 10
92  if a = 8 then x = x - ds
93  if a = 11 then y = y - ds
94  if a = 21 then x = x + ds
95  if a = 10 then y = y + ds
100  if x<0 then x = 0
101  if x>559 then x = 559
102  if y<0 then y = 0
103  if y>191 then y = 191
104  gosub 17: return

110  rem stroke
111  if ps = 0 then &mode=128: &stroke#br at x,y: &mode=pm: return
112  if br = 0 then &rec: &hplot x,y: lastCmd = 4: goto 114
113  &rec: &stroke#br at x,y: lastCmd = 8
114  &stop: cnt = cnt + 1: return: rem done no prompt

120 rem brush
121 if peek(49249)>127 then br = br - 1: if br < 0 then br = 7
122 if peek(49249)<128 then br = br + 1: if br > 7 then br = 0
123  gosub 10: return

130 rem mode
131 if lastCmd = 2 then gosub 550
132 pm = 128*(pm<128): &rec: &mode=pm: lastCmd = 2
133 &stop: cnt = cnt + 1: gosub 10: return: rem done restore prompt

200 rem color
201 if lastCmd = 1 then gosub 550
202 p$ = "color: ": gosub 900: c1 = b: &rec: &hcolor=c1: lastCmd = 1: c2 = c1: c3 = c1: c4 = c1: goto 133

210 rem dither
211 if lastCmd = 1 then gosub 550
212 p$ = "Dither color r1c1: ": gosub 900: c1 = b: p$ = "Dither color r1c2: ": gosub 900: c2 = b
213 p$ = "Dither color r2c1: ": gosub 900: c3 = b: p$ = "Dither color r2c2: ": gosub 900: c4 = b
214 &rec: &hcolor=c1,c2,c3,c4: lastCmd = 1: goto 133

300 rem line mode
310 home: htab 1: vtab 21: print "Line Mode"
311 print "(apple)arrows=movement, space=draw line, esc=exit"
319 &rec: &move to x,y: lastCmd = 3: goto 331
320 gosub 110: gosub 20: gosub 110: gosub 90
321 if a = 27 then gosub 10: return
322 if a$ <> " " then 320
330 &move to x0,y0: &rec: &hplot to x,y: lastCmd = 5 
331 x0 = x: y0 = y: &stop: cnt = cnt + 1: goto 320

400 rem trapezoid mode
401 curs(0,0) = x-3: curs(0,1) = x+3: curs(0,2) = y: n = 0: i = 0: i0 = 0
402 curs(1,0) = x-3: curs(1,1) = x+3: curs(1,2) = y+2:
410 home: vtab 21: print "Trapezoid Mode"
411 print "(apple)arrows=move, tab=vertex, ret=fill, esc=done"
420 &mode=128:gosub 495: gosub 20: gosub 495: &mode=pm
421 ds = 1: if peek(49249)>127 then ds = 10
430 if a$ = chr$(13) then gosub 490: goto 420
432 if a$ = chr$(9) then n = n + 1: if n > 3 then n = 0
433 i0 = int(n/2): i = 2*n/2 - 2*i0
441 if a = 10 then curs(i0,2) = curs(i0,2) + ds
442 if a = 11 then curs(i0,2) = curs(i0,2) - ds
443 if a = 8 then curs(i0,i) = curs(i0,i) - ds
444 if a = 21 then curs(i0,i) = curs(i0,i) + ds
480 if a = 27 then gosub 10: return
489 goto 420

490 &rec: &trap at curs(0,0),curs(0,1),curs(0,2) to curs(1,0),curs(1,1),curs(1,2): &stop: cnt = cnt + 1: lastCmd = 7
492 for i = 0 to 2: curs(0,i) = curs(1,i): next: n = 2: i0 = 1: i = 0: return

495 if curs(0,2)>curs(1,2) then curs(0,2) = curs(1,2)
496 if curs(0,0)>curs(0,1) then curs(0,0) = curs(0,1)
497 if curs(1,0)>curs(1,1) then curs(1,0) = curs(1,1)
498 &stroke #1 at curs(i0,i)-2,curs(i0,2)-1 
499 &hplot curs(0,0),curs(0,2) to curs(0,1),curs(0,2) to curs(1,1),curs(1,2) to curs(1,0),curs(1,2) to curs(0,0),curs(0,2): return

500 rem undo
510 if cnt = 0 then return
520 cnt = cnt - 1: &seekp(a0,cnt): &rec: &end: &stop: &dhr: &seekg(a0,0): &draw at 0,0: gosub 880: gosub 10: return

550 rem pop vestigial cmd
551 cnt = cnt - 1: &seekp(a0,cnt): return

600 rem save
610 home: input "save path: ";a$
611 &tellp(addr,bit,cnt)
620 print: print chr$(4);"bsave ";a$;",A";a0;",L";addr-a0+2
630 goto 40

650 rem append
660 &tellp(addr,bit,cnt): home: input "load path: ";a$: print chr$(4);"bload ";a$;",A";addr+1
661 &seekg(addr+1,0): &rec: &scan: &draw at 0,0: &end: &stop: goto 40

670 rem load
680 &seekp(a0,0): goto 650

800 rem array setup
810 dim cl$(15): dim curs(1,2): dim pn$(9): dim cmd$(7)
820 restore: for i = 0 to 15: read cl$(i): next: for i = 0 to 7: read cmd$(i): next
840 return

850 rem new pic
851 x = 280: y = 80: ps = 0: pm = 0: br = 0: a0 = 6*4096: poke a0,0: c1 = 15: cnt = 0: lastCmd = 0: goto 40

860 rem edit
861 &dhr: &seekg(a0,0): &draw at 0,0: gosub 880: gosub 10: goto 60

870 rem quit
871 vtab 21: end

880 rem sync parameters
881 pm = 128*int(peek(249)/128): c2 = int(peek(28)/16): c1 = peek(28)-c2*16: c4 = int(peek(228)/16): c3 = peek(228)-c4*16
882 &tellg(addr,bit,cnt): &seekp(a0,cnt): return

900 rem color picker
910 b = 0
911 if b>15 then b = 0
912 if b<0 then b = 15
920 home: vtab 21: print p$;cl$(b): print "use arrows, return": get a$
930 if a$ = chr$(13) then return
940 if a$ = chr$(8) then b = b - 1: goto 911
950 if a$ = chr$(21) then b = b + 1: goto 911
960 goto 911

1100 rem select part
1110 home: vtab 21: print "arrows, spc starts and ends, esc aborts": m = -1: n = 0
1111 &rec: &end: &stop: &seekg(a0,0)
1120 gosub 1190: gosub 20: gosub 1190
1121 if a = 8 and n>0 then n = n - 1: &seekg(a0,n): goto 1120
1122 if a = 21 then 1140
1123 if a$ = " " and m=-1 then m = n: goto 1140
1124 if a$ = " " and m>=0 and n>m then 1150
1132 if a = 27 then 1180
1133 goto 1120

1140 if fn mod8(peek(249)) <> 0 then n = n + 1: &seekg(a0,n): rem next
1141 goto 1120

1150 rem cut range m..n
1151 &seekg(a0,n): &seekp(a0,m): &rec: &scan: &draw at 0,0: &end: &stop
1180 &dhr: &seekg(a0,0): &draw at 0,0: gosub 880: gosub 10: return: rem cleanup and return

1190 &mode=128: &draw 1 at 0,0: &seekg(a0,n): rem highlight part
1191 poke 49237,0: htab 1: vtab 22: print m" "n" "cmd$(fn mod8(peek(249)))"   ": return

9990 data black,blue,green,cyan,brown,grey-brown,light green,aquamarine,magenta,purple,grey-green,blue-grey,orange,pink,yellow,white
9991 data end,clr,mod,mov,plt,lin,trp,str
