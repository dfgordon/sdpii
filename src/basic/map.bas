1 gosub 895: lomem: 35584: lom=35584: if peek(-1088)=234 then text: home: print chr$(7);"65C02 PROCESSOR REQUIRED": end
2  d$ = chr$(4): def fngt16(addr) =  peek (addr) + 256 *  peek (addr + 1): def fndcount(x) = peek(a0+4-8*(m0=a0))
3  print d$;"bload maplib": poke 1013,76: poke 1014,0: poke 1015,64: gosub 890
4  print d$;"bload font1": poke 232,0: poke 233,96: &aux: poke 233,0
5 vwidth = 15: vheight = 11: xhalf = 7: yhalf = 5: x00 = 1: y00 = 1: gosub 800: gosub 1300
6 &vers: &pul > vers(0): &pul > vers(1): &pul > vers(2): gosub 40: gosub 8: goto 60

8 text: home: print d$;"pr#3": print chr$(17): return: rem 40 column text home
9 home: print chr$(18): &dhr: poke -16302,0: &pr#: return: rem DHR home

10 rem tile selection
11 pd = pd + 1: &mod(pd,tcount): &tile #pd at 39,21: return

18 rem indefinite progress
19 &clear 1,23 to 40,24: &mode = 128: vtab 23: print "Working...": &mode = 0: return

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

40 rem read configuration
41 print d$;"prefix": input wd$: print d$;"open sdpii.config": print d$;"read sdpii.config"
42 input a: input a$: input map$: input tile$: if a > 0 then input avtar: input bound: input inner
43 print d$;"close sdpii.config": if map$="" then map$=wd$
44 if tile$="" then tile$=wd$
45 & av #avtar: return

50 rem edit prompt
51 &clear 1,23 to 40,24: vtab 23
52 print chr$(5)chr$(6)"SPC=place, `/TAB=select, +/-=level"
53 print chr$(5)chr$(6)chr$(9)"=move, B=bound, "chr$(5)chr$(6)"D=denizen, ESC=menu"
54 rem coords
55 w$ = str$(x) + "," + str$(y) + "," + str$(z): htab 41-len(w$): vtab 1: &tile #pd at 39,21: &clear 32,1: print w$: i = fre(0): return

60 rem main menu
61  gosub 8: m = fre(0): print "SDP II Mapper "vers(0)"."vers(1)"."vers(2): l = 3: p = 8: vtab l+p+4
62 print "size=";lx;",";ly: print "tiles=";tcount: print "levels=";lz: print "denizens=";fndcount(0)
63 w$ = "Select- ": b = 13: gosub 30
64  on m + 1 goto 450,400,500,1000,1050,1100,900,1150,1200

70 rem edit loop
71  gosub 20: dx = (a = 21 or a = 51 or a = 54 or  a = 57) - (a = 8 or a = 49 or a = 52 or a = 55): dy = (a = 10 or a >= 49 and a <= 51) - (a = 11 or a >= 55 and a <= 57)
72  if dx <> 0 or dy <> 0 then gosub 90: goto 70
73  if a = 32 then gosub 100: goto 70
74  if a = 27 then  gosub 130: home: vtab 21 : goto 60
75  if a = 9 then gosub 10: goto 70
76  if a = 96 then pd = pd - 2: gosub 10: goto 70
77  if a = asc("B") then gosub 200: goto 70
78  if a = asc("+") then gosub 870: gosub 96: goto 70
79  if a = asc("-") then gosub 880: gosub 96: goto 70
80  if a = asc("D") then gosub 150: gosub 50: goto 70
81  goto 70

90 rem scroll map
91  ds = 1 + (peek(49249)>127)*3: if peek (49250)>127 then gosub 103
92  x = x + dx*ds: y = y + dy*ds: &mod(x,lx): &mod(y,ly)
96  poke 0,a1lo: poke 1,a2hi
99  &map at x-xhalf,y-yhalf to x+xhalf,y+yhalf at x00,y00: gosub 54: return

100 rem place tile(s)
101 if peek(49249)>127 then dx=2: dy=1: goto 105
102 if peek(49250)>127 then dx=4: dy=3: goto 105
103 i=x: j=y
104 p = l0 + 6 + i + j*lx: a = peek(p): &and(a,128): poke p,pd+a: return
105 gosub 18: gosub 110: for i = x-dx to x+dx: for j = y-dy to y+dy: gosub 104: next: next: gosub 50: goto 96
110 if x < dx or x + dx >= lx or y < dy or y + dy >= ly then 120
111 return
120 vtab 23: print "out of range error": get a$: gosub 50: pop: return

130 rem close to menu
140 return

150 rem place or remove denizen
151 i = l0 + 6 + x + y*lx: j = peek(i): &and(j,127): &clear 1,24: htab 1: vtab 24
152 if peek(49249)>=128 then 160
153 if fndcount(0)>63 or d0 + 4*fndcount(0) + 4 > lom then print "no room": get a$: return
155 a = 48: if peek(49250)>=128 then print "type digit for aux value": gosub 20
159 poke i,j+128: &den(1,pd,a-48,i-a0+8*(a0=m0)): return
160 poke i,j: &den(255,0,0,i-a0+8*(a0=m0)): return

