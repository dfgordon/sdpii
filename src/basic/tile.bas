1 gosub 892: lomem: 8*4096: if peek(-1088)=234 then print chr$(7);"65C02 PROCESSOR REQUIRED": end
2  d$ = chr$(4): DEF  FN GT16(ADDR) =  PEEK (ADDR) + 256 *  PEEK (ADDR + 1)
3  print d$;"bload dhrlib": poke 1013,76: poke 1014,0: poke 1015,64: gosub 890
4  print d$;"bload font1": print d$;"pr#3": poke 232,0: poke 233,96: &aux: poke 233,0
6 lx = 1: ly = 1: dx = 8: dy = 6: yg = 2+16*ly: poke a0,lx: poke a0+1,ly: gosub 800
7 poke 232,a1lo: poke 233,a2hi: tilNum = 0: tSize = 16*lx*ly: & vers: &pul > vers(0): &pul > vers(1): &pul > vers(2): gosub 50: gosub 8: goto 60

8 text: home: print chr$(17): return: rem 40 column text home
9 text: home: print chr$(18): &dhr: poke -16302,0: return: rem DHR home

10 rem coords
11 w$ = "   " + str$(x) + "," + str$(y): poke 233,0: &mode=0: &print w$ at 41-len(w$),1
12 &print "pen=" + str$(pd) at 36,2: i = fre(0)
13 poke 233,a2hi: &mode=128: return

15 poke 233,0: &mode=0: &clear 1,24: &mode=128: &print w$ at 1,24: poke 233,a2hi: return: rem progress message
16 poke 233,0: &mode=0: &clear 1,24: goto 13: rem finish progress and return

20 rem get upper
21 a = peek(49152): if a < 128 then 21
22 a = a - 128: a = a - 32 * (a > 96): poke 49168,0: return

30  rem menu subroutine
31 n = 0: m = 0: htab 1: vtab l: print "1) ";: inverse : print pn$(0): normal: if p > 0 then  for i = 1 to p: print i + 1;") ";pn$(i): next 
32  htab 1: vtab l + p + 2: print w$;: gosub 20: if a =  13 or a = b then  return 
33  if  a > 48 and  a <= 49 + p then m =  a - 49: return 
34  if a =  8 or a =  11 then n = m: m = m - 1: if m < 0 then m = p
35  if a =  10 or a =  21 then n = m: m = m + 1: if m > p then m = 0
36  htab 4: vtab n + l: print pn$(n): inverse: htab 4: vtab m + l: print pn$(m): normal: goto 32

40 rem edit prompt
41 poke 233,0: &mode=0: &clear 1,21 to 40,24
42 &print "SPC=toggle pixel, TAB=toggle pen" at 1,21
43 &print chr$(128) + chr$(132) + "=move, ESC=menu" at 1,22
44 &print "p=preview, d=dither" at 1,23: goto 10

50 rem path setup
51 print d$;"prefix": input wd$: print d$;"open sdpii.config": print d$;"read sdpii.config"
52 input a$: input a$: input a$: input tile$: print d$;"close sdpii.config": if tile$="" then tile$=wd$
53 print d$;"prefix ";tile$: return

60  gosub 8: m = fre(0): ? "SDP II Tiler "vers(0)"."vers(1)"."vers(2): vtab 13: print "tiles=";tilNum;" bytes=";2+tilNum*tSize: l = 3: p = 7: w$ = "Select- ": b = 13
61 pn$(0) = "New Set": pn$(1) = "Load Set": pn$(2) = "Append Set": pn$(3) = "Save Set": pn$(4) = "Edit": pn$(5) = "View": pn$(6) = "Catalog": pn$(7) = "Exit": gosub 30
62  on m + 1 goto 400,550,560,600,1050,1100,1150,1200

70 rem edit loop
71  gosub 110: gosub 20: gosub 110: gosub 90
72  if a = asc("P") then gosub 200: goto 70
73  if a = 32 then gosub 110: goto 70
74  if a = 27 then  gosub 130: home: vtab 21 : goto 60
75  if a = asc("D") then gosub 210: goto 70
76  if a = 9 then pd = pd = 0: gosub 10
77  goto 70

90 rem move cursor
91  ds = 1 + (peek(49249)>127)*7: if pd then gosub 110
92  if a = 8 then x = x - ds: &mod(x,lx*14)
93  if a = 11 then y = y - ds: &mod(y,ly*8)
94  if a = 21 then x = x + ds: &mod(x,lx*14)
95  if a = 10 then y = y + ds: &mod(y,ly*8)
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
142 for j=0 to ly*8-1: a = 4: for i=0 to lx*2-1: for bit=0 to 6: st = peek(addr): &bit (st,bit): &mode = 128 + 32 * not st: &stroke #1 at a,b: a = a + dx: next: addr = addr + 1: next: b = b + dy: next: goto 16

150 rem swap
151 i = 0: j = 1: &clear 1,24: &print "swap partner 1" at 1,24
152 poke 233,a2hi: &tile #i at 1,21: gosub 20: i = i + (a=21) - (a=8): &mod(i,tilNum)
153 if a = 32 then poke 233,0: &print "2" at 14,24: goto 160
154 if a = 27 then return
155 goto 152
160 poke 233,a2hi: &tile #j at 1,21: gosub 20: j = j + (a=21) - (a=8): &mod(j,tilNum)
161 if a = 32 then 169
162 if a = 27 then return
163 goto 160
169 a = a0 + 2 + i*tSize: b = a0 + 2 + j*tSize: for n = 0 to tSize-1: m = peek(a+n): poke a+n,peek(b+n): poke b+n,m: next: return

