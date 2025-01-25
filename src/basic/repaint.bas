1 himem: 9*4096: lomem: 8*4096: if peek(-1088)=234 then text: home: print chr$(7);"65C02 REQUIRED": end
2  print chr$(4);"bload dhrlib": gosub 890: poke 1013,76: poke 1014,0: poke 1015,64
3  print chr$(4);"bload font1": print chr$(4);"pr#3": poke 232,0: poke 233,96: &aux: poke 233,0
4  gosub 800: & vers: &pul > vers(0): &pul > vers(1): &pul > vers(2): goto 850

5 rem move cursor
6  ds = 1: if peek(49249)>127 then ds = 8
7  x = x - ds*(a=8) + ds*(a=21): y = y - ds*(a=11) + ds*(a=10): &mod(x,560): &mod(y,192)
8  return

10 rem edit prompt
11 &tellp(addr,bit,cnt): &clear 1,24: if pr > 3 then pr = 1
12 on pr goto 13,14,17
13 w$ = "TAB=prompt, ESC=exit, SPC=select": goto 19
14 w$ = "1=recolor,2=move": goto 19
17 w$ = "selection: " + str$(m1) + " to " + str$(m2) + "   " 
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

40  text: home: ? "SDP II Repainter "vers(0)"."vers(1)"."vers(2): vtab 13: &tellp(addr,bit,cnt): ? "length=";addr-a0;".";8-bit: l = 3: p = 3: w$ = "Select- ": b = 13
41 pn$(0) = "Load Pic":pn$(1) = "Save Pic":pn$(2) = "Edit": pn$(3) = "Exit": gosub 30
42  on m + 1 goto 670,600,860,870

60 rem edit loop
61  gosub 20
64  if a$ = "1" then gosub 200: goto 60
65  if a$ = "2" then gosub 300: goto 60
67  if a$ = " " then gosub 1100: goto 60
72  if a = 9 then pr = pr + 1: gosub 10: goto 60
73  if a = 27 then 40
74  goto 60

200 rem color
201 rem user selects color command which is then replaced
202 &seekg(a0,0): x = 0: &psh < 0: &psh < 0
203 &scan: &draw 1 at 0,0: &stop: cmd = peek(249): &mod(cmd,8): if cmd = 1 then 206
204 if cmd = 0 then 202
205 x = x + 1: goto 203
206 &clear 1,24: &trap at 0,13,184 to 0,13,191: &print chr$(130) + chr$(131) + ", SPC " + str$(x) at 2,24: gosub 20: if a=32 then 211
207 if a=21 then xlow = x: &mod(xlow,256): &psh < xlow: &psh < int(x/256): goto 205
208 if a=27 then 1180
209 if a=8 then &pul > x: &pul > y: x = x*256 + y: &seekg(a0,x): goto 203
210 goto 206
211 ci = 1: gosub 900: &seekp(a0,x): &rec: &scan: &hcolor=cl(1),cl(2),cl(3),cl(4): &seekg(a0,x+1): &draw 1 at 0,0: &stop: goto 1180

300 rem move
301 &clear 1,24: &print "Move: " + chr$(128) + chr$(132) + ", SPC" at 1,24
302 x0 = mx: y0 = my: x = x0 + 8: y = y0
303 &mode=128: &hplot x0,y0 to x,y: gosub 20: &hplot x0,y0 to x,y: &mode=0: gosub 5
304 if a = 27 then 1180
305 if a <> 32 then 303
306 &seekg(a0,m1): &seekp(a0,m1): &rec: &scan: &draw m2-m1 at x-x0,y-y0: &draw 1 at 0,0
307 cmd = peek(249): &mod(cmd,8): if cmd=0 then &end
308 &stop: goto 1180

600 rem save
610 home: input "save path: ";a$
611 &tellp(addr,bit,cnt)
620 print: print chr$(4);"bsave ";a$;",A";a0;",L";addr-a0+2
630 goto 40

650 rem append
660 &tellp(addr,bit,cnt): home: input "load path: ";a$: print chr$(4);"bload ";a$;",A";addr+1
661 &seekg(addr+1,0): &rec: &scan: &draw at 0,0: &end: &stop: goto 40

670 rem load
680 gosub 700: &seekp(a0,0): goto 650

700 rem confirm
701  if addr=a0 and bit=8 or a0=0 then return
702  home: print "Erase? ": gosub 20: if a$="Y" then return
703  pop: print: print "canceled. ";: gosub 20: goto 40

800 rem array setup
810 dim cl(4): dim pn$(9): dim cmd$(7): dim vers(2)
820 restore: for i = 0 to 7: read cmd$(i): next: for i = 0 to 4: cl(i) = 15: next
840 return

850 rem new pic
851 gosub 700: x = 280: y = 80: m1 = 0: m2 = 0: pm = 0: br = 0: &seekg(a0,0): &seekp(a0,0): poke a0,0: addr = a0: bit = 8: cnt = 0: goto 40

860 rem edit
861 &dhr: poke -16302,0: &seekg(a0,0): &draw at 0,0: gosub 880: gosub 10: pr = 1: goto 60

870 rem quit
871 vtab 21: end

880 rem sync parameters
881 pm = peek(249): &and(pm,128): cl(1) = peek(28): &and(cl(1),15): cl(2) = int(peek(28)/16): cl(3) = peek(228): &and(cl(3),15): cl(4) = int(peek(228)/16)
882 &tellg(addr,bit,cnt): &seekp(a0,cnt): return

890 rem picture workspace
891 a0 = peek (48825) + 256 * peek (48826) + peek (48840) + 256 * peek(48841): addr = a0: bit = 8: return

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
1110 &clear 1,24: &print chr$(128) + chr$(132) + ", SPC=start/end" at 1,24: m = -1: n = 0: x0 = 0: y0 = 0
1111 &rec: &end: &stop: &seekg(a0,0)
1120 gosub 1140: gosub 20: gosub 1140: ds = 1: if peek(49249)>127 then ds = 10
1121 if a = 8 and n-ds>=0 then n = n - ds: &seekg(a0,n): goto 1120
1122 if a = 21 then n = n + ds: &seekg(a0,n): &tellg(addr,bit,n): goto 1120
1123 if a$ = " " and m=-1 then m = n: a = 21: ds = 1: goto 1122
1124 if a$ = " " and m>=0 and n>m then m1 = m: m2 = n: mx = x0: my = y0: goto 1180
1132 if a = 27 then 1180
1133 goto 1120

1140 &mode=128: &move to x0,y0: &draw 1 at 0,0: cmd = peek(249): &mod(cmd,8): if cmd <> 5 then x0 = peek(224) + peek(225)*256: y0 = peek(226): rem highlight part
1141 &seekg(a0,n): w$ = str$(m) + " " + str$(n) + " " + cmd$(cmd): &mode=cmd: &clear 28,24 to 32,24: &print w$ at 40-len(w$),24: return

1180 &dhr: poke -16302,0: &seekg(a0,0): &draw at 0,0: gosub 880: gosub 10: return: rem cleanup and return

9990 data end,clr,mod,mov,plt,lin,trp,str