200 rem set boundary tiles
210 &clear 1,23: &clear 1,24: vtab 23: print "type N, S, E, or W": gosub 20
220 if a = asc("N") then poke l0 + 2, pd
221 if a = asc("S") then poke l0 + 3, pd
222 if a = asc("E") then poke l0 + 4, pd
223 if a = asc("W") then poke l0 + 5, pd
230 gosub 50: goto 96

300 a$ = tile$: goto 320: rem enter tile path
310 a$ = map$: rem enter map path
320 home: print d$;"prefix ";a$: print "prefix: ";a$: input "path: ";a$: return

400 rem init map
410  gosub 600: home: input "map columns: ";lx: if lx<16 or lx>128 then 410
411  input "map rows: ";ly: if ly<16 or ly>128 then home: goto 411
412  input "map levels: ";lz: if lz<1 or lx*ly*lz > 16384 then home: goto 412
421  print "starting tile:": temp$ = str$(inner): gosub 950: if a<0 or a>47 then home: goto 421
422  x = a0 + 6: d0 = a0 + (6+lx*ly)*lz
423  if d0 > lom then print chr$(7);"not enough workspace": get a$: goto 410
424  m0 = a0: aux = 0: gosub 850: &den(0,a0-8,0,d0): gosub 860
430  print "fill first page...": for addr = x to x + 255: poke addr,a: next: a = 2: addr = addr - 256
431  htab 1: vtab 7: print "copy to page ";a
432  poke 60,addr - 256*int(addr/256): poke 61,int(addr/256): addr = addr + 255
433  poke 62,addr - 256*int(addr/256): poke 63,int(addr/256): poke 66,peek(60): poke 67,peek(61)+1: addr = addr + 1
434  call 768: if addr + 512 > d0 then 440: rem destination is the last page
435  a = a + 1: goto 431
440 if addr + 256 = d0 then map = 1: goto 442: rem there is no remainder page
441 print "fill remainder...": x = addr + 256: a = peek(addr-1): for addr = x to d0-1: poke addr,a: next: map = 1
442 for i = 1 to lz: gosub 445: gosub 870: next: gosub 860: goto 60

445 rem setup level header
446 poke l0,lx: poke l0+1,ly: poke l0+2,bound: poke l0+3,bound: poke l0+4,bound: poke l0+5,bound: return 

450 rem load tiles
451  home: if d0 + 4*fndcount(0) > 24576 then print "save and restart program first": get a$: goto 60
460  gosub 300: onerr goto 1049
462  print d$;"bload ";a$;",a$6000": if peek(24576) <> 2 or peek(24577) <> 2 then print "incompatible tiles": get a$: poke 216,0: goto 60
470  call 780: poke 233,96: &bank: poke 233,0: tcount = (fn gt16 (48840) - 2) / 64
471  print "tiles stashed in bank 2 at $D400": print "IRQ is disabled"
472  print "saving displaced memory..."
473  print d$;"bsave ";wd$;"d400.bank2.save,a$6002,l$c00"
474  tiles = 1: poke 216,0: goto 60

500 rem load map
501  gosub 600: gosub 310: onerr goto 1049
503  print d$;"bload ";a$;",a";a0: if peek(a0)=0 then 510
504  m0 = a0: lx = peek(m0): ly = peek(m0+1)
505  lz = fn gt16 (48840) / (6 + lx*ly): aux = 0: d0 = a0 + fn gt16 (48840): gosub 850
508  &den(0,a0-8*(a0=m0),0,d0): map = 1: poke 216,0: gosub 860: goto 60

510 rem extended map format
511 if peek(a0+1)<>1 then print "map version is ";peek(a0+1);", expected 1": get a$: goto 60
512 lz = peek(a0+2): aux = peek(a0+3)*4: m0 = a0 + 8: lx = peek(m0): ly = peek(m0+1)
513 d0 = m0 + (6+lx*ly)*lz + aux: goto 508

600 rem check tiles, may pop stack
601 if tiles <> 1 then home: print "load tiles first": get a$: pop: goto 60
602 return

700 rem check map, may pop stack
701 if map <> 1 then home: print "init or load map first": get a$: pop: goto 60
702 return

800 rem arrays
810  dim pn$(9), vers(2): pn$(0) = "Load Tiles": pn$(1) = "New Map": pn$(2) = "Load Map": pn$(3) = "Save Map"
820  pn$(4) = "Edit": pn$(5) = "Auxiliary": pn$(6) = "Settings": pn$(7) = "Catalog": pn$(8) = "Exit": return

850 rem init extended header
851 for i = 0 to 7: poke a0-8+i,0: next: poke a0-7,1: poke a0-6,lz: return