200 rem preview
201 gosub 130: &mode=0: for i = 0 to 1: for j = 0 to 1: &tile #id at 21+i*lx,1+j*ly: next: next
202 &mode=128: return

210 rem dither
211 ci = 1: &mode=0: gosub 900: &hcolor=cl(1),cl(2),cl(3),cl(4): &clear 1,1 to 40,24: &trap at 0,lx*14-1,0 to 0,lx*14-1,ly*8-1
212 &hcolor=15: gosub 120: gosub 140: gosub 40: return

400  rem init tile set
410  gosub 450: home: input "tile columns (14 pix each): ";lx: IF lx < 1 OR lx>8 THEN 410
420  input "tile rows (8 pix each): ";ly: if ly<1 or ly>4 then 420
430  poke a0,lx: poke a0+1,ly: tilNum = 0: tSize = lx*ly*16: yg = 2+16*ly: goto 60

450 rem confirm erase, if no pop and goto main
451 if tilNum = 0 then return
452 home: print "erase ";tilNum;" tiles (Y/N) ": gosub 20
453 if a = ASC("Y") then return
454 pop: print "aborting": get a$: goto 60

460 rem confirm tiles, if none pop and goto main
461 if tilNum > 0 then return
462 home: print "no tiles ";: get a$: pop: goto 60

500 rem edit path
510 print: print d$;"prefix";tile$
520 home: print "prefix: ";tile$: input "path: ";a$: return

550  rem load tile set
551 gosub 450: gosub 500: onerr goto 640
553 print d$;"bload ";a$;",a";a0: poke 216,0: lx = peek(a0): ly = peek(a0+1): tSize = lx*ly*16: tilNum = (fn gt16(48840)-2)/tSize: goto 60

560  rem append tile set
561 if tilNum = 0 then home: print "nothing to append to": get a$: goto 60
562 addr = a0 + tilNum*tSize: b1 = peek(addr): b2 = peek(addr+1)
563 gosub 500: onerr goto 640
564 print d$;"bload ";a$;",a";addr: poke 216,0: lx = peek(addr): ly = peek(addr+1): poke addr,b1: poke addr+1,b2
565 if lx <> peek(a0) or ly <> peek(a0+1) then print "incompatible size": get a$: goto 60
566 tilNum = tilNum + (fn gt16(48840)-2)/tSize: goto 60

600 rem save tile set
610 gosub 460: gosub 500
620 onerr goto 640
630 print d$;"bsave ";a$;",a";a0;",l";2+tilNum*tSize: poke 216,0: goto 60
640 print "disk error": call -3288: get a$: poke 216,0: goto 60

800 rem arrays
810 dim pn$(9): dim cl(4): dim vers(2): for i = 0 to 4: cl(i) = 15: next
820 return

890 rem tile workspace
891 a0 = fn gt16(48825) + fn gt16(48840): a1lo = a0: &mod(a1lo,256): a2hi = int(a0/256): return

892 rem check himem
893 hm = peek (115) + 256 * peek (116): if hm < 9*4096 then print "HIMEM TOO LOW": end
894 return

900 rem color picker
901 &clear 1,24: a$ = chr$(130) + chr$(131) + ", SPC": if ci > 0 then a$ = a$ + ", TAB"
902 poke 233,0: &print a$ at 3+2*(ci>0),24: poke 233,a2hi
911 &mod(cl(0),16): if ci = 0 then 930
914 if ci>4 then ci = 1
920 cl(ci) = cl(0): &hcolor=cl(1),cl(2),cl(3),cl(4): &trap at 28,43,184 to 28,43,191
930 &hcolor=cl(ci): &trap at 0,15,184 to 0,15,191: gosub 20: if a = 32 then return
940 if a = 8 then cl(0) = cl(0) - 1: goto 911
950 if a = 21 then cl(0) = cl(0) + 1: goto 911
951 if ci>0 and a = 9 then ci = ci + 1
960 goto 911

1050  rem edit tile
1051  home: input "tile id: ";id: if id>tilNum then print "next tile is ";tilNum: get a$: goto 60
1053  gosub 9: x = 0: y = 0: if id=tilNum then tilNum = tilNum + 1: goto 1070
1060  &tile #id at 1,1
1070  gosub 40: &mode=0: &hcolor=15: gosub 120: &mode=128: gosub 140: goto 70

1100  rem overview
1101  gosub 460: gosub 9: x = 1: y = 1: for i = 1 to tilNum
1102  poke 233,a2hi: &tile #i-1 at x,y: poke 233,0: &print str$(i-1) at x,y+ly: x = x + lx
1103  if x>40 then x = 1: y = y + ly*2
1104  next
1110  &mode=0: poke 233,0: &print "ESC=exit, SPC=swap" at 1,24: gosub 20
1111  if a = 27 then poke 233,a2hi: goto 60
1112  if a = 32 then gosub 150: goto 1100
1113  goto 1110

1150 rem catalog
1160 home: print d$;"cat"
1170 input "enter prefix or bye: ";a$
1180 if a$="bye" or a$="BYE" then 60
1185 onerr goto 1199
1190 print d$;"prefix ";a$: poke 216,0: goto 1160
1199 print "disk error try again": call -3288: goto 1170

1200 rem quit
1210 home: vtab 21: print "confirm (Y/N) ": get a$: if a$ = "Y" then 1230
1220 goto 60
1230 print: print "restoring prefix...": print d$;"prefix";wd$
1240 end
