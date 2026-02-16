1 gosub 892: lomem: 8*4096: lm = 8*4096: if peek(-1088)=234 then print chr$(7);"65C02 PROCESSOR REQUIRED": end
2  d$ = chr$(4): DEF  FN GT16(ADDR) =  PEEK (ADDR) + 256 *  PEEK (ADDR + 1)
3  print d$;"bload dhrlib": poke 1013,76: poke 1014,0: poke 1015,64: gosub 890
4  print d$;"bload font1": poke 232,0: poke 233,96: &aux: poke 233,0
6 lx = 1: ly = 1: dx = 8: dy = 6: yg = 2+16*ly: poke a0,lx: poke a0+1,ly: gosub 800: gosub 1300
7 poke 232,a1lo: poke 233,a2hi: tilNum = 0: tSize = 16*lx*ly: & vers: &pul > vers(0): &pul > vers(1): &pul > vers(2): gosub 50: gosub 8: goto 60

8 text: home: print d$;"pr#3": print chr$(17): return: rem 40 column text home
9 home: print chr$(18): &dhr: poke -16302,0: &pr#: return: rem DHR home

10 rem coords
11 w$ = "   " + str$(x) + "," + str$(y): poke 233,0: htab 41-len(w$): vtab 1: print w$
12 i = fre(0)
13 poke 233,a2hi: return

15 poke 233,0: &clear 1,24: inverse: vtab 24: print w$: poke 233,a2hi: normal: return: rem progress message
16 poke 233,0: &clear 1,24: goto 13: rem finish progress and return

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
41 if pr > 2 then pr = 1
42 htab 1: vtab 24: poke 233,0: &clear 1,24: on pr goto 43,44
43 print "TAB=prompt, ESC=exit, SPC=toggle": return
44 print chr$(5)chr$(6)chr$(9)"=move,p=preview,d=dither": return

50 rem path setup
51 print d$;"prefix": input wd$: print d$;"open sdpii.config": print d$;"read sdpii.config"
52 input a$: input a$: input a$: input tile$: print d$;"close sdpii.config": if tile$="" then tile$=wd$
53 print d$;"prefix ";tile$: return

60 rem main menu
61  gosub 8: m = fre(0): ? "SDP II Tiler "vers(0)"."vers(1)"."vers(2): frspc = lm - a0 - 2 - tilNum*tSize: if buf%(1) then frspc = frspc - siz%(1)
62  l = 3: p = 7: vtab l+p+4: ? "tiles=";tilNum;" bytes=";2+tilNum*tSize;" free=";frspc
63  w$ = "Select- ": b = 13: gosub 30
64  on m + 1 goto 500,550,560,600,1000,1100,1150,1200

70 rem edit loop
71  gosub 110: gosub 20: if a = 32 then 70
72  gosub 90: &mode=128: permanent = 0
73  if a = asc("P") then gosub 200: goto 70
74  if a = 27 then poke 233,0: gosub 430: goto 78
75  if a = asc("D") then gosub 210: goto 70
76  if a = 9 then pr = pr + 1: gosub 40
77  goto 70
78  if a = asc("Y") then permanent = 1: gosub 130
79  poke 233,a2hi: goto 60

80 rem select tile >= i0
81 id = i0: poke 233,0
82 gosub 1130: htab i: vtab j: print "^": gosub 20: &clear i,j to i+1,j: gosub 100
83 if (a = 13 or a = 32) and id >= i0 then j0 = id: return
84 if a = 13 or a = 32 then &clear 1,24: vtab 24: print "must be after": id = i0
86 goto 82

90 rem move cursor
91  ds = 1 + (peek(49249)>127)*7: if peek(49250)<128 then gosub 110
92  if a = 8 then x = x - ds: &mod(x,lx*14)
93  if a = 11 then y = y - ds: &mod(y,ly*8)
94  if a = 21 then x = x + ds: &mod(x,lx*14)
95  if a = 10 then y = y + ds: &mod(y,ly*8)
99  gosub 10: return

100 rem move cursor in arranger
101  if a = 8 then id = id - 1
102  if a = 11 then id = id - int(40/lx)
103  if a = 21 then id = id + 1
104  if a = 10 then id = id + int(40/lx)
105  &mod(id,tilNum): return

110  rem stroke
111  &stroke #1 at x*dx+4,yg+y*dy+2: &hplot x,y: return

120 rem draw grid
121 &hcolor = 1,0,1,0
122 for j = 0 to ly*8: &hplot 0,yg+j*dy to lx*14*dx,yg+j*dy: next
123 return