860 rem reset level to 0
861 z = 0: l0 = m0
862 a1lo = l0: &mod(a1lo,256): a2hi = int(l0/256): return: rem set level pointer

870 rem increase level
871 if z + 1 = lz then return
872 z = z + 1: l0 = l0 + 6 + lx*ly: goto 862

880 rem decrease level
881 if z = 0 then return
882 z = z - 1: l0 = l0 - 6 - lx*ly: goto 862

890 rem setup workspace
891 a0 = 8 + fn gt16 (48825) + fn gt16 (48840): rem leave 8 bytes for conversion to extended format
892 m0 = a0: d0 = a0: lz = 0: aux = 0: poke a0-4,0: return: rem init size check inputs so we can always load tiles at start

895 rem check himem
896 hm = peek (115) + 256 * peek (116): if hm < 9*4096 then print "HIMEM TOO LOW": end
897 return

900 rem settings
910 home: print "view width": temp$ = str$(vwidth): gosub 950: vwidth = a: if vwidth<5 or vwidth>15 or vwidth/2 = int(vwidth/2) then 910
920 home: print "view height": temp$ = str$(vheight): gosub 950: vheight = a: if vheight<5 or vheight>11 or vheight/2 = int(vheight/2) then 920
930 home: print "avatar tile": temp$ = str$(avtar): gosub 950: avtar = a: if avtar<0 or avtar>47 then 930
940 &av #avtar: xhalf = int(vwidth/2): x00 = 16 - vwidth: yhalf = int(vheight/2): y00 = 12 - vheight: goto 60

950 rem edit number
951 print " ";temp$: call -868
952 vtab peek (37): htab 1: input a$: a = val(a$): return

1000 rem save map
1010 gosub 700: gosub 310: onerr goto 1049
1011 if m0 <> a0 then 1030
1012 if fndcount(0) > 0 then 1040
1020 rem simple format
1021 print d$;"bsave ";a$;",a";m0;",l";(6+lx*ly)*lz: poke 216,0: goto 60
1030 rem extended format
1031 poke a0+2,lz
1032 print d$;"bsave ";a$;",a";a0;",l";d0-a0+4*fndcount(0): poke 216,0: goto 60
1040 rem old format being extended
1041 poke a0-6,lz
1042 print d$;"bsave ";a$;",a";a0-8;",l";d0-a0+8+4*fndcount(0): poke 216,0: goto 60

1049 print "disk error": call -3288: get a$: poke 216,0: goto 60

1050  rem edit map
1060  gosub 600: gosub 700: gosub 9: x = lx/2: y = ly/2: gosub 860: pd = 0
1070  poke -16302,0: gosub 50: ds = 0: gosub 96: goto 70

1100 rem view aux records
1101 home: if lx=0 then print "no map": get a$: goto 60
1102 print "Auxiliary Records": print "---": j = 0: i=d0-aux
1103 if i >= d0 or j > 1 then 1110
1104 a = peek(i): if a=0 then j = j + 1: print: print "---"
1105 if a>0 then print chr$(a);: j = 0
1106 i = i + 1: goto 1103
1110 print: get a$: goto 60

1150 rem catalog
1160 home: print d$;"cat"
1170 input "enter prefix or bye: ";a$
1180 if a$="bye" or a$="BYE" then 60
1185 onerr goto 1199
1190 print d$;"prefix ";a$: poke 216,0: goto 1160
1199 print "disk error try again": call -3288: goto 1170

1200 rem quit
1210 home: vtab 21: print "confirm (Y/ESC) ": gosub 20: if a = asc("Y") then 1230
1220 if a = 27 then 60
1221 goto 1210
1230 print: print "restoring prefix...": print d$;"prefix";wd$
1240 if tiles then print "restoring bank switched memory..."
1250 if tiles then print d$;"bload d400.bank2.save": poke 232,0: poke 233,96: &bank
1260 if tiles then print "re-enabling IRQ...": call 782
1270 end

1300 rem setup machine code
1310 poke 768,160: poke 769,0: poke 770,32: poke 771,44: poke 772,254: poke 773,96: rem move memory
1320 poke 780,120: poke 781,96: rem disable interrupt
1330 poke 782,88: poke 783,96: rem enable interrupt
1399 return

9000 rem variable descriptions
9010 rem address types:
9020 rem   a0 = start of map data
9030 rem   m0 = start of first map level
9040 rem   l0 = start of current map level
9050 rem   d0 = start of denizen data
9060 rem To allow the program to auto-select simple or extended maps, the following device is used.
9061 rem   The start of the map data is always 8 bytes advanced from the start of free space.
9062 rem   If a0=m0, we have a simple map.  If denizens are added, they are referenced to the
9063 rem   address a0-8, and when the map is saved the header is simply inserted
9064 rem   and an extended map is saved.  If a0<>m0, we have an extended map, and denizens
9065 rem   are referenced to a0.  In this case the 8 byte gap is simply not used.
9070 rem aux = size of auxiliary data in bytes

9999 end: rem minifier L3 will choke without this (why?)