# Super Dungeon Plot II

This is an Apple II double high resolution (DHR) graphics package.  Components include

* `dhrlib.S` - assembly language subroutines with Applesoft ampersand interface
* `tile.bas` - program to build tile sets, e.g., for fonts or scrolling maps
* `paint.bas` - program to create and encode artwork
* `repaint.bas` - program to modify artwork
* `font1.json` - file image for a DHR font
* `dhrlib.json` - file image of assembled DHRLIB
* `buildBrushes.py` - metaprogram to form brushes

## Status

Getting closer...

## Build

Building requires PowerShell 7.4, Merlin32, and a2kit.  From PowerShell get to the project directory and run `build.ps1`.  You should now have a bootable WOZ in the `build` directory containing everything needed.  By default every level of bounds checking is enabled (see below).

## Ampersands

To try the ampersand library in immediate mode, just boot the floppy. You should get the FP prompt with the ampersands and a font preloaded.  Try this:
```bas
&dhr
&hcolor = 11
&trap at 10,50,10 to 20,30,50
&hcolor = 1,1,2,2
&stroke #7 at 500,100
&print "Hello World!" at 1,1
```
The (232) pointer is shared by `&PRINT`, `&TILE`, and `&DRAW`, so be sure to reset it as needed.

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

## Bounds Checking and Optimization

The lowest level bounds check prevents any stores outside the screen buffer.  If an out of bounds store makes it to this level the result is simply a clipped drawing.

The next level of bounds checking is cursor wrap-around.  Signed horizontal coordinates work gracefully within the range `-1024 <= x < 1024` (still some issues as of this writing).  Outside this range the wrapping is difficult to predict, but will still keep the cursor on screen.

The highest level bounds checks occur during ampersand parsing.  Any out of bounds coordinate throws an `ILLEGAL QUANTITY ERROR`.  If this check is active, wrapping is usually prevented.

Optimization for a given purpose can be achieved by using conditional assembly to bypass one or more of the three kinds of bounds checks.

## About Apple II Graphics

Apple II graphics are built upon the idea of spoofing an analog decoder into interpreting digital data as a picture.  The decoders in question are those that were found in American color television sets (TV's) circa 1980.  These decoders work by separating a primary carrier, which encodes black and white, from a subcarrier, which encodes two color channels in phase quadrature.  It can be shown that the black and white signal plus the two color channels carry the same information as three color channels.

The Apple II feeds the decoder a rectangular waveform made out of digital highs and lows in order to approximate a color picture.  In regular high-res, When the bits are alternated at the maximum rate, the period of the square wave matches the period of the color subcarrier.  The circuitry includes a phase shifter that is used to activate one color channel or the other, depending on the high bits in the screen buffer.

In the case of DHR, the bits can be alternated at quadruple the subcarrier frequency.  This way, the phase of the wave can be directly encoded in the bit patterns.  Specifically, four bits correspond to a full period of the subcarrier, so a shift by one bit is a 90 degree phase shift.  Call these four bits a *color nibble*.  Now the phase of the analog signal that the TV is expecting is fixed by a reference signal called the *color burst*.  This absolute phase also fixes the alignment of the color nibbles, i.e., the color nibble `0001` is blue only if it is aligned.  This alignment is tricky because in DHR the high bits in the screen buffer are passed over.  As a result, the color nibbles are aligned to nibble boundaries only if we agree to subtract out all the high bits from the overall bit sequence.

To understand why `0001` is blue takes a bit of analysis.  Thinking in reverse, we may roughly say that some superposition of the three analog channels would be needed to produce this digital waveform.  Evidently this superposition corresponds to blue.  This blue arrangement plus the other fifteen possible arrangements give sixteen colors.

Interestingly it is possible to get more colors out of DHR by taking advantage of the detailed characteristics of the analog color channels.  See Kris Kennaway's [ii-pix docs](https://github.com/KrisKennaway/ii-pix/blob/main/docs/dhr.md).