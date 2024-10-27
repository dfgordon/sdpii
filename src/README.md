# Ancillary Notes

## Auxiliary Memory

Since SDP II is geared toward a case where there is an Applesoft front end, we suppose a RAM disk will be utilized.  Therefore DHRLIB does not use any auxiliary memory other than the DHR screen buffer.  But even when a RAM disk is connected, we still have pockets of free space that add up to about 3.5K:

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
$4000 - $5100 | DHRLIB + free space
$5100 - $6000 | Picture workspace
$6000 - $6652 | DHR font
$8000 - $9000 | Variables

The memory map used by `tile` is:

Range | Usage
------|------
$0801 - $2000 | Program and variables
$2000 - $4000 | Screen buffer
$4000 - $6000 | DHRLIB + free space
$6000 - $8000 | Tile workspace
$8000 - $8652 | DHR font

To do: respond dynamically to the actual size of DHRLIB

### Minifier

The BASIC programs are supposed to be minified before being deployed.  If this step is skipped, results are undefined. The build scripts are designed to take care of this.