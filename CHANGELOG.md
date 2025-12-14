# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.6.0] - 2025-12-14

### New Features

* Map operations can be factored for better integration into compression schemes
* Redirected output is safe to invoke from either main or aux text pages
* Script to build game versions of libraries assembled at $800
* `&clear` defaults to current cursor and window margins
* `_bound` controls whether CMOS checker is included (omitting saves space)

### New Behaviors

* Submap views are always copied to the input buffer before display
* Ampersands restore the caller's actual PAGE2 state rather than assuming MAIN

## [0.5.0] - 2025-11-09

### Fixes

* Correct documentation concerning pages 12 and 13 of auxiliary memory

### New Features

* Provide hooks for extension libraries
* Add `&den` operation to locate denizen record
* Mapper can display auxiliary records
* Mapper can set denizen's auxiliary field

## [0.4.0] - 2025-10-26

### Fixes

* Tiler can discard changes even if there was a dither
* Tiler warns that preview scan is not reversible

### New Features

* Map denizens are supported
* Character output can be hooked to DHGR screen

### Removed Features

* Printing to the DHGR screen in immediate mode

### Breaking Changes

* `&PRINT` is replaced with `&PR#` and regular `PRINT`
* Extended glyphs in `CHR$` are referenced starting from 5

## [0.3.0] - 2025-05-04

### New Features

* Hard drive installer
* Repainter brought into parity with other editors
* Option to discard changes to a tile
* Configuration of default tiles

## [0.2.0] - 2025-03-30

### Fixes

* Fix an issue with north/south ghost cells

### New Features

* Mapper handles multi-level maps

## [0.1.1] - 2025-03-23

### Fixes

* Allow user to ESC from dithering a tile
* Tile incompatibilities are better handled
* Painter restores prefix upon exit

## [0.1.0] - 2025-03-15

### Fixes

* Fix possible error when exiting mapper
* Update system requirements in WOZ metadata
* Fix issues with large tiles

### New Features

* Tiler interface is improved
* Configuration of default paths
* Map and tile optimizations

### Breaking Changes

* Tile format has changed
    - v0.0.0 tiles can be converted using scripts/dev/upgradeTiles.py

## [0.0.0] - 2025-02-01

Initial release