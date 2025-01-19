# Ancillary Notes

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

SDP II uses auxiliary and bank-switched memory to stash a standard size (14x8) font.
The first 96 glyphs (usually ASCII 32 - 127) are stashed in pages 8 - 13 of auxiliary memory.  Extended glyphs (up to 16) are stashed in page 208 of bank-switched memory, bank 2.

DHRLIB users must issue `&aux` to stash the font, and `POKE 233,0` to use the stashed font.  If this is not done, DHRLIB can still display fonts, but they will take up space in the lower 48K of main memory.

## Memory Map

As of this writing `paint` and `repaint` use the following memory map:

Range | Usage
------|------
$0801 - $2000 | Program
$2000 - $4000 | Screen buffer
$4000 - $5XXX | DHRLIB
$5XXX - $8000 | Picture workspace
$8000 - himem | Variables

The picture workspace is dynamically allocated based on the actual size of DHRLIB.

The memory map used by `tile` is:

Range | Usage
------|------
$0801 - $2000 | Program and variables
$2000 - $4000 | Screen buffer
$4000 - $6000 | DHRLIB + free space
$6000 - himem | Tile workspace

The memory map used by `map` is:

Range | Usage
------|------
$0801 - $2000 | Program and variables
$2000 - $4000 | Screen buffer
$4000 - $6000 | DHRLIB + free space
$6000 - $7000 | Tiles + free space
$7000 - himem | Map workspace

### Minifier

The BASIC programs are supposed to be minified before being deployed.  If this step is skipped, results are undefined. The build scripts are designed to take care of this.