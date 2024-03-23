1 lomem: 8*4096: if peek(-1088)=234 then text: home: print chr$(7);"65C02 REQUIRED": end
2  print chr$(4);"bload dhrlib": print chr$(4);"bload font1": print  chr$ (4);"pr#3"
3  poke 1013,76: poke 1014,0: poke 1015,64: poke 232,0: poke 233,96: def fn mod (x) = x - de*int(x/de)
4  gosub 800: goto 850

5 rem move cursor
6  ds = 1: if peek(49249)>127 then ds = 10
7  x = x - ds*(a=8) + ds*(a=21): y = y - ds*(a=11) + ds*(a=10): de = 560: x = fn mod(x): de = 192: y = fn mod(y): if pr=5 then gosub 17
8  return

10 rem edit prompt
11 &tellp(addr,bit,cnt): &clear 1,24: if pr > 5 then pr = 1
12 on pr goto 13,14,15,16,17
13 w$ = "TAB=prompt, ESC=exit, SPC=stroke": goto 19
14 w$ = chr$(128)+chr$(132) + "=move,1=line,2=trap,3=tri,x=xor": goto 19
15 w$ = chr$(128)+"b=brush,c=color,d=dither,^x=cut,^z=pop": goto 19
16 w$ = "brush=" + str$(br) + ",xor=" + str$(pm) + ",len=" + str$(addr-a0) + "." + str$(8-bit) + ",cmd=" + str$(cnt): goto 19
17 &trap at 0,13,184 to 0,13,191: w$ = str$(x) + "," + str$(y) + "   ": &print w$ at 3,24: return 
19 &print w$ at 1,24: return

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
61  gosub 110: gosub 20: gosub 110: gosub 5
62  if a$ = "B" then gosub 120: goto 60
63  if a$ = "C" then gosub 200: goto 60
64  if a$ = "1" then gosub 300: goto 60
65  if a$ = "2" then gosub 400: goto 60
66  if a$ = "3" then gosub 450: goto 60
67  if a$ = " " then ps = 1: gosub 110: ps = 0: goto 60
68  if a$ = "D" then gosub 210: goto 60
69  if a$ = "X" then gosub 130: goto 60
70  if a = 26 then gosub 500: goto 60
71  if a = 24 then gosub 1100: goto 60
72  if a = 9 then pr = pr + 1: gosub 10: goto 60
73  if a = 27 then &rec: &end: &stop: goto 40
74  goto 60
 
80 rem generalized move cursor
81 if peek(49250)<128 then x = x(n): y = y(n): gosub 5: x(n) = x: y(n) = y: return
85 for i=0 to 3: x = x(i): y = y(i): pr = 0: gosub 5: x(i) = x: y(i) = y: next: pr = 5: gosub 17: return

110  rem stroke
111  if ps = 0 then &mode=128: &stroke#br at x,y: &mode=pm: return
112  if br = 0 then &rec: &hplot x,y: goto 114
113  &rec: &stroke#br at x,y
114  &stop: gosub 10: return

120 rem brush
121 if peek(49249)>127 then br = br - 1: if br < 0 then br = 7
122 if peek(49249)<128 then br = br + 1: if br > 7 then br = 0
123  gosub 10: return

130 rem xor
131 gosub 540: if lastCmd = 2 then gosub 550
132 pm = 128*(pm<128): &mode=pm+64: goto 114

200 rem color
201 gosub 540: if lastCmd = 1 then gosub 550
202 ci = 0: gosub 900: &rec: &hcolor=cl(0): goto 114

210 rem dither
211 gosub 540: if lastCmd = 1 then gosub 550
212 ci = 1: gosub 900: &rec: &hcolor=cl(1),cl(2),cl(3),cl(4): goto 114

300 rem line mode
301 &clear 1,24: pr=5: gosub 17: &print "Line: " + chr$(128) + chr$(132) + ", SPC" at 13,24
302 &rec: &move to x,y: goto 307
303 &mode=128: &hplot x0,y0 to x,y: gosub 20: &hplot x0,y0 to x,y: &mode=pm: gosub 5
304 if a = 27 then gosub 10: return
305 if a <> 32 then 303
306 &move to x0,y0: &rec: &hplot to x,y
307 x0 = x: y0 = y: &stop: goto 303

400 rem trapezoid mode
401 x(0) = x: y(0) = y: x(1) = x+10: y(1) = y: n = 0
402 x(2) = x: y(2) = y+5: x(3) = x+10: y(3) = y+5:
403 &clear 1,24: pr=5: gosub 17: &print "Trap: " + chr$(128) + chr$(129) + chr$(132) + ", TAB, SPC" at 13,24
404 &mode=128:gosub 430: gosub 20: gosub 430: &mode=pm: gosub 80: gosub 420
405 if a = 32 then gosub 410: goto 404
406 if a = 27 then gosub 10: x = x(n): y = y(n): return
407 if a = 9 then de = 4: n = fn mod(n+1)
409 goto 404

410 &rec: &trap at x(0),x(1),y(0) to x(2),x(3),y(3): &stop
411 x(0) = x(2): y(0) = y(2): x(1) = x(3): y(1) = y(3): y(2) = y(2) + 5: y(3) = y(3) + 5: n = 2: return

420 de = 2: i = n - 2 * fn mod(n) + 1: j = n - 4*int(n/2) + 2
421 if j>n and y(n)>y(j) then y(j) = y(n)
422 if j<n and y(n)<y(j) then y(j) = y(n)
423 if i>n and x(n)>x(i) then x(i) = x(n)
424 if i<n and x(n)<x(i) then x(i) = x(n)
425 y(i) = y(n): i = j - 2 * fn mod(j) + 1: y(i) = y(j): return

