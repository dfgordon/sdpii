1 if peek(-1088)=234 then text: home: print chr$(7);"65C02 PROCESSOR REQUIRED": end
2  DEF  FN GT16(ADDR) =  PEEK (ADDR) + 256 *  PEEK (ADDR + 1)
4  print chr$(4);"bload dhrlib": print chr$(4);"pr#3"
5  poke 1013,76: poke 1014,0: poke 1015,64
6 lx = 1: ly = 1: dx = 8: dy = 6: yg = 2+16*ly: a0 = 96*256: poke a0,lx: poke a0+1,ly: gosub 800
7 poke 232,0: poke 233,a0/256: tilNum = 0: tSize = 16*lx*ly: goto 40

20 rem edit prompt
21 poke 49236,0: home: vtab 21
22 print "spc=toggle pixel, tab=toggle pen"
24 print "p=preview, d=dither"
25 print "(apple)arrows=movement, esc=menu";
29 poke 49237,0: htab 67: vtab 24: print "pos ";x;",";y;"  ";: return

30 rem get upper
31 a = peek(49152): if a<128 then 31
32 a$ = chr$(a-128): if asc(a$)>96 then a$ = chr$(asc(a$)-32)
33 poke 49168,0: return

40  TEXT : HOME : PRINT "SDP II Tiler v-dev": VTAB 13: PRINT "tiles=";tilNum;" bytes=";2+tilNum*tSize:L = 3:P = 6:W$ = "Select- ":B$ =  CHR$ (13)
41 PN$(0) = "New Set":PN$(1) = "Append Set":PN$(2) = "Save Set":PN$(3) = "Edit":PN$(4) = "View":PN$(5) = "Catalog":PN$(6) = "Exit": GOSUB 50
42  ON M + 1 GOTO 900,950,1000,1050,1100,1150,1200

50  rem menu subroutine
51 N = 0:M = 0: HTAB 1: VTAB L: PRINT "1) ";: INVERSE : PRINT PN$(0): NORMAL : IF P > 0 THEN  FOR I = 1 TO P: PRINT I + 1;") ";PN$(I): NEXT 
52  HTAB 1: VTAB L + P + 2: PRINT W$;: GET A$: IF A$ =  CHR$ (13) OR A$ = B$ THEN  RETURN 
53  IF  VAL (A$) >  = 1 AND  VAL (A$) <  = P + 1 THEN M =  VAL (A$) - 1: RETURN 
54  IF A$ =  CHR$ (8) OR A$ =  CHR$ (11) THEN N = M:M = M - 1: IF M < 0 THEN M = P
55  IF A$ =  CHR$ (10) OR A$ =  CHR$ (21) THEN N = M:M = M + 1: IF M > P THEN M = 0
56  HTAB 4: VTAB N + L: PRINT PN$(N): INVERSE : HTAB 4: VTAB M + L: PRINT PN$(M): NORMAL : GOTO 52

60 rem edit loop
61  gosub 110: gosub 30: gosub 110: gosub 90
62  if a$ = "P" then gosub 200: goto 60
63  if a$ = " " then gosub 110: goto 60
64  if a$ = chr$(27) then  gosub 130: home: vtab 21 : goto 40
65  if a$ = "D" then gosub 9000: goto 60
66  if a$ = chr$(9) then pd = pd = 0
89  goto 60

90 rem move cursor
91  if pd then gosub 110
92  if a$ = chr$(8) then x = x - 1
93  if a$ = chr$(11) then y = y - 1
94  if a$ = chr$(21) then x = x + 1
95  if a$ = chr$(10) then y = y + 1
100  if x<0 then x = lx*14-1
101  if x>=lx*14 then x = 0
102  if y<0 then y = ly*8-1
103  if y>=ly*8 then y = 0
104  gosub 29: return

110  rem stroke
111  &stroke #1 at x*dx+4,yg+y*dy+2: &hplot x,y: return

120 rem draw grid
121 for j = 0 to ly*8: &hplot 0,yg+j*dy to lx*14*dx,yg+j*dy: next
122 for i = 0 to lx*14: &hplot i*dx,yg to i*dx,yg+ly*8*dy: &hplot i*dx+1,yg to i*dx+1,yg+ly*8*dy: next
123 return

