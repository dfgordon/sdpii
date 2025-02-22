10 text: home: print chr$(17)
20 onerr goto 1000
30 print chr$(4);"verify sdpii.config": poke 216,0
31 print chr$(4);"open sdpii.config"
32 print chr$(4);"read sdpii.config"
33 input vers: input art$: input map$: input tile$
34 print chr$(4);"close sdpii.config"

100 rem edit default paths
110 home: print "Edit Default Paths": print "(leave blank to use working path)": print
120 print "Path to artwork:": temp$ = art$: gosub 400: art$ = a$
130 print "Path to maps:": temp$ = map$: gosub 400: map$ = a$
140 print "Path to tiles:": temp$ = tile$: gosub 400: tile$ = a$

200 rem save configuration
210 onerr goto 1010
220 print chr$(4);"verify sdpii.config": poke 216,0
221 print chr$(4);"open sdpii.config"
222 print chr$(4);"write sdpii.config"
230 print vers: print art$: print map$: print tile$: print "end"
240 print chr$(4);"close sdpii.config"
250 print "done.": end

400 rem edit string
410 print " ";temp$: call -868
420 vtab peek (37): htab 1: input a$: if a$ = "" then return
421 if right$(a$,1) <> "/" then a$ = a$ + "/"
430 onerr goto 490
440 print chr$(4);"verify ";a$: poke 216,0
450 return
490 input "invalid path, try again (Y/N) ";a$
491 if a$ = "Y" then call -3288: poke 216,0: goto 410
492 end

1000 print chr$(7);"No SDP II configuration found.": poke 216,0: end
1010 print chr$(7);"Error ";peek (222): poke 216,0: end