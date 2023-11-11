1 lomem: 8*4096: if peek(-1088)=234 then text: home: print chr$(7);"65C02 REQUIRED": end
2  print chr$(4);"bload dhrlib": print  chr$ (4);"pr#3"
3  poke 1013,76: poke 1014,0: poke 1015,64
4 &inistk: gosub 800: goto 850

10 rem edit prompt
11 poke 49236,0: home: vtab 21
12 print "1=move, 2=recolor, 3=color, cx=cut, esc=menu"
16 poke 49237,0: htab 1: vtab 24: print "bytes ";addr-a0+1;: return

20 rem get upper
21 a = peek(49152): if a<128 then 21
22 a = a - 128: a$ = chr$(a): if a>96 then a$ = chr$(a-32)
23 poke 49168,0: return

30 rem move x
31 w = peek(addr) + 256*peek(addr+1) + x
32 poke addr,w-256*int(w/256): poke addr+1,int(w/256): addr = addr + 2: return
33 rem move y
34 b = peek(addr) + y: poke addr,b: addr = addr + 1: return

40  TEXT : HOME : PRINT "SDP II Transformer v-dev": VTAB 13: PRINT "bytes=";addr-a0+1:L = 3:P = 4:W$ = "Select- ":B$ =  CHR$ (13)
41 PN$(0) = "Load Pic":PN$(1) = "Save Pic":PN$(2) = "Append Pic":PN$(3) = "Edit Pic": PN$(4) = "Exit": GOSUB 50
42  ON M + 1 GOTO 670,600,650,860,870

50  rem menu subroutine
51 N = 0:M = 0: HTAB 1: VTAB L: PRINT "1) ";: INVERSE : PRINT PN$(0): NORMAL : IF P > 0 THEN  FOR I = 1 TO P: PRINT I + 1;") ";PN$(I): NEXT 
52  HTAB 1: VTAB L + P + 2: PRINT W$;: GET A$: IF A$ =  CHR$ (13) OR A$ = B$ THEN  RETURN 
53  IF  VAL (A$) >  = 1 AND  VAL (A$) <  = P + 1 THEN M =  VAL (A$) - 1: RETURN 
54  IF A$ =  CHR$ (8) OR A$ =  CHR$ (11) THEN N = M:M = M - 1: IF M < 0 THEN M = P
55  IF A$ =  CHR$ (10) OR A$ =  CHR$ (21) THEN N = M:M = M + 1: IF M > P THEN M = 0
56  HTAB 4: VTAB N + L: PRINT PN$(N): INVERSE : HTAB 4: VTAB M + L: PRINT PN$(M): NORMAL : GOTO 52

60 rem edit loop
61  gosub 20
64  if a$ = "1" then gosub 300: goto 60
65  if a$ = "2" then gosub 400: goto 60
66  if a$ = "3" then gosub 500: goto 60
70  if a = 24 then gosub 550: goto 60
72  if a = 27 then poke addr,255: goto 40
73  goto 60

200 rem color
201 p$ = "color: ": gosub 900: c1 = b: &hcolor=c1
202 c2 = c1: c3 = c1: c4 = c1: goto 214

210 rem dither
211 p$ = "Dither color r1c1: ": gosub 900: c1 = b: p$ = "Dither color r1c2: ": gosub 900: c2 = b
212 p$ = "Dither color r2c1: ": gosub 900: c3 = b: p$ = "Dither color r2c2: ": gosub 900: c4 = b
213 &hcolor=c1,c2,c3,c4
214 gosub 10: return

300 rem move
310 home: vtab 21: input "horizontal: ";x: input "vertical: ";y
320 poke addr,255: addr = a0
330 if peek(addr) > 127 then 1180
340 if peek(addr) > 7 then print chr$(7);"BAD DHR CODE": end
350 b = peek(addr): if b=3 then addr = addr+1: gosub 30: gosub 33: goto 330: rem plot
351 if b=4 then addr = addr+1: gosub 30: gosub 33: gosub 30: goto 330: rem hlin
352 if b=5 then addr = addr+1: gosub 30: gosub 33: gosub 30: gosub 33: goto 330: rem line
353 if b=6 then addr = addr+1: gosub 30: gosub 33: gosub 30: gosub 30: gosub 33: gosub 30: goto 330: rem trap
354 if b=7 then addr = addr+1: gosub 30: gosub 33: addr = addr + 1: goto 330: rem stroke
399 addr = addr + cmdLn(b): goto 330

