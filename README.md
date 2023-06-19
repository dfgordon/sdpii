# Super Dungeon Plot II

This is an Apple II double high resolution (DHR) graphics package.  Components include

* `dhrlib.S` - assembly language subroutines with Applesoft ampersand interface
* `tile.bas` - program to build tile sets, e.g., for fonts or scrolling maps
* `paint.bas` - program to create and encode artwork
* `font1.json` - file image for a DHR font
* `dhrlib.json` - file image of assembled DHRLIB
* `buildBrushes.py` - metaprogram to form brushes

## Status

This is likely to be a moving target for some time

## Ampersands

To use the ampersands, assemble `dhrlib.S` in Merlin 8, or use `a2kit` to restore `dhrlib.json` to a disk image.  Once you have the object file,
```bas
BLOAD DHRLIB
PR#3
POKE 1013,76
POKE 1014,0
POKE 1015,64 
```
The ampersands should now be ready.

### Graphics

* `& dhr` - initialize DHR
* `& mode=aexpr` - plotting mode, 0=normal, 128=xor
* `& hcolor = aexpr[,aexpr,aexpr,aexpr]` - set a color or dither pattern
* `& hplot aexpr,aexpr [{to aexpr,aexpr}]` - same as HGR equivalent
* `& stroke #aexpr at aexpr,aexpr` - brush stroke, brushes are built in
* `& tile #aexpr at aexpr,aexpr` - render tile at column,row; tiles must be loaded at (232)
* `& print sexpr at aexpr,aexpr` - print string to DHR screen at column,row; font must be loaded at (232)
* `& trap at x0,x1,y0 to x2,x3,y1` - fill trapezoid defined by upper and lower segments (coords can be aexpr)
* `& draw at aexpr,aexpr` - draw binary encoded picture, picture must be loaded at (232)

### Utility

* `& bit (aexpr,real)` - test bit aexpr, real variable is tested and receives result
* `& inistk` - initialize internal stack (istack)
* `& stkptr > real` - copy istack pointer to real variable
* `& psh < aexpr` - push value of expression onto istack
* `& pul > real` - pull byte from istack and store in real variable

## About Apple II Graphics

Apple II graphics are built upon the idea of spoofing an analog decoder into interpreting digital data as a picture.  The decoders in question are those that were found in American color television sets (TV's) circa 1980.  These decoders work by separating a primary carrier, which encodes black and white, from a subcarrier, which encodes two color channels in phase quadrature.  It can be shown that the black and white signal plus the two color channels carry the same information as three color channels.

The Apple II feeds the decoder a rectangular waveform made out of digital highs and lows in order to approximate a color picture.  In regular high-res, When the bits are alternated at the maximum rate, the period of the square wave matches the period of the color subcarrier.  The circuitry includes a phase shifter that is used to activate one color channel or the other, depending on the high bits in the screen buffer.

In the case of DHR, the bits can be alternated at quadruple the subcarrier frequency.  This way, the phase of the wave can be directly encoded in the bit patterns.  Specifically, four bits correspond to a full period of the subcarrier, so a shift by one bit is a 90 degree phase shift.  Call these four bits a *color nibble*.  Now the phase of the analog signal that the TV is expecting is fixed by a reference signal called the *color burst*.  This absolute phase also fixes the alignment of the color nibbles, i.e., the color nibble `0001` is blue only if it is aligned.  This alignment is tricky because in DHR the high bits in the screen buffer are passed over.  As a result, the color nibbles are aligned to nibble boundaries only if we agree to subtract out all the high bits from the overall bit sequence.

To understand why `0001` is blue takes a bit of analysis.  Thinking in reverse, we may roughly say that some superposition of the three analog channels would be needed to produce this digital waveform.  Evidently this superposition corresponds to blue.  This blue arrangement plus the other fifteen possible arrangements give sixteen colors.

Interestingly it is possible to get more colors out of DHR by taking advantage of the detailed characteristics of the analog color channels.  See Kris Kennaway's [ii-pix docs](https://github.com/KrisKennaway/ii-pix/blob/main/docs/dhr.md).