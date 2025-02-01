1 home: print "CHECK REQUIREMENTS...": print chr$(4);"BLOAD IDENTIFY": call 768
2 f peek(0) = 0 then 10
3 print "ONE OF THE FOLLOWING NOT MET:"
4 print " 1. ENHANCED //E OR HIGHER"
5 print " 2. 80 COLUMN FIRMWARE"
6 print " 3. 128K RAM"
9 end
10 vtab 1: htab 22: print "OK": print "SETUP DHRLIB...": print chr$(4);"BLOAD DHRLIB": gosub 890
20 poke 1013,76: poke 1014,0: poke 1015,64
30 print chr$(4);"BLOAD FONT1": poke 232,0: poke 233,96: &aux: poke 233,0
40 print chr$(4);"PR#3"
50 home: print "FONT1 stashed in auxiliary memory"
60 &seekg(a0,0): &seekp(a0,0): print "Picture buffer at ";a0
70 &vers: dim x(2): &pul > x(0): &pul > x(1): &pul > x(2): print "DHRLIB version is "x(0)"."x(1)"."x(2)
80 print "Repository: https://github.com/dfgordon/sdpii"
99 vtab 21: end

890 rem picture workspace
891 a0 = peek (48825) + 256 * peek (48826) + peek (48840) + 256 * peek(48841): return
