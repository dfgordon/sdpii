1 himem: 8192: if peek(-1088)=234 then text: home: print chr$(7);"65C02 PROCESSOR REQUIRED": end
2  DEF  FN GT16(ADDR) =  PEEK (ADDR) + 256 *  PEEK (ADDR + 1)
4  print chr$(4);"bload dhrlib": print chr$(4);"bload font1,a$8000": print chr$(4);"pr#3"
5  poke 1013,76: poke 1014,0: poke 1015,64
6 lx = 1: ly = 1: dx = 8: dy = 6: yg = 2+16*ly: a0 = 96*256: poke a0,lx: poke a0+1,ly: gosub 800
7 poke 232,0: poke 233,a0/256: tilNum = 0: tSize = 16*lx*ly: goto 40

10 rem coords
11 w$ = "   " + str$(x) + "," + str$(y): poke 233,8*16: &mode=0: &print w$ at 41-len(w$),1
12 &print "pen=" + str$(pd) at 36,2: i = fre(0)
13 poke 233,a0/256: &mode=128: return

15 poke 233,8*16: &mode=0: &clear 1,24: &mode=128: &print w$ at 1,24: poke 233,a0/256: return: rem progress message
16 poke 233,8*16: &mode=0: &clear 1,24: goto 13: rem finish progress and return

20 rem edit prompt
21 poke 233,8*16: &mode=0: &clear 1,21 to 40,24
22 &print "SPC=toggle pixel, TAB=toggle pen" at 1,21
23 &print chr$(128) + chr$(132) + "=move, ESC=menu" at 1,22
24 &print "p=preview, d=dither" at 1,23: goto 10

30 rem get upper
31 a = peek(49152): if a<128 then 31
32 a = a - 128: if a>96 then a = a - 32
33 poke 49168,0: return

40  TEXT : HOME : PRINT "SDP II Tiler v-dev": VTAB 13: PRINT "tiles=";tilNum;" bytes=";2+tilNum*tSize:L = 3:P = 6:W$ = "Select- ":B$ =  CHR$ (13)
41 PN$(0) = "New Set":PN$(1) = "Append Set":PN$(2) = "Save Set":PN$(3) = "Edit":PN$(4) = "View":PN$(5) = "Catalog":PN$(6) = "Exit": GOSUB 50
42  ON M + 1 GOTO 400,500,1000,1050,1100,1150,1200

50  rem menu subroutine
51 N = 0:M = 0: HTAB 1: VTAB L: PRINT "1) ";: INVERSE : PRINT PN$(0): NORMAL : IF P > 0 THEN  FOR I = 1 TO P: PRINT I + 1;") ";PN$(I): NEXT 
52  HTAB 1: VTAB L + P + 2: PRINT W$;: GET A$: IF A$ =  CHR$ (13) OR A$ = B$ THEN  RETURN 
53  IF  VAL (A$) >  = 1 AND  VAL (A$) <  = P + 1 THEN M =  VAL (A$) - 1: RETURN 
54  IF A$ =  CHR$ (8) OR A$ =  CHR$ (11) THEN N = M:M = M - 1: IF M < 0 THEN M = P
55  IF A$ =  CHR$ (10) OR A$ =  CHR$ (21) THEN N = M:M = M + 1: IF M > P THEN M = 0
56  HTAB 4: VTAB N + L: PRINT PN$(N): INVERSE : HTAB 4: VTAB M + L: PRINT PN$(M): NORMAL : GOTO 52

60 rem edit loop
61  gosub 110: gosub 30: gosub 110: gosub 90
62  if a = asc("P") then gosub 200: goto 60
63  if a = 32 then gosub 110: goto 60
64  if a = 27 then  gosub 130: home: vtab 21 : goto 40
65  if a = asc("D") then gosub 210: goto 60
66  if a = 9 then pd = pd = 0: gosub 10
89  goto 60

90 rem move cursor
91  ds = 1 + (peek(49249)>127)*7: if pd then gosub 110
92  if a = 8 then x = x - ds: x = x - lx*14*int(x/lx/14)
93  if a = 11 then y = y - ds: y = y - ly*8*int(y/ly/8)
94  if a = 21 then x = x + ds: x = x - lx*14*int(x/lx/14)
95  if a = 10 then y = y + ds: y = y - ly*8*int(y/ly/8)
99  gosub 10: return

110  rem stroke
111  &stroke #1 at x*dx+4,yg+y*dy+2: &hplot x,y: return

120 rem draw grid
121 &hcolor = 1,0,1,0
122 for j = 0 to ly*8: &hplot 0,yg+j*dy to lx*14*dx,yg+j*dy: next
123 return

130 rem scan tile
131 w$ = "SCANNING...": gosub 15: for j=0 to ly*8-1: for i=0 to lx-1: &move to i*14,j: addr = peek(38) + peek(39)*256
132 poke 49237,0: b1 = peek(addr+i): poke 49236,0: b2 = peek(addr+i)
133 addr = a0 + 2 + id*tSize + j*lx*2 + i*2: poke addr,b1: poke addr+1,b2
134 next: next: goto 16

