1 himem: 8192: if peek(-1088)=234 then text: home: print chr$(7);"65C02 PROCESSOR REQUIRED": end
2  def  fn gt16(addr) =  peek (addr) + 256 *  peek (addr + 1)
4  print chr$(4);"bload dhrlib": print chr$(4);"bload font1,a$8000": print chr$(4);"pr#3"
6  poke 1013,76: poke 1014,0: poke 1015,64
7 x = 40: y = 40: lx = 80: ly = 80: a0 = 7*4096: poke a0,lx: poke a0+1,ly: gosub 800
8 poke 232,0: poke 233,96: &vers: &pul > vers(0): &pul > vers(1): &pul > vers(2): goto 70

10 rem tile selection, tile count of 16 is hard coded here
11 pd = pd + 1: if pd > 15 then pd = 0
12 if pd < 0 then pd = 15
13 &tile #pd at 39,21: return

18 rem indefinite progress
19 poke 233,128: &clear 1,21 to 40,24: &mode = 128: &print "Working..." at 1,21: &mode = 0: return

20 rem get upper
21 a = peek(49152): if a < 128 then 21
22 a = a - 128: if a > 96 then a = a - 32
23 poke 49168,0: return

30  rem menu subroutine
31 n = 0: m = 0: htab 1: vtab l: print "1) ";: inverse : print pn$(0): normal: if p > 0 then  for i = 1 to p: print i + 1;") ";pn$(i): next 
32  htab 1: vtab l + p + 2: print w$;: gosub 20: if a =  13 or a = b then  return 
33  if  a > 48 and  a <= 49 + p then m =  a - 49: return 
34  if a =  8 or a =  11 then n = m: m = m - 1: if m < 0 then m = p
35  if a =  10 or a =  21 then n = m: m = m + 1: if m > p then m = 0
36  htab 4: vtab n + l: print pn$(n): inverse: htab 4: vtab m + l: print pn$(m): normal: goto 32

60 rem edit prompt
61 poke 233,128: &clear 1,21 to 40,24
62 &print chr$(128) + chr$(129) + "SPC=place, `=prev, TAB=next" at 1,21
63 &print chr$(128) + chr$(129) + chr$(132) + "=move, ESC=menu" at 1,22
64 rem coords
65 w$ = "  " + str$(x) + "," + str$(y): &tile #pd at 39,21: poke 233,128: &print w$ at 41-len(w$),24: poke 233,96: i = fre(0): return

70  text : home : print "SDP II Mapper "vers(0)"."vers(1)"."vers(2): vtab 13: print "size=";lx;",";ly: l = 3: p = 5: w$ = "Select- ": b = 13
71 pn$(0) = "New Map": pn$(1) = "Load Tiles": pn$(2) = "Load Map": pn$(3) = "Save Map": pn$(4) = "Edit": pn$(5) = "Catalog": pn$(6) = "Exit": gosub 30
72  on m + 1 goto 400,450,500,1000,1050,1150,1200

80 rem edit loop
81  gosub 20: if a = 8 or a = 11 or a = 21 or a = 10 then gosub 90: goto 81
82  if a = 32 then gosub 100: goto 80
83  if a = 27 then  gosub 130: home: vtab 21 : goto 70
84  if a = 9 then gosub 10: goto 80
85  if a = 96 then pd = pd - 2: gosub 10: goto 80
86  goto 80

90 rem scroll map
91  ds = 1 + (peek(49249)>127)*7: p = a0 + 2 + x + y*lx: if peek (49250)>127 then poke p,pd
92  if a = 8 then x = x - ds: &mod(x,lx)
93  if a = 11 then y = y - ds: &mod(y,ly)
94  if a = 21 then x = x + ds: &mod(x,lx)
95  if a = 10 then y = y + ds: &mod(y,ly)
96  poke 0,0: poke 1,a0/256: rem if ds = 1 then 150
99  &map at x-5,y-4 to x+5,y+4 at 3,2: &tile #15 at 13,10: gosub 64: return

100 rem place tile(s)
101 if peek(49249)>127 then 104
102 if peek(49250)>127 then 105
103 poke a0 + 2 + x + y*lx,pd: return
104 gosub 18: for i = x-2 to x+2: for j = y-1 to y+1: poke a0 + 2 + i + j*lx,pd: next: next: gosub 60: ds = 0: goto 96
105 gosub 18: for i = x-4 to x+4: for j = y-3 to y+3: poke a0 + 2 + i + j*lx,pd: next: next: gosub 60: ds = 0: goto 96

130 rem close to menu
140 return

150 rem complicated scroll
151  &tile #peek(p) at 13,10
152  if a = 8 then &scroll at 3,2 to 24,19 step -2,0: &map at x-5,y-4 to x-5,y+4 at 3,2: goto 159
153  if a = 11 then &scroll at 3,2 to 24,19 step 0,-2: &map at x-5,y-4 to x+5,y-4 at 3,2: goto 159
154  if a = 21 then &scroll at 3,2 to 24,19 step 2,0: &map at x+5,y-4 to x+5,y+4 at 23,2: goto 159
155  if a = 10 then &scroll at 3,2 to 24,19 step 0,2: &map at x-5,y+4 to x+5,y+4 at 3,18
159  &tile #15 at 13,10: gosub 64: return

400 rem init map
410  home: input "map columns: ";lx: IF lx < 1 OR lx>128 THEN 410
420  input "map rows: ";ly: if ly<1 or ly>128 then 420
430  poke a0,lx: poke a0+1,ly: for addr = a0+2 to a0+2+lx*ly: poke addr,0: next: goto 70

450 rem load tiles
460  home: input "path: ";a$
461  onerr goto 1049
462  print chr$(4);"bload ";a$;",a$6000"
463  tiles = 1: poke 216,0: goto 70

500 rem load map
501  home: input "path: ";a$
502  onerr goto 1049
503  print chr$(4);"bload ";a$;",a$7000": lx = peek(a0): ly = peek(a0+1)
508  poke 216,0: goto 70

800 rem arrays
810  dim pn$(9): dim vers(2)
820  return

1000 rem save map
1010 home: input "path: ";a$
1020 onerr goto 1049
1021 print chr$(4);"bsave ";a$;",a";a0;",l";lx*ly+2: poke 216,0: goto 70
1049 print "disk error": call -3288: get a$: poke 216,0: goto 70

1050  rem edit map
1051  if tiles <> 1 then home: print "load tile first": get a$: goto 70
1060  &dhr: x = lx/2: y = ly/2: pd = 0
1070  poke -16302,0: gosub 60: ds = 0: gosub 96: goto 80

1150 rem catalog
1160 text:home: print chr$(4);"catalog"
1170 input "enter prefix or bye: ";a$
1180 if a$="bye" or a$="BYE" then 70
1185 onerr goto 1199
1190 print chr$(4);"prefix ";a$: poke 216,0: goto 1160
1199 print "disk error try again": call -3288: goto 1170

1200 rem quit
1210 home: vtab 21: end


