# PowerShell script to create floppy distro
# Run from root project directory
# (from VSCode just push button)

#Requires -Version 7.4

Set-Variable floppy "./build/sdpii.woz"
Set-Variable basicFiles @("startup","paint","tile","repaint","map")

if (!(Test-Path ./build)) {
    mkdir ./build
} else {
    Remove-Item ./build/*
}

# Get the version from the WOZ metadata
$vers = (Get-Content ./scripts/meta.json | ConvertFrom-Json).woz2.meta.version
# Check DHRLIB version
(Get-Content ./src/dhrlib.S -Raw) -match 'version\s+DFB\s+([0-9]+,[0-9]+,[0-9]+)'
$dhrlib_vers = $Matches[1] -replace ',','.'
if ($vers -ne $dhrlib_vers) {
    Write-Error ("DHRLIB version is " + $dhrlib_vers + ", but meta version is " + $vers)
    exit 1
}

# Create bootable disk with WOZ metadata
a2kit mkdsk -d $floppy -t woz2 -o prodos -v sdpii
Get-Content ./fimg/prodos.json | a2kit put -d $floppy -f prodos -t any
Get-Content ./fimg/basic.system.json | a2kit put -d $floppy -f basic.system -t any
Get-Content ./scripts/meta.json | a2kit put -d $floppy -t meta

# Tokenize and put BASIC sources
foreach ($f in $basicFiles) {
    Get-Content ("./src/" + $f + ".bas") |
     a2kit minify -t atxt --level 3|
      a2kit tokenize -a 2049 -t atxt |
       a2kit put -d $floppy -f $f -t atok
}

# Assemble and put IDENTIFY
Merlin32 ./src ./src/identify.S
a2kit get -f ./src/identify | a2kit put -d $floppy -f identify -t bin -a 768
Move-Item ./src/identify ./build/identify

# Assemble and put DHRLIB and FONT1
Merlin32 ./src ./src/link32.S
a2kit get -f ./src/dhrlib | a2kit put -d $floppy -f dhrlib -t bin -a 16384
a2kit get -f ./fimg/font1.json | a2kit put -d $floppy -f font1 -t any
Move-Item ./src/dhrlib ./build/dhrlib

# Update the project's file images
a2kit get -d $floppy -f dhrlib -t any > ./fimg/dhrlib.json
a2kit get -d $floppy -f identify -t any > ./fimg/identify.json

# Cleanup
Remove-Item ./src/_FileInformation.txt -Force

# If disk image notebook available, leave out the catalog,
# so the merlin output is more readily viewable.

#a2kit catalog -d $floppy