430 &stroke #1 at x(n)-2,y(n)-1 
431 &hplot x(0),y(0) to x(1),y(1) to x(3),y(3) to x(2),y(2) to x(0),y(0): return

450 rem triangle mode
451 x(0) = x: y(0) = y: x(1) = x+10: y(1) = y+5: x(2) = x: y(2) = y+10: n = 0
452 &clear 1,24: pr=5: gosub 17: &print "Tri: " + chr$(128) + chr$(129) + chr$(132) + ", TAB, SPC" at 13,24
453 &mode=128: gosub 480: gosub 20: gosub 480: &mode=pm: gosub 80
454 if a = 32 then gosub 460: a = 9
455 if a = 27 then gosub 10: x = x(n): y = y(n): return
456 if a = 9 then de = 3: n = fn mod(n+1)
457 goto 453

460 if y(0) > y(1) then i = 0: j = 1: gosub 490
461 if y(1) > y(2) then i = 1: j = 2: gosub 490
462 if y(0) > y(1) then i = 0: j = 1: gosub 490
463 x(3) = x(0) + int((x(2)-x(0))*(y(1)-y(0))/(y(2)-y(0))): x = x(3): if x<=x(1) then x = x(1): x(1) = x(3)
464 &rec: &trap at x(0),x(0),y(0) to x(1),x,y(1): &trap at x(1),x,y(1) to x(2),x(2),y(2): &stop
465 rem make next triangle the same, n.b. x(1) might not be the vertex
466 rem user can build off it by simply moving 1 vertex past opposite segment
468 if x(1) = x(3) then x(1) = x
469 return: rem after returning we cycle the vertex

480 &stroke #1 at x(n)-2,y(n)-1
481 &hplot x(0),y(0) to x(1),y(1) to x(2),y(2) to x(0),y(0): return

490 rem swap i,j
491 x = x(i): x(i) = x(j): x(j) = x: y = y(i): y(i) = y(j): y(j) = y: return

500 rem undo
510 if cnt = 0 then return
520 &seekp(a0,cnt-1): &rec: &end: &stop: &dhr: poke -16302,0: &seekg(a0,0): &draw at 0,0: gosub 880: gosub 10: return

540 rem get last cmd
541 if cnt<1 then lastCmd = 0: return
542 &seekg(a0,cnt-1): &scan: &draw 1 at 0,0: &stop: de = 8: lastCmd = fn mod(peek(249)): return

550 rem pop vestigial cmd
551 &seekp(a0,cnt-1): return

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
810 dim cl(4): dim x(3): dim y(3): dim pn$(9): dim cmd$(7)
820 restore: for i = 0 to 7: read cmd$(i): next: for i = 0 to 4: cl(i) = 15: next
840 return

850 rem new pic
851 x = 280: y = 80: ps = 0: pm = 0: br = 0: a0 = 81*256: poke a0,0: addr = a0: bit = 8: cnt = 0: goto 40

860 rem edit
861 &dhr: poke -16302,0: &seekg(a0,0): &draw at 0,0: gosub 880: gosub 10: pr = 1: goto 60

870 rem quit
871 vtab 21: end

880 rem sync parameters
881 pm = 128*int(peek(249)/128): cl(2) = int(peek(28)/16): cl(1) = peek(28)-cl(2)*16: cl(4) = int(peek(228)/16): cl(3) = peek(228)-cl(4)*16
882 &tellg(addr,bit,cnt): &seekp(a0,cnt): return

900 rem color picker
901 &clear 1,24: a$ = chr$(130) + chr$(131) + ", SPC": if ci > 0 then a$ = a$ + ", TAB"
902 &print a$ at 3+2*(ci>0),24
911 if cl(0)>15 then cl(0) = 0
912 if cl(0)<0 then cl(0) = 15
913 if ci = 0 then 930
914 if ci>4 then ci = 1
920 cl(ci) = cl(0): &hcolor=cl(1),cl(2),cl(3),cl(4): &trap at 28,43,184 to 28,43,191
930 &hcolor=cl(ci): &trap at 0,15,184 to 0,15,191: get a$: if a$ = " " then return
940 if a$ = chr$(8) then cl(0) = cl(0) - 1: goto 911
950 if a$ = chr$(21) then cl(0) = cl(0) + 1: goto 911
951 if ci>0 and a$ = chr$(9) then ci = ci + 1
960 goto 911

1100 rem select part
1110 &clear 1,24: &print chr$(132) + ", SPC=start/end" at 1,24: m = -1: n = 0
1111 &rec: &end: &stop: &seekg(a0,0)
1120 gosub 1190: gosub 20: gosub 1190
1121 if a = 8 and n>0 then n = n - 1: &seekg(a0,n): goto 1120
1122 if a = 21 then 1140
1123 if a$ = " " and m=-1 then m = n: goto 1140
1124 if a$ = " " and m>=0 and n>m then 1150
1132 if a = 27 then 1180
1133 goto 1120

1140 de = 8: if fn mod(peek(249)) <> 0 then n = n + 1: &seekg(a0,n): rem next
1141 goto 1120

1150 rem cut range m..n
1151 &seekg(a0,n): &seekp(a0,m): &rec: &scan: &draw at 0,0: &end: &stop
1180 &dhr: poke -16302,0: &seekg(a0,0): &draw at 0,0: gosub 880: gosub 10: return: rem cleanup and return

1190 &mode=128: &draw 1 at 0,0: &seekg(a0,n): rem highlight part
1191 poke 49237,0: htab 1: vtab 22: de = 8: print m" "n" "cmd$(fn mod(peek(249)))"   ": return

9990 data end,clr,mod,mov,plt,lin,trp,str
