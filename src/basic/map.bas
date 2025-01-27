1 gosub 892: lomem: 35584: if peek(-1088)=234 then text: home: print chr$(7);"65C02 PROCESSOR REQUIRED": end
2  def  fn gt16(addr) =  peek (addr) + 256 *  peek (addr + 1)
4  print chr$(4);"bload maplib": poke 1013,76: poke 1014,0: poke 1015,64: gosub 890
6  print chr$(4);"bload font1": print chr$(4);"pr#3": poke 232,0: poke 233,96: &aux: poke 233,0
7 x = 20: y = 20: lx = 40: ly = 40: poke a0,lx: poke a0+1,ly: gosub 800: gosub 1300
8 &vers: &pul > vers(0): &pul > vers(1): &pul > vers(2): goto 70

10 rem tile selection, tile count of 16 is hard coded here
11 pd = pd + 1: if pd > 15 then pd = 0
12 if pd < 0 then pd = 15
13 &tile #pd at 39,21: return

18 rem indefinite progress
19 &clear 1,21 to 40,24: &mode = 128: &print "Working..." at 1,21: &mode = 0: return

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
61 &clear 1,21 to 40,24
62 &print chr$(128) + chr$(129) + "SPC=place, `=prev, TAB=next" at 1,21
63 &print chr$(128) + chr$(129) + chr$(132) + "=move, ESC=menu" at 1,22
64 rem coords
65 w$ = "  " + str$(x) + "," + str$(y): &tile #pd at 39,21: &print w$ at 41-len(w$),24: i = fre(0): return

70  text : home : print "SDP II Mapper "vers(0)"."vers(1)"."vers(2): vtab 13: print "size=";lx;",";ly: l = 3: p = 6: w$ = "Select- ": b = 13
71 pn$(0) = "Load Tiles": pn$(1) = "New Map": pn$(2) = "Load Map": pn$(3) = "Save Map": pn$(4) = "Edit": pn$(5) = "Catalog": pn$(6) = "Exit": gosub 30
72  on m + 1 goto 450,400,500,1000,1050,1150,1200

80 rem edit loop
81  gosub 20: if a = 8 or a = 11 or a = 21 or a = 10 then gosub 90: goto 81
82  if a = 32 then gosub 100: goto 80
83  if a = 27 then  gosub 130: home: vtab 21 : goto 70
84  if a = 9 then gosub 10: goto 80
85  if a = 96 then pd = pd - 2: gosub 10: goto 80
86  goto 80

90 rem scroll map
91  ds = 1 + (peek(49249)>127)*-2: p = a0 + 2 + x + y*lx: if peek (49250)>127 then poke p,pd
92  dx = ds*((a = 21) - (a = 8)): dy = ds*((a = 10) - (a = 11)): x = x + dx: y = y + dy: &mod(x,lx): &mod(y,ly)
96  poke 0,a1lo: poke 1,a2hi: if ds = 1 then 150
99  &map at x-6,y-4 to x+6,y+4 at 1,1: &tile #15 at 13,9: gosub 64: return

100 rem place tile(s)
101 if peek(49249)>127 then 104
102 if peek(49250)>127 then 105
103 poke a0 + 2 + x + y*lx,pd: return
104 gosub 18: for i = x-2 to x+2: for j = y-1 to y+1: poke a0 + 2 + i + j*lx,pd: next: next: gosub 60: ds = 0: goto 96
105 gosub 18: for i = x-4 to x+4: for j = y-3 to y+3: poke a0 + 2 + i + j*lx,pd: next: next: gosub 60: ds = 0: goto 96

130 rem close to menu
140 return

150 rem complicated scroll
151  &tile #peek(p) at 13,9
155  &map at x-6,y-4 to x+6,y+4 at 1,1 step dx*2,dy*2
159  &tile #15 at 13,9: gosub 64: return

400 rem init map
410  gosub 600: home: input "map columns: ";lx: IF lx < 1 OR lx>128 THEN 410
420  input "map rows: ";ly: if ly<1 or ly>128 then 420
421  input "starting tile: ";a: if a<0 or a>47 then 421
422  poke a0,lx: poke a0+1,ly: x = a0 + 2: y = x + lx*ly - 1
423  if y >= 35584 then print chr$(7);"not enough workspace": get a$: goto 410
430  print "fill first page...": for addr = x to x + 255: poke addr,a: next: a = 2: addr = addr - 256
431  htab 1: vtab 5: print "copy to page ";a
432  poke 60,addr - 256*int(addr/256): poke 61,int(addr/256): addr = addr + 255
433  poke 62,addr - 256*int(addr/256): poke 63,int(addr/256): poke 66,peek(60): poke 67,peek(61)+1: addr = addr + 1
434  call 768: if addr + 256 + 255 > y then 440
435  a = a + 1: goto 431
440 if addr + 255 = y then map = 1: goto 70
441 print "fill remainder...": x = addr + 256: a = peek(addr-1): for addr = x to y: poke addr,a: next: map = 1: goto 70

450 rem load tiles
451  home: if a0 + 2 + lx*ly >= 24576 then print "need to restart first": get a$: goto 70
460  input "tile path: ";a$
461  onerr goto 1049
462  print chr$(4);"bload ";a$;",a$6000": poke 233,96: &bank: poke 233,0 
463  tiles = 1: poke 216,0: goto 70

500 rem load map
501  gosub 600: home: input "map path: ";a$
502  onerr goto 1049
503  print chr$(4);"bload ";a$;",a";a0: lx = peek(a0): ly = peek(a0+1)
508  map = 1: poke 216,0: goto 70

600 rem check tiles, may pop stack
601 if tiles <> 1 then home: print "load tiles first": get a$: pop: goto 70
602 return

700 rem check map, may pop stack
701 if map <> 1 then home: print "init or load map first": get a$: pop: goto 70
702 return

800 rem arrays
810  dim pn$(9): dim vers(2)
820  return

890 rem map workspace
891 a0 = peek (48825) + 256 * peek (48826) + peek (48840) + 256 * peek(48841): a1lo = a0: &mod(a1lo,256): a2hi = int(a0/256): return

892 rem check himem
893 hm = peek (115) + 256 * peek (116): if hm < 9*4096 then print "HIMEM TOO LOW": end
894 return

1000 rem save map
1010 home: input "save path: ";a$
1020 onerr goto 1049
1021 print chr$(4);"bsave ";a$;",a";a0;",l";lx*ly+2: poke 216,0: goto 70
1049 print "disk error": call -3288: get a$: poke 216,0: goto 70

1050  rem edit map
1060  gosub 600: gosub 700: &dhr: x = lx/2: y = ly/2: pd = 0
1070  poke -16302,0: gosub 60: ds = 0: gosub 96: goto 80

1150 rem catalog
1160 text:home: print chr$(4);"catalog"
1170 input "enter prefix or bye: ";a$
1180 if a$="bye" or a$="BYE" then 70
1185 onerr goto 1199
1190 print chr$(4);"prefix ";a$: poke 216,0: goto 1160
1199 print "disk error try again": call -3288: goto 1170

1200 rem quit
1210 home: vtab 21: print "confirm (Y/N) ": get a$: if a$ = "Y" then end
1220 goto 70

1300 rem setup move memory call
1310 poke 768,160: poke 769,0: poke 770,32: poke 771,44: poke 772,254: poke 773,96: return