130 rem scan tile, permanent=1 means permanent change
131 &mode=128: w$ = "SCANNING...": gosub 15: d2dec = a0 + 2 + (id+1)*tSize - 1: d1dec = d2dec - tSize/2: for j=0 to ly*8-1: for i=0 to lx-1: &move to i*14,j: addr = peek(38) + peek(39)*256
132 poke 49237,0: b1 = peek(addr+i): poke 49236,0: b2 = peek(addr+i)
133 &zoom(b1,4+14*dx*i,2+yg+dy*j): &zoom(b2,4+14*dx*i+7*dx,2+yg+dy*j)
134 if permanent > 0 then poke d1dec,b1: poke d2dec,b2: d1dec = d1dec - 1: d2dec = d2dec - 1
135 next: next: goto 16

140 rem insert
141 if buf%(1) = 0 then &clear 1,24: vtab 24: print "clipboard empty": gosub 20: return
142 i0 = id
143 buf%(0) = a0 + 2 + i0*tSize: siz%(0) = (tilNum-i0)*tSize:   buf%(2) = buf%(1) - siz%(0): siz%(2) = siz%(0): i = 0: j = 2: gosub 180
144 siz%(0) = siz%(1): i = 1: j = 0: gosub 180
145 buf%(0) = buf%(0) + siz%(0): siz%(0) = siz%(2): i = 2: j = 0: gosub 180
146 tilNum = tilNum + siz%(1)/tSize: return

150 rem cut range
151 gosub 440: if a = 27 then return
152 i0 = id: &clear 1,24: vtab 24: print "select last": gosub 80
155 buf%(0) = a0 + 2 + i0*tSize: siz%(0) = (j0-i0+1)*tSize:   buf%(1) = lm - siz%(0): siz%(1) = siz%(0): i = 0: j = 1: gosub 180
156 buf%(2) = buf%(0): siz%(2) = (tilNum - i0)*tSize:   buf%(0) = buf%(0) + siz%(0): siz%(0) = siz%(2): i = 0: j = 2: gosub 180
157 tilNum = tilNum + i0 - j0 - 1: return

180 rem copy buf(i) to buf(j), overlap OK if downward
181 poke 60,buf%(i) - 256*int(buf%(i)/256): poke 61,int(buf%(i)/256): last = buf%(i) + siz%(i) - 1
182 poke 62,last - 256*int(last/256): poke 63,int(last/256): poke 66,buf%(j) - 256*int(buf%(j)/256): poke 67,int(buf%(j)/256) 
183 call 768: return

200 rem preview
201 poke 233,0: &clear 1,24: vtab 24: print "scan cannot be undone, proceed (Y/ESC)": gosub 20: if a <> 27 and a <> asc("Y") then 201
202 poke 233,a2hi: if a <> asc("Y") then gosub 40: return
203 permanent = 1: gosub 130: &mode=0: for i = 0 to 1: for j = 0 to 1: &tile #id at 41+i*lx-2*lx,4+j*ly: next: next
204 permanent = 0: gosub 130: gosub 40: return

210 rem dither
211 ci = 1: &mode=0: gosub 900: if a = 27 then 214
212 &hcolor=cl(1),cl(2),cl(3),cl(4): &clear 1,1 to 40,24: &trap at 0,lx*14-1,0 to 0,lx*14-1,ly*8-1
213 &hcolor=15: gosub 120: gosub 130
214 gosub 40: return

430 rem confirm scan changes, result in a
431 &clear 1,24: vtab 24: print "keep changes (Y/N)": gosub 20: if a <> asc("Y") and a <> asc("N") then 431
432 if a = asc("N") and nwtile = 1 then tilNum = tilNum - 1 
433 return

440 rem confirm dispose clipboard, result in a
441 if buf%(1) <> 0 then &clear 1,24: vtab 24: print "drop current clipboard (Y/ESC)": gosub 20: if a = asc("Y") or a = 27 then return
442 if buf%(1) <> 0 then 441
443 a = asc("Y"): return

450 rem confirm erase, if no pop and goto main
451 if tilNum = 0 then return
452 home: print "erase ";tilNum;" tiles (Y/ESC) ": gosub 20
453 if a = asc("Y") then return
454 if a = 27 then pop: goto 60
455 goto 452

460 rem confirm tiles, if none pop and goto main
461 if tilNum > 0 then return
462 home: print "no tiles ";: get a$: pop: goto 60

470 rem edit path
471 print: print d$;"prefix";tile$
472 home: print "prefix: ";tile$: input "path: ";a$: return

500  rem init tile set
510  gosub 450
511  home: input "tile columns (14 pix each): ";lx: if lx < 1 or lx > 4 then 511
520  home: input "tile rows (8 pix each): ";ly: if ly < 1 or ly > 3 then 511
530  poke a0,lx: poke a0+1,ly: tilNum = 0: tSize = lx*ly*16: yg = 2+8*ly: goto 60

