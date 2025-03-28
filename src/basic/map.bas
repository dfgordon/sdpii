1 gosub 892: lomem: 35584: if peek(-1088)=234 then text: home: print chr$(7);"65C02 PROCESSOR REQUIRED": end
2  d$ = chr$(4): def  fn gt16(addr) =  peek (addr) + 256 *  peek (addr + 1)
3  print d$;"bload maplib": poke 1013,76: poke 1014,0: poke 1015,64: gosub 890
4  print d$;"bload font1": print d$;"pr#3": poke 232,0: poke 233,96: &aux: poke 233,0
5 vwidth = 15: vheight = 11: gosub 800: gosub 1300
6 &vers: &pul > vers(0): &pul > vers(1): &pul > vers(2): gosub 50: gosub 8: goto 70

8 text: home: print chr$(17);: return: rem 40 column text home
9 text: home: print chr$(18);: &dhr: poke -16302,0: return: rem DHR home

10 rem tile selection
11 pd = pd + 1: &mod(pd,tcount): &tile #pd at 39,21: return

18 rem indefinite progress
19 &clear 1,23 to 40,24: &mode = 128: &print "Working..." at 1,23: &mode = 0: return

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

50 rem path setup
51 print d$;"prefix": input wd$: print d$;"open sdpii.config": print d$;"read sdpii.config"
52 input a$: input a$: input map$: input tile$: print d$;"close sdpii.config"
53 if map$="" then map$=wd$
54 if tile$="" then tile$=wd$
55 return

60 rem edit prompt
61 &clear 1,23 to 40,24
62 &print chr$(128) + chr$(129) + "SPC=place, `=prev, TAB=next" at 1,23
63 &print chr$(128) + chr$(129) + chr$(132) + "=move, B=bound, ESC=menu" at 1,24
64 rem coords
65 w$ = "  " + str$(x) + "," + str$(y): &tile #pd at 39,21: &print w$ at 41-len(w$),24: i = fre(0): return

70  gosub 8: m = fre(0): print "SDP II Mapper "vers(0)"."vers(1)"."vers(2): l = 3: p = 7: vtab l+p+4: print "size=";lx;",";ly: print "tiles=";tcount
71 w$ = "Select- ": b = 13: gosub 30
72  on m + 1 goto 450,400,500,1000,1050,900,1150,1200

80 rem edit loop
81  gosub 20: dx = (a = 21 or a = 51 or a = 54 or  a = 57) - (a = 8 or a = 49 or a = 52 or a = 55): dy = (a = 10 or a >= 49 and a <= 51) - (a = 11 or a >= 55 and a <= 57)
82  if dx <> 0 or dy <> 0 then gosub 90: goto 80
83  if a = 32 then gosub 100: goto 80
84  if a = 27 then  gosub 130: home: vtab 21 : goto 70
85  if a = 9 then gosub 10: goto 80
86  if a = 96 then pd = pd - 2: gosub 10: goto 80
87  if a = asc("B") then gosub 200: goto 80
89  goto 80

90 rem scroll map
91  ds = 1 + (peek(49249)>127)*3: p = a0 + 6 + x + y*lx: if peek (49250)>127 then poke p,pd
92  x = x + dx*ds: y = y + dy*ds: &mod(x,lx): &mod(y,ly)
96  poke 0,a1lo: poke 1,a2hi
99  &map at x-int(vwidth/2),y-int(vheight/2) to x+int(vwidth/2),y+int(vheight/2) at 1,1: gosub 64: return

100 rem place tile(s)
101 if peek(49249)>127 then 104
102 if peek(49250)>127 then 105
103 poke a0 + 6 + x + y*lx,pd: return
104 gosub 18: gosub 110: for i = x-2 to x+2: for j = y-1 to y+1: poke a0 + 6 + i + j*lx,pd: next: next: gosub 60: goto 96
105 gosub 18: gosub 112: for i = x-4 to x+4: for j = y-3 to y+3: poke a0 + 6 + i + j*lx,pd: next: next: gosub 60: goto 96
110 if x < 2 or x > lx-3 or y < 1 or y > ly-2 then 120
111 return
112 if x < 4 or x > lx-5 or y < 3 or y > ly-4 then 120
113 return
120 &print "out of range error" at 1,23: get a$: gosub 60: pop: return

130 rem close to menu
140 return

