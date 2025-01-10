1 home: print "SETUP DHRLIB..."
10 print chr$(4);"BLOAD DHRLIB": gosub 890
20 print chr$(4);"BLOAD FONT1"
30 poke 1014,0: poke 1015,64: poke 232,0: poke 233,96
40 print chr$(4);"PR#3"
50 home: print "DHRLIB loaded with FONT1"
60 &seekg(a0,0): &seekp(a0,0): print "Picture buffer at ";a0
70 &vers: dim x(2): &pul > x(0): &pul > x(1): &pul > x(2): print "DHRLIB version is "x(0)"."x(1)"."x(2)
99 vtab 21: end

890 rem picture workspace
891 a0 = peek (48825) + 256 * peek (48826) + peek (48840) + 256 * peek(48841): return
