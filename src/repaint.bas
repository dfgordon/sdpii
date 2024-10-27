1 himem: 9*4096: lomem: 8*4096: if peek(-1088)=234 then text: home: print chr$(7);"65C02 REQUIRED": end
2  print chr$(4);"bload dhrlib": print chr$(4);"bload font1": print  chr$ (4);"pr#3"
3  poke 1013,76: poke 1014,0: poke 1015,64: poke 232,0: poke 233,96: def fn mod (x) = x - de*int(x/de)
4  a0 = 0: gosub 800: goto 850

5 rem move cursor
6  ds = 1: if peek(49249)>127 then ds = 8
7  x = x - ds*(a=8) + ds*(a=21): y = y - ds*(a=11) + ds*(a=10): de = 560: x = fn mod(x): de = 192: y = fn mod(y)
8  return

10 rem edit prompt
11 &tellp(addr,bit,cnt): &clear 1,24: if pr > 3 then pr = 1
12 on pr goto 13,14,17
13 w$ = "TAB=prompt, ESC=exit, SPC=select": goto 19
14 w$ = "1=recolor,2=move": goto 19
17 w$ = "selection: " + str$(m1) + " to " + str$(m2) + "   " 
19 &print w$ at 1,24: return

20 rem get upper
21 a = peek(49152): if a<128 then 21
22 a = a - 128: a$ = chr$(a): if a>96 then a$ = chr$(a-32)
23 poke 49168,0: return

40  TEXT : HOME : ? "SDP II Repainter v-dev": VTAB 13: &tellp(addr,bit,cnt): ? "length=";addr-a0;".";8-bit:L = 3:P = 3:W$ = "Select- ":B$ =  CHR$ (13)
41 PN$(0) = "Load Pic":PN$(1) = "Save Pic":PN$(2) = "Edit": PN$(3) = "Exit": GOSUB 50
42  ON M + 1 GOTO 670,600,860,870

50  rem menu subroutine
51 N = 0:M = 0: HTAB 1: VTAB L: PRINT "1) ";: INVERSE : PRINT PN$(0): NORMAL : IF P > 0 THEN  FOR I = 1 TO P: PRINT I + 1;") ";PN$(I): NEXT 
52  HTAB 1: VTAB L + P + 2: PRINT W$;: GET A$: IF A$ =  CHR$ (13) OR A$ = B$ THEN  RETURN 
53  IF  VAL (A$) >  = 1 AND  VAL (A$) <  = P + 1 THEN M =  VAL (A$) - 1: RETURN 
54  IF A$ =  CHR$ (8) OR A$ =  CHR$ (11) THEN N = M:M = M - 1: IF M < 0 THEN M = P
55  IF A$ =  CHR$ (10) OR A$ =  CHR$ (21) THEN N = M:M = M + 1: IF M > P THEN M = 0
56  HTAB 4: VTAB N + L: PRINT PN$(N): INVERSE : HTAB 4: VTAB M + L: PRINT PN$(M): NORMAL : GOTO 52

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
202 &seekg(a0,0): de = 8: x = 0: &psh < 0: &psh < 0
203 &scan: &draw 1 at 0,0: &stop: cmd = fn mod(peek(249)): if cmd = 1 then 206
204 if cmd = 0 then 202
205 x = x + 1: goto 203
206 &clear 1,24: &trap at 0,13,184 to 0,13,191: &print chr$(130) + chr$(131) + ", SPC " + str$(x) at 2,24: gosub 20: if a=32 then 211
207 if a=21 then de=256: &psh < fn mod(x): &psh < int(x/256): de = 8: goto 205
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
307 de = 8: if fn mod(peek(249))=0 then &end
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
810 dim cl(4): dim pn$(9): dim cmd$(7)
820 restore: for i = 0 to 7: read cmd$(i): next: for i = 0 to 4: cl(i) = 15: next
840 return

850 rem new pic
851 gosub 700: x = 280: y = 80: m1 = 0: m2 = 0: pm = 0: br = 0: a0 = 81*256: &seekg(a0,0): &seekp(a0,0): poke a0,0: addr = a0: bit = 8: cnt = 0: goto 40

860 rem edit
861 &dhr: poke -16302,0: &seekg(a0,0): &draw at 0,0: gosub 880: gosub 10: pr = 1: goto 60

870 rem quit
871 vtab 21: end

880 rem sync parameters
881 pm = 128*int(peek(249)/128): cl(2) = int(peek(28)/16): cl(1) = peek(28)-cl(2)*16: cl(4) = int(peek(228)/16): cl(3) = peek(228)-cl(4)*16
882 &tellg(addr,bit,cnt): &seekp(a0,cnt): return

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

1140 &mode=128: &move to x0,y0: &draw 1 at 0,0: de = 8: cmd = fn mod(peek(249)): if cmd <> 5 then x0 = peek(224) + peek(225)*256: y0 = peek(226): rem highlight part
1141 &seekg(a0,n): w$ = str$(m) + " " + str$(n) + " " + cmd$(cmd): &mode=cmd: &clear 28,24 to 32,24: &print w$ at 40-len(w$),24: return

1180 &dhr: poke -16302,0: &seekg(a0,0): &draw at 0,0: gosub 880: gosub 10: return: rem cleanup and return

9990 data end,clr,mod,mov,plt,lin,trp,str
 