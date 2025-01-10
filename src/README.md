# Ancillary Notes

## Version

The version number is controlled by `scripts/meta.json`.  This is the WOZ metadata for the floppy distribution.  The build scripts will read this file and verify that the version number embedded in DHRLIB is consistent.  The BASIC programs retrieve the version number using the `&vers` ampersand.

As a corollary, the entire package is always synchronized under the same version number.

## Auxiliary Memory

Since SDP II is geared toward a case where there is an Applesoft front end, we suppose a RAM disk will be utilized for swapping programs and/or variables.  Therefore DHRLIB does not use any auxiliary memory other than the DHR screen buffer.  But even when a RAM disk is connected, we still have pockets of free space that add up to about 3.5K:

* $0000 to $0200 ($80-$FF reserved)
* $0400 to $0800 (assuming we don't need native text)
* $0800 to $0E00
* $BF00 to $C000 (reserved)
* $D000 to $D100 (main memory, but bank switched)
* Altogether that makes 14 pages, or 3584 bytes.

The RAM disk is nominally 127 blocks, but only 121 are used:

* 0 boot blocks (compared to the usual 2)
* 1 directory block (compared to the usual 4)
* 1 bitmap block
* 119 user blocks

## Memory Map

As of this writing `paint` and `repaint` use the following memory map:

Range | Usage
------|------
$0801 - $2000 | Program
$2000 - $4000 | Screen buffer
$4000 - $5XXX | DHRLIB
$5XXX - $6000 | Picture workspace
$6000 - $6652 | DHR font
$8000 - $9000 | Variables

The picture workspace is dynamically allocated based on the actual size of DHRLIB.

The memory map used by `tile` is:

Range | Usage
------|------
$0801 - $2000 | Program and variables
$2000 - $4000 | Screen buffer
$4000 - $6000 | DHRLIB + free space
$6000 - $8000 | Tile workspace
$8000 - $8652 | DHR font

The memory map used by `map` is:

Range | Usage
------|------
$0801 - $2000 | Program and variables
$2000 - $4000 | Screen buffer
$4000 - $6000 | DHRLIB + free space
$6000 - $7000 | Tiles + free space
$7000 - $8000 | Map workspace
$8000 - $8652 | DHR font

### Minifier

The BASIC programs are supposed to be minified before being deployed.  If this step is skipped, results are undefined. The build scripts are designed to take care of this.