130 rem scan tile
131 for j=0 to ly*8-1: for i=0 to lx-1: jm = j - 8*int(j/8)
132 addr = 8192 + jm*1024 + int(j/8)*128: poke 49237,0: b1 = peek(addr+i): poke 49236,0: b2 = peek(addr+i)
133 addr = a0 + 2 + id*tSize + j*lx*2 + i*2: poke addr,b1: poke addr+1,b2
134 next: next: return

140 rem fill grid
141 gosub 130
142 for j=0 to ly*8-1: for i=0 to lx*2-1
143 addr = a0 + 2 + id*tSize + j*lx*2 + i
144 for bit=0 to 6: st = peek(addr): &bit (bit,st): if st then &stroke #1 at dx*(i*7+bit)+4,yg+j*dy+2
145 next: next: next: return

200 rem preview
210 gosub 130: for i = 0 to 1: for j = 0 to 1: &tile #id at 21+i*lx,1+j*ly: next: next
220 return

300 rem fill
310 &hcolor = c1,c2,c3,c4: &mode=0
320 &trap at 0,lx*14-1,0 to 0,lx*14-1,ly*8-1: &mode=128: gosub 20: return

800 rem arrays
810 dim pn$(9): dim cl$(15): for i = 0 to 15: read cl$(i): next
820 return

900  rem init tile set
910  home: input "tile columns (14 pix each): ";lx: IF lx < 1 OR lx>8 THEN 910
920  input "tile rows (8 pix each): ";ly: if ly<1 or ly>4 then 920
930  poke a0,lx: poke a0+1,ly: tilNum = 0: tSize = lx*ly*16: yg = 2+16*ly: goto 40

950  rem append tile set (assumes compatibility)
960 home: input "path: ";a$: addr = a0 + tilNum*tSize: b1 = peek(addr): b2 = peek(addr+1)
961 onerr goto 1049
962 print chr$(4);"bload ";a$;",a";addr: lx = peek(addr): ly = peek(addr+1): tSize = lx*ly*16
963 if addr>a0 then 980
964 l = tilNum*tSize + fn gt16(48840): tilNum = (l-2)/tSize: goto 999
980 poke addr,b1: poke addr+1,b2: if lx <> peek(a0) or ly <> peek(a0+1) then print "incompatible size": gosub 30: goto 999
985 goto 964
999 poke 216,0: goto 40

1000 rem save tile set
1010 home: input "path: ";a$
1020 onerr goto 1049
1021 print chr$(4);"bsave ";a$;",a";a0;",l";2+tilNum*tSize: poke 216,0: goto 40
1049 print "disk error": call -3288: get a$: poke 216,0: goto 40

1050  rem edit tile
1051  home: input "tile id: ";id
1052  if id=tilNum then tilNum = tilNum + 1: c1=0: c2=0: c3=0: c4=0: x=0: y=0: &dhr: gosub 300: goto 1070
1053  if id>tilNum then print "next tile is ";tilNum: get a$: goto 40
1060  &dhr: x = 0: y = 0: &tile #id at 1,1
1070  gosub 20: &mode=0: &hcolor=15: gosub 120: &mode=128: pen = 0: gosub 140: goto 60

1100  rem overview
1110  &dhr: x = 1: y = 1: for i = 1 to tilNum
1120  &tile #i-1 at x,y: x = x + lx
1130  if x>40 then x = 1: y = y + ly
1140  next: get a$: goto 40

1150 rem catalog
1160 text:home: print chr$(4);"catalog"
1170 input "enter prefix or bye: ";a$
1180 if a$="bye" or a$="BYE" then 40
1185 onerr goto 1199
1190 print chr$(4);"prefix ";a$: poke 216,0: goto 1160
1199 print "disk error try again": call -3288: goto 1170

1200 rem quit
1210 home: end

9000 rem dither picker
9001 p$ = "r1c1": gosub 9010: c1 = b: p$ = "r1c2": gosub 9010: c2 = b
9002 p$ = "r2c1": gosub 9010: c3 = b: p$ = "r2c2": gosub 9010: c4 = b
9003 gosub 300: return
9010 b = 0
9011 if b>15 then b = 0
9012 if b<0 then b = 15
9020 home: vtab 21: print "dither color ";p$;": ";cl$(b): print "use arrows, return": get a$
9030 if a$ = chr$(13) then return
9040 if a$ = chr$(8) then b = b - 1: goto 9011
9050 if a$ = chr$(21) then b = b + 1: goto 9011
9060 goto 9011
9990 data black,blue,green,cyan,brown,grey-brown,light green,aquamarine,magenta,purple,grey-green,blue-grey,red,pink,yellow,white