550  rem load tile set
551 gosub 450: gosub 470: onerr goto 640
553 print d$;"bload ";a$;",a";a0: poke 216,0: lx = peek(a0): ly = peek(a0+1): tSize = lx*ly*16: tilNum = (fn gt16(48840)-2)/tSize: yg = 2+8*ly: goto 60

560  rem append tile set
561 if tilNum = 0 then home: print "nothing to append to": get a$: goto 60
562 addr = a0 + tilNum*tSize: b1 = peek(addr): b2 = peek(addr+1)
563 gosub 470: onerr goto 640
564 print d$;"bload ";a$;",a";addr: poke 216,0: lx = peek(addr): ly = peek(addr+1): poke addr,b1: poke addr+1,b2
565 if lx <> peek(a0) or ly <> peek(a0+1) then lx = peek(a0): ly = peek(a0+1): print "incompatible size": get a$: goto 60
566 tilNum = tilNum + (fn gt16(48840)-2)/tSize: goto 60

600 rem save tile set
610 gosub 460: gosub 470
620 onerr goto 640
630 print d$;"bsave ";a$;",a";a0;",l";2+tilNum*tSize: poke 216,0: goto 60
640 print "disk error": call -3288: get a$: poke 216,0: goto 60

800 rem arrays
810 dim pn$(9), cl(4), vers(2), buf%(2), siz%(2): for i = 0 to 4: cl(i) = 15: next
815 pn$(0) = "New Set": pn$(1) = "Load Set": pn$(2) = "Append Set": pn$(3) = "Save Set": pn$(4) = "Add": pn$(5) = "Modify": pn$(6) = "Catalog": pn$(7) = "Exit"
820 for i = 0 to 2: buf%(i) = 0: next: return

890 rem tile workspace
891 a0 = fn gt16(48825) + fn gt16(48840): &psh16 < a0: &pul > a1lo: &pul > a2hi: return

892 rem check himem
893 hm = peek (115) + 256 * peek (116): if hm < 9*4096 then print "HIMEM TOO LOW": end
894 return

900 rem color picker
901 &clear 1,24: poke 233,0: htab 3+2*(ci>0): vtab 24
902 print "ESC, "chr$(7)chr$(8)", SPC";: if ci > 0 then print ", TAB"
903 poke 233,a2hi
911 &mod(cl(0),16): if ci = 0 then 930
914 if ci>4 then ci = 1
920 cl(ci) = cl(0): &hcolor=cl(1),cl(2),cl(3),cl(4): &trap at 28,43,184 to 28,43,191
930 &hcolor=cl(ci): &trap at 0,15,184 to 0,15,191: gosub 20: if a = 32 or a = 27 then return
940 if a = 8 then cl(0) = cl(0) - 1: goto 911
950 if a = 21 then cl(0) = cl(0) + 1: goto 911
951 if ci>0 and a = 9 then ci = ci + 1
960 goto 911

1000 rem add tile
1001 id = tilNum: gosub 9: tilNum = tilNum + 1: nwtile = 1: goto 1053
1050  rem edit tile
1052  gosub 9: &tile #id at 1,1: nwtile = 0
1053  x = 0: y = 0: &mode=0: &hcolor=15: gosub 120: gosub 130: pr = 1: gosub 40: goto 70

1100  rem modify tile(s)
1101  gosub 460: gosub 9: id = 0: x = 1: y = 1: for i = 1 to tilNum
1102  poke 233,a2hi: &tile #i-1 at x,y: x = x + lx
1103  if x + lx > 41 then x = 1: y = y + ly + 1
1104  next
1110  &mode=0: poke 233,0: &clear 1,24: vtab 24: print chr$(9)" ESC=exit RET=edit ^X=cut ^V=insert"
1111  gosub 1130: htab i: vtab j: print "^": gosub 20: gosub 100: &clear i,j to i+1,j
1112  if a = 27 then poke 233,a2hi: goto 60
1113  if a = 24 then gosub 150: goto 1100
1114  if a = 22 then gosub 140: goto 1100
1115  if a = 13 then poke 233,a2hi: goto 1050
1116  goto 1111

1130 rem set i,j based on id
1131 tmp = lx*int(40/lx)
1132 i = 1 + id*lx: &mod(i,tmp): j = 1 + ly+(ly+1)*int(id*lx/tmp): return

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
1240 end

1300 rem setup move memory call
1310 poke 768,160: poke 769,0: poke 770,32: poke 771,44: poke 772,254: poke 773,96: return