400 rem recolor all old patterns
410 end

500 rem color a range of steps
510 end

550 rem cut
560 gosub 1100: if a=27 then return
570 gosub 1150: return

600 rem save
610 home: input "save path: ";a$
620 print: print chr$(4);"bsave ";a$;",A";a0;",L";addr-a0+1
630 goto 40

650 rem append
660 &inistk: home: input "load path: ";a$: print chr$(4);"bload ";a$;",A";addr: addr = addr + peek (48840) + 256 * peek (48841) - 1: goto 40

670 rem load
680 addr = a0: goto 650

800 rem array setup
810 dim cl$(15): dim cmd$(7): dim cmdLn(7): dim c(9): dim curs(1,2): dim pn$(9)
820 restore: for i = 0 to 15: read cl$(i): next
830 for i = 0 to 7: read cmd$(i): read cmdLn(i): next
840 return

850 rem new pic
851 x = 280: y = 80: ps = 0: pm = 0: br = 0: a0 = 96*256: addr = a0: c1 = 15: gosub 202: poke 232,0: poke 233,a0/256: poke addr,255: goto 40

860 rem edit
861 &dhr: &draw at 0,0: gosub 880: gosub 10: goto 60

870 rem quit
871 vtab 21: end

880 rem sync parameters
881 pm = peek(249): c2 = int(peek(28)/16): c1 = peek(28)-c2*16: c4 = int(peek(228)/16): c3 = peek(228)-c4*16: return

900 rem color picker
910 b = 0
911 if b>15 then b = 0
912 if b<0 then b = 15
920 home: vtab 21: print p$;cl$(b): print "use arrows, return": get a$
930 if a$ = chr$(13) then return
940 if a$ = chr$(8) then b = b - 1: goto 911
950 if a$ = chr$(21) then b = b + 1: goto 911
960 goto 911

1100 rem select
1110 home: vtab 21: print "arrows, spc starts and ends, esc aborts": addr% = addr: poke addr,255: addr = a0: poke 232,0: poke 233,3: m = -1: n = 0
1111 &inistk: &mode=128: gosub 1190: onerr goto 1140
1120 gosub 20: b = peek(addr+cmdLn(peek(addr))): rem lookahead code
1121 if a = 8 and n>0 then n = n - 1: gosub 1190: &pul > b: addr = addr - cmdLn(b): gosub 1190: goto 1120
1122 if a = 21 and b<128 then n = n + 1: gosub 1190: &psh < b: addr = addr + cmdLn(b): gosub 1190: goto 1120
1123 if a$ = " " and m=-1 then m = n: gosub 1190: gosub 1190: goto 1120
1124 if a$ = " " and m>=0 and n>m then return: rem selection done
1132 if a = 27 then gosub 1190: addr = addr%: goto 1180
1133 goto 1120

1140 call -3288: if peek (222) = 42 then print "cannot go back": n = n + 1: gosub 1190: goto 1120
1141 print chr$(7);"unhandled error ";peek (222): end

1150 rem cut
1151 addr = a0: if m>0 then for i = 0 to m-1: addr = addr + cmdLn(peek(addr)): next
1152 w = addr: for i = m to n-1: w = w + cmdLn(peek(w)): next
1153 b = peek(w): if b > 127 then poke addr,b: goto 1180
1154 for i = 0 to cmdLn(b)-1: poke addr+i,peek(w+i): next: addr = addr + i: w = w + i: goto 1153
1180 poke 216,0: poke 232,0: poke 233,a0/256: &dhr: &draw at 0,0: gosub 880: gosub 10: return: rem cleanup and return

1190 b = peek(addr): poke 49237,0: htab 1: vtab 22: print m" "n" "cmd$(b)"   ": if b=0 or b=1 then return: rem highlight part
1191 for i=0 to cmdLn(b)-1: poke 768+i,peek(addr+i): next: poke 768+i,255: &draw at 0,0: return

9990 data black,blue,green,cyan,brown,grey-brown,light green,aquamarine,magenta,purple,grey-green,blue-grey,orange,pink,yellow,white
9991 data color,3,mode,2,draw,3,plot,4,hline,6,line,7,trap,11,stroke,5: rem cmd name,length