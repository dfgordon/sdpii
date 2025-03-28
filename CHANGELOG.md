# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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