200 rem set boundary tiles
210 &clear 1,23: &clear 1,24: &print "type N, S, E, or W" at 1,23: gosub 20
220 if a = asc("N") then poke a0 + 2, pd
221 if a = asc("S") then poke a0 + 3, pd
222 if a = asc("E") then poke a0 + 4, pd
223 if a = asc("W") then poke a0 + 5, pd
230 gosub 60: goto 96

300 a$ = tile$: goto 320: rem enter tile path
310 a$ = map$: rem enter map path
320 home: print d$;"prefix ";a$: print "prefix: ";a$: input "path: ";a$: return

400 rem init map
410  gosub 600: home: input "map columns: ";lx: if lx<16 or lx>128 then 410
420  input "map rows: ";ly: if ly<16 or ly>128 then home: goto 420
421  input "starting tile: ";a: if a<0 or a>47 then home: goto 421
422  poke a0,lx: poke a0+1,ly: poke a0+2,0: poke a0+3,0: poke a0+4,0: poke a0+5,0: x = a0 + 6: y = x + lx*ly - 1
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
451  home: if a0 + 6 + lx*ly >= 24576 then print "save and restart program first": get a$: goto 70
460  gosub 300: onerr goto 1049
462  print d$;"bload ";a$;",a$6000": if peek(24576) <> 2 or peek(24577) <> 2 then print "incompatible tiles": get a$: poke 216,0: goto 70
470  poke 233,96: &bank: poke 233,0: tcount = (fn gt16 (48840) - 2) / 64
471  print "tiles stashed in bank 2 at $D400"
472  print "saving displaced memory..."
473  print d$;"bsave ";wd$;"d400.bank2.save,a$6002,l$c00"
474  tiles = 1: poke 216,0: goto 70

500 rem load map
501  gosub 600: gosub 310: onerr goto 1049
503  print d$;"bload ";a$;",a";a0: lx = peek(a0): ly = peek(a0+1)
508  map = 1: poke 216,0: goto 70

600 rem check tiles, may pop stack
601 if tiles <> 1 then home: print "load tiles first": get a$: pop: goto 70
602 return

700 rem check map, may pop stack
701 if map <> 1 then home: print "init or load map first": get a$: pop: goto 70
702 return

800 rem arrays
810  dim pn$(9), vers(2): pn$(0) = "Load Tiles": pn$(1) = "New Map": pn$(2) = "Load Map": pn$(3) = "Save Map"
820  pn$(4) = "Edit": pn$(5) = "Settings": pn$(6) = "Catalog": pn$(7) = "Exit": return

890 rem map workspace
891 a0 = fn gt16 (48825) + fn gt16 (48840): a1lo = a0: &mod(a1lo,256): a2hi = int(a0/256): return

892 rem check himem
893 hm = peek (115) + 256 * peek (116): if hm < 9*4096 then print "HIMEM TOO LOW": end
894 return

900 rem settings
910 home: input "view width ";vwidth: if vwidth<5 or vwidth>15 or vwidth/2 = int(vwidth/2) then 910
920 home: input "view height ";vheight: if vheight<5 or vheight>11 or vheight/2 = int(vheight/2) then 920
930 home: input "avatar tile ";avtar: if avtar<0 or avtar>47 then 930
940 &av #avtar: goto 70

1000 rem save map
1010 gosub 700: gosub 310: onerr goto 1049
1020 print d$;"bsave ";a$;",a";a0;",l";lx*ly+6: poke 216,0: goto 70
1049 print "disk error": call -3288: get a$: poke 216,0: goto 70

1050  rem edit map
1060  gosub 600: gosub 700: gosub 9: x = lx/2: y = ly/2: pd = 0
1070  poke -16302,0: gosub 60: ds = 0: gosub 96: goto 80

1150 rem catalog
1160 home: print d$;"cat"
1170 input "enter prefix or bye: ";a$
1180 if a$="bye" or a$="BYE" then 70
1185 onerr goto 1199
1190 print d$;"prefix ";a$: poke 216,0: goto 1160
1199 print "disk error try again": call -3288: goto 1170

1200 rem quit
1210 home: vtab 21: print "confirm (Y/N) ": get a$: if a$ = "Y" then 1230
1220 goto 70
1230 print: print "restoring prefix...": print d$;"prefix";wd$
1240 if tiles then print "restoring bank switched memory..."
1250 if tiles then print d$;"bload d400.bank2.save": poke 232,0: poke 233,96: &bank
1260 end

1300 rem setup move memory call
1310 poke 768,160: poke 769,0: poke 770,32: poke 771,44: poke 772,254: poke 773,96: return
