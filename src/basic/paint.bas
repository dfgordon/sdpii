1 gosub 892: lomem: 8*4096: if peek(-1088)=234 then text: home: print chr$(7);"65C02 REQUIRED": end
2  d$ = chr$(4): print d$;"bload dhrlib": poke 1013,76: poke 1014,0: poke 1015,64: gosub 890
3  print d$;"bload font1": print d$;"pr#3": poke 232,0: poke 233,96: &aux: poke 233,0
4  gosub 800: & vers: &pul > vers(0): &pul > vers(1): &pul > vers(2): gosub 50: gosub 8: goto 850

5  ds = 1: if peek(49249)>127 then ds = 10: rem move cursor
6  x = x - ds*(a=8) + ds*(a=21): y = y - ds*(a=11) + ds*(a=10): &mod(x,560): &mod(y,192): if pr=5 then gosub 17
7  return

8 text: home: print chr$(17);: return: rem 40 column text home
9 text: home: print chr$(18);: &dhr: poke -16302,0: return: rem DHR home

10 rem edit prompt
11 &tellp(addr,bit,cnt): &clear 1,24: if pr > 5 then pr = 1
12 on pr goto 13,14,15,16,17
13 w$ = "TAB=prompt, ESC=exit, SPC=stroke": goto 19
14 w$ = chr$(128)+chr$(132) + "=move,1=line,2=trap,3=tri,x=xor": goto 19
15 w$ = chr$(128)+"b=brush,c=color,d=dither,^x=cut,^z=pop": goto 19
16 w$ = "brush=" + str$(br) + ",len=" + str$(addr-a0) + "." + str$(8-bit) + ",cmd=" + str$(cnt): goto 19
17 &trap at 0,13,184 to 0,13,191: w$ = str$(x) + "," + str$(y) + "   ": &print w$ at 3,24: return 
19 &print w$ at 1,24: return

20 rem get upper
21 a = peek(49152): if a < 128 then 21
22 a = a - 128: if a > 96 then a = a - 32
23 a$ = chr$(a): poke 49168,0: return

30  rem menu subroutine
31 n = 0: m = 0: htab 1: vtab l: print "1) ";: inverse : print pn$(0): normal: if p > 0 then  for i = 1 to p: print i + 1;") ";pn$(i): next 
32  htab 1: vtab l + p + 2: print w$;: gosub 20: if a =  13 or a = b then  return 
33  if  a > 48 and  a <= 49 + p then m =  a - 49: return 
34  if a =  8 or a =  11 then n = m: m = m - 1: if m < 0 then m = p
35  if a =  10 or a =  21 then n = m: m = m + 1: if m > p then m = 0
36  htab 4: vtab n + l: print pn$(n): inverse: htab 4: vtab m + l: print pn$(m): normal: goto 32

40 rem main menu
41  gosub 8: ? "SDP II Painter "vers(0)"."vers(1)"."vers(2): l = 3: p = 5: vtab l+p+4
42  &tellp(addr,bit,cnt): ? "length=";addr-a0;".";8-bit: w$ = "Select- ": b = 13: gosub 30
43  on m + 1 goto 860,670,600,650,850,1200

50 rem path setup
51 print d$"prefix": input wd$: print d$"open sdpii.config": print d$"read sdpii.config": input a$: input art$: print d$"close sdpii.config": if art$="" then art$=wd$
53 print d$"prefix "art$: return

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
407 if a = 9 then n = n + 1: &mod(n,4)
409 goto 404

410 &rec: &trap at x(0),x(1),y(0) to x(2),x(3),y(3): &stop
411 x(0) = x(2): y(0) = y(2): x(1) = x(3): y(1) = y(3): y(2) = y(2) + 5: y(3) = y(3) + 5: n = 2: return

420 parity = n: &mod(parity,2): i = n - 2 * parity + 1: j = n - 4*int(n/2) + 2
421 if j>n and y(n)>y(j) then y(j) = y(n)
422 if j<n and y(n)<y(j) then y(j) = y(n)
423 if i>n and x(n)>x(i) then x(i) = x(n)
424 if i<n and x(n)<x(i) then x(i) = x(n)
425 y(i) = y(n): parity = j: &mod(parity,2): i = j - 2 * parity + 1: y(i) = y(j): return

430 &stroke #1 at x(n)-2,y(n)-1 
431 &hplot x(0),y(0) to x(1),y(1) to x(3),y(3) to x(2),y(2) to x(0),y(0): return

450 rem triangle mode
451 x(0) = x: y(0) = y: x(1) = x+10: y(1) = y+5: x(2) = x: y(2) = y+10: n = 0
452 &clear 1,24: pr=5: gosub 17: &print "Tri: " + chr$(128) + chr$(129) + chr$(132) + ", TAB, SPC" at 13,24
453 &mode=128: gosub 480: gosub 20: gosub 480: &mode=pm: gosub 80
454 if a = 32 then gosub 460: a = 9
455 if a = 27 then gosub 10: x = x(n): y = y(n): return
456 if a = 9 then n = n + 1: &mod(n,3)
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
520 &seekp(a0,cnt-1): &rec: &end: &stop: gosub 9: &seekg(a0,0): &draw at 0,0: gosub 880: gosub 10: return

