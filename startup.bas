1 home: print "SETUP DHRLIB..."
10 print chr$(4);"BLOAD DHRLIB"
20 print chr$(4);"BLOAD FONT1"
30 poke 1014,0: poke 1015,64: poke 232,0: poke 233,96
40 print chr$(4);"PR#3"
50 home: print "DHRLIB loaded with FONT1": vtab 21