140 rem fill grid
141 gosub 130: w$ = "FILL GRID...": gosub 15: b = yg + 2: addr = a0 + 2 + id*tSize
142 for j=0 to ly*8-1: a = 4: for i=0 to lx*2-1: for bit=0 to 6: st = peek(addr): &bit (bit,st): &mode = 128 + 32 * not st: &stroke #1 at a,b: a = a + dx: next: addr = addr + 1: next: b = b + dy: next: goto 16

150 rem swap
151 i = 0: j = 1: &clear 1,24: &print "swap partner 1" at 1,24
152 poke 233,a0/256: &tile #i at 1,21: gosub 30: i = i + (a=21) - (a=8): i = i - tilNum*int(i/tilNum)
153 if a = 32 then poke 233,8*16: &print "2" at 14,24: goto 160
154 if a = 27 then return
155 goto 152
160 poke 233,a0/256: &tile #j at 1,21: gosub 30: j = j + (a=21) - (a=8): j = j - tilNum*int(j/tilNum)
161 if a = 32 then 169
162 if a = 27 then return
163 goto 160
169 a = a0 + 2 + i*tSize: b = a0 + 2 + j*tSize: for n = 0 to tSize-1: m = peek(a+n): poke a+n,peek(b+n): poke b+n,m: next: return

200 rem preview
201 gosub 130: &mode=0: for i = 0 to 1: for j = 0 to 1: &tile #id at 21+i*lx,1+j*ly: next: next
202 &mode=128: return

210 rem dither
211 ci = 1: &mode=0: gosub 900: &hcolor=cl(1),cl(2),cl(3),cl(4): &clear 1,1 to 40,24: &trap at 0,lx*14-1,0 to 0,lx*14-1,ly*8-1
212 &hcolor=15: gosub 120: gosub 140: gosub 20: return

400  rem init tile set
410  home: input "tile columns (14 pix each): ";lx: IF lx < 1 OR lx>8 THEN 410
420  input "tile rows (8 pix each): ";ly: if ly<1 or ly>4 then 420
430  poke a0,lx: poke a0+1,ly: tilNum = 0: tSize = lx*ly*16: yg = 2+16*ly: goto 40

500  rem append tile set (assumes compatibility)
501 home: input "path: ";a$: addr = a0 + tilNum*tSize: b1 = peek(addr): b2 = peek(addr+1)
502 onerr goto 1049
503 print chr$(4);"bload ";a$;",a";addr: lx = peek(addr): ly = peek(addr+1): tSize = lx*ly*16
504 if addr>a0 then 506
505 l = tilNum*tSize + fn gt16(48840): tilNum = (l-2)/tSize: goto 508
506 poke addr,b1: poke addr+1,b2: if lx <> peek(a0) or ly <> peek(a0+1) then print "incompatible size": gosub 30: goto 508
507 goto 505
508 poke 216,0: goto 40

800 rem arrays
810 dim pn$(9): dim cl(4): for i = 0 to 4: cl(i) = 15: next
820 return

900 rem color picker
901 &clear 1,24: a$ = chr$(130) + chr$(131) + ", SPC": if ci > 0 then a$ = a$ + ", TAB"
902 poke 233,8*16: &print a$ at 3+2*(ci>0),24: poke 233,a0/256
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

1000 rem save tile set
1010 home: input "path: ";a$
1020 onerr goto 1049
1021 print chr$(4);"bsave ";a$;",a";a0;",l";2+tilNum*tSize: poke 216,0: goto 40
1049 print "disk error": call -3288: get a$: poke 216,0: goto 40

1050  rem edit tile
1051  home: input "tile id: ";id
1052  if id=tilNum then tilNum = tilNum + 1: x=0: y=0: &dhr: goto 1070
1053  if id>tilNum then print "next tile is ";tilNum: get a$: goto 40
1060  &dhr: x = 0: y = 0: &tile #id at 1,1
1070  poke -16302,0: gosub 20: &mode=0: &hcolor=15: gosub 120: &mode=128: gosub 140: goto 60

1100  rem overview
1101  &dhr: poke -16302,0: x = 1: y = 1: for i = 1 to tilNum
1102  poke 233,a0/256: &tile #i-1 at x,y: poke 233,8*16: &print str$(i-1) at x,y+ly: x = x + lx
1103  if x>40 then x = 1: y = y + ly*2
1104  next
1110  &mode=0: poke 233,8*16: &print "ESC=exit, SPC=swap" at 1,24: gosub 30
1111  if a = 27 then poke 233,a0/256: goto 40
1112  if a = 32 then gosub 150: goto 1100
1113  goto 1110

1150 rem catalog
1160 text:home: print chr$(4);"catalog"
1170 input "enter prefix or bye: ";a$
1180 if a$="bye" or a$="BYE" then 40
1185 onerr goto 1199
1190 print chr$(4);"prefix ";a$: poke 216,0: goto 1160
1199 print "disk error try again": call -3288: goto 1170

1200 rem quit
1210 home: vtab 21: end
