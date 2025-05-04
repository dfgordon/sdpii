10 text: home: print chr$(17)
20 onerr goto 1000
30 print chr$(4);"verify sdpii.config": poke 216,0
31 print chr$(4);"open sdpii.config"
32 print chr$(4);"read sdpii.config"
33 input vers: input art$: input map$: input tile$
34 if vers = 0 then 99
35 input avtar: input bound: input inner
99 vers = 0.3: print chr$(4);"close sdpii.config"

100 rem edit default paths
110 home: print "Edit Default Paths": print "(leave blank to use working path)": print
120 print "Path to artwork:": temp$ = art$: gosub 400: art$ = a$
130 print "Path to maps:": temp$ = map$: gosub 400: map$ = a$
140 print "Path to tiles:": temp$ = tile$: gosub 400: tile$ = a$
150 print "Default avatar tile:": temp$ = str$(avtar): gosub 500: avtar = a
151 print "Initial bounding tile:": temp$ = str$(bound): gosub 500: bound = a
152 print "Initial interior tile:": temp$ = str$(inner): gosub 500: inner = a

200 rem save configuration
210 onerr goto 1010
220 print chr$(4);"verify sdpii.config": poke 216,0
221 print chr$(4);"open sdpii.config"
222 print chr$(4);"write sdpii.config"
230 print vers: print art$: print map$: print tile$: print avtar: print bound: print inner: print "end"
240 print chr$(4);"close sdpii.config"
250 print "done.": end

400 rem edit path
410 print " ";temp$: call -868
420 vtab peek (37): htab 1: input a$: if a$ = "" then return
421 if right$(a$,1) <> "/" then a$ = a$ + "/"
430 onerr goto 490
440 print chr$(4);"verify ";a$: poke 216,0
450 return
490 input "invalid path, try again (Y/N) ";a$
491 if a$ = "Y" then call -3288: poke 216,0: goto 410
492 end

500 rem edit number
510 print " ";temp$: call -868
520 vtab peek (37): htab 1: input a$: a = val(a$): return

1000 print chr$(7);"No SDP II configuration found.": poke 216,0: end
1010 print chr$(7);"Error ";peek (222): poke 216,0: end