540 rem get last cmd
541 if cnt<1 then lastCmd = 0: return
542 &seekg(a0,cnt-1): &scan: &draw 1 at 0,0: &stop: lastCmd = peek(249): &mod(lastCmd,8): return

550 rem pop vestigial cmd
551 &seekp(a0,cnt-1): return

600 rem save
610 home: input "save path: ";a$: &tellp(addr,bit,cnt): onerr goto 640
630 print: print d$;"bsave ";a$;",A";a0;",L";addr-a0+2: goto 40
640 print "disk error": call -3288: get a$: poke 216,0: goto 40

650 rem append
651 onerr goto 640
660 &tellp(addr,bit,cnt): home: input "load path: ";a$: print d$;"bload ";a$;",A";addr+1
661 &seekg(addr+1,0): &rec: &scan: &draw at 0,0: &end: &stop: goto 40

670 rem load
680 gosub 700: &seekp(a0,0): goto 650

700 rem confirm
701  if addr=a0 and bit=8 or a0=0 then return
702  home: print "Erase? ": gosub 20: if a$="Y" then return
703  pop: print: print "canceled. ";: gosub 20: goto 40

800 rem array setup
810 dim cl(4), x(3), y(3), pn$(9), cmd$(7), vers(2): restore: for i = 0 to 7: read cmd$(i): next: for i = 0 to 4: cl(i) = 15: next
820 pn$(0) = "Edit": pn$(1) = "Load Pic": pn$(2) = "Save Pic": pn$(3) = "Append Pic": pn$(4) = "Clear": pn$(5) = "Exit": return

850 rem new pic
851 gosub 700: x = 280: y = 80: ps = 0: pm = 0: br = 0: &seekg(a0,0): &seekp(a0,0): poke a0,0: addr = a0: bit = 8: cnt = 0: goto 40

860 rem edit
861 gosub 9: &seekg(a0,0): &draw at 0,0: gosub 880: gosub 10: pr = 1: goto 60

880 rem sync parameters
881 pm = peek(249): &and(pm,128): cl(1) = peek(28): &and(cl(1),15): cl(2) = int(peek(28)/16): cl(3) = peek(228): &and(cl(3),15): cl(4) = int(peek(228)/16)
882 &tellg(addr,bit,cnt): &seekp(a0,cnt): return

890 rem picture workspace
891 a0 = peek (48825) + 256 * peek (48826) + peek (48840) + 256 * peek(48841): addr = a0: bit = 8: return

892 rem check himem
893 hm = peek (115) + 256 * peek (116): if hm < 9*4096 then print "HIMEM TOO LOW": end
894 return

900 rem color picker
901 &clear 1,24: a$ = chr$(130) + chr$(131) + ", SPC": if ci > 0 then a$ = a$ + ", TAB"
902 &print a$ at 3+2*(ci>0),24
911 &mod(cl(0),16): if ci = 0 then 930
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
1110 &clear 1,24: &print chr$(128) + chr$(132) + ", SPC=start/end" at 1,24: m = -1: n = 0: x0 = 0: y0 = 0
1111 &rec: &end: &stop: &seekg(a0,0)
1120 gosub 1140: gosub 20: gosub 1140: ds = 1: if peek(49249)>127 then ds = 10
1121 if a = 8 and n-ds>=0 then n = n - ds: &seekg(a0,n): goto 1120
1122 if a = 21 then n = n + ds: &seekg(a0,n): &tellg(addr,bit,n): goto 1120
1123 if a$ = " " and m=-1 then m = n: a = 21: ds = 1: goto 1122
1124 if a$ = " " and m>=0 and n>m then 1150
1132 if a = 27 then 1180
1133 goto 1120

1140 &mode=128: &move to x0,y0: &draw 1 at 0,0: cmd = peek(249): &mod(cmd,8): if cmd <> 5 then x0 = peek(224) + peek(225)*256: y0 = peek(226): rem highlight part
1141 &seekg(a0,n): w$ = str$(m) + " " + str$(n) + " " + cmd$(cmd): &mode=cmd: &clear 28,24 to 32,24: &print w$ at 40-len(w$),24: return

1150 rem cut range m..n
1151 &seekg(a0,n): &seekp(a0,m): &rec: &scan: &draw at 0,0: &end: &stop
1180 gosub 9: &seekg(a0,0): &draw at 0,0: gosub 880: gosub 10: return: rem cleanup and return

1200 rem quit
1210 home: vtab 21: print "confirm (Y/N) ": get a$: if a$ = "Y" then 1230
1220 goto 40
1230 print: print "restoring prefix...": print d$;"prefix";wd$
1260 end

9990 data end,clr,mod,mov,plt,lin,trp,str

