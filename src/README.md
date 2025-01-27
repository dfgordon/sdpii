# Notes

## Version

The version number is controlled by `scripts/meta.json`.  This is the WOZ metadata for the floppy distribution.  The build scripts will read this file and verify that the version number embedded in DHRLIB is consistent.  The BASIC programs retrieve the version number using the `&vers` ampersand.

As a corollary, the entire package is always synchronized under the same version number.

## Bank Switching Background

Since SDP II is geared toward a case where there is an Applesoft front end, we suppose a RAM disk will be utilized for swapping programs and/or variables. The RAM disk uses auxiliary memory, but the following blocks remain available:

* $0000 to $0200 ($80-$FF reserved)
* $0400 to $0800 (assuming we don't need native text)
* $0800 to $0E00
* $BF00 to $C000 (reserved)

There is also some bank-switched memory not used by ProDOS:

* $D000 to $D100 (bank 2)
* $D400 to $E000 (reserved, bank 2)

Altogether that makes 26 (12.5) pages, or 6656 (3200) bytes, if reserved space is used (not used).

The RAM disk is nominally 127 blocks, but only 121 are used:

* 0 boot blocks (compared to the usual 2)
* 1 directory block (compared to the usual 4)
* 1 bitmap block
* 119 user blocks

This information comes from *Beneath Apple ProDOS*, and from experimenting with the AppleWin debugger.

## Bank Switching

SDP II uses auxiliary and bank-switched memory to stash a standard size (14x8) font, and a standard size (28x16) map set, without compromising the RAM disk.  The auxiliary stack provides a "cyclic stack" accessible from Applesoft.

### Stashed Font

The first 96 glyphs (usually ASCII 32 - 127) are stashed in pages 8 - 13 of auxiliary memory.  Extended glyphs (up to 16) are stashed in page 208 of bank-switched memory, bank 2.

DHRLIB users must issue `&aux` to stash the font, and `POKE 233,0` to use the stashed font.  If this is not done, DHRLIB can still display fonts, but they will take up space in the lower 48K of main memory.

### Stashed Map Set

Up to 48 map tiles can be stored in pages 212 - 223 of bank 2.  The displaced memory can be saved for later restoration.

DHRLIB users must issue `&bank` to stash the tiles, and `POKE 233,0` to use the stashed tiles.  If this is not done, DHRLIB can still render maps, but the tiles will take up space in the lower 48K of main memory.

### Cyclic Stack

The `&psh` and `&pul` ampersands allow byte-values to be pushed onto, and pulled from, the auxiliary stack page.  The "stack" wraps around when it hits the storage boundary (usually the full page).

## Memory Map

All memory protection in this system is by means of HIMEM and LOMEM.  LOMEM is moved past library and workspace areas to prevent collisions with strings.  As of this writing `tile`, `paint` and `repaint` use the following memory map:

Bank | Range | Usage
-----|------|------
main | $0801 - $2000 | Program
main | $2000 - $4000 | Screen buffer
main | $4000 - $XXXX | DHRLIB
main | $XXXX - $8000 | Workspace
main | $8000 - HIMEM | Variables
aux | $0800 - $0E00 | ASCII Glyphs
bank2 | $D000-$D100 | Extended glyphs

The memory map used by `map` is:

Bank | Range | Usage
-----|------|------
main | $0801 - $2000 | Program
main | $2000 - $4000 | Screen buffer
main | $4000 - $XXXX | MAPLIB
main | $XXXX - $8B00 | Map workspace
main | $8B00 - HIMEM | Variables
aux | $0800 - $0E00 | ASCII Glyphs
bank2 | $D000-$D100 | Extended glyphs
bank2 | $D400-$E000 | Tiles 

The workspaces are dynamically allocated based on the actual size of DHRLIB or MAPLIB.  MAPLIB is a version of DHRLIB that only contains map and utility ampersands.  It is supposed to be small enough to allow editing an uncompressed 128 by 128 map.

### Minifier

The BASIC programs are supposed to be minified before being deployed.  If this step is skipped, results are undefined. The build scripts are designed to take care of this.