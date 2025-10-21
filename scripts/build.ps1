# PowerShell script to create floppy distro
# Run from root project directory
# (from VSCode just push button)

#Requires -Version 7.4
Set-Variable ErrorActionPreference "Stop"
Set-Variable PSNativeCommandUseErrorActionPreference $true

$min_a2kit_vers = "4.0.0"
$a2kit_vers = (a2kit -V).Split()[1]
if ([Version]$a2kit_vers -lt [Version]$min_a2kit_vers) {
    Write-Error ("requires a2kit v" + $min_a2kit_vers)
}

Set-Variable prodosPath ""
Set-Variable floppy "./build/sdpii.woz"
Set-Variable basicFiles @("startup","config","paint","tile","repaint","map","hd.install")

if (!(Test-Path ./build)) {
    mkdir ./build
} else {
    Remove-Item ./build/*
}

# Get the version from the WOZ metadata
$vers = (Get-Content ./scripts/meta.json | ConvertFrom-Json).woz2.meta.version
# Check DHRLIB version
$matching = (Get-Content ./src/merlin/dhrlib.S -Raw) -match 'version\s+DFB\s+([0-9]+,[0-9]+,[0-9]+)'
if (!$matching) {
    Write-Error "DHRLIB version data missing"
    exit 1
}
$dhrlib_vers = $Matches[1] -replace ',','.'
if ($vers -ne $dhrlib_vers) {
    Write-Error ("DHRLIB version is " + $dhrlib_vers + ", but meta version is " + $vers)
    exit 1
}
# Check HD.INSTALL version
$matching = (Get-Content ./src/basic/hd.install.bas -Raw) -match 'HD INSTALLER V([0-9]+\.[0-9]+\.[0-9]+)'
if (!$matching) {
    Write-Error "HD.INSTALL version data missing"
    exit 1
}
if ($vers -ne $Matches[1]) {
    Write-Error ("HD.INSTALL version is " + $Matches[1] + ", but meta version is " + $vers)
    exit 1
}


# Create bootable disk with WOZ metadata
a2kit mkdsk -d $floppy -t woz2 -o prodos -v sdpii
Get-Content ./fimg/prodos.json | a2kit put -d $floppy -f prodos -t any
Get-Content ./fimg/ns.clock.system.json | a2kit put -d $floppy -f ns.clock.system -t any
Get-Content ./fimg/basic.system.json | a2kit put -d $floppy -f basic.system -t any
Get-Content ./scripts/meta.json | a2kit put -d $floppy -t meta

# Tokenize and put BASIC sources
foreach ($f in $basicFiles) {
    Get-Content ("./src/basic/" + $f + ".bas") |
    a2kit renumber -b 0 -e 64000 -f 1 -s 1 -t atxt |
      a2kit minify -t atxt --level 3|
        a2kit tokenize -a 2049 -t atxt |
          a2kit put -d $floppy -f $f -t atok
}

# Assemble, put, and archive IDENTIFY
Merlin32 ./src/merlin ./src/merlin/identify.S
a2kit get -f ./src/merlin/identify | a2kit put -d $floppy -f identify -t bin -a 768
a2kit get -f ./src/merlin/identify | a2kit pack -a 768 -t bin -o prodos -f identify > ./fimg/identify.json
Move-Item ./src/merlin/identify ./build/identify

# Assemble, put, and archive MAPLIB
./scripts/config-asm -target maplib
Merlin32 ./src/merlin ./src/merlin/link32.S
a2kit get -f ./src/merlin/dhrlib | a2kit put -d $floppy -f maplib -t bin -a 16384
a2kit get -f ./src/merlin/dhrlib | a2kit pack -a 16384 -t bin -o prodos -f maplib > ./fimg/maplib.json
Move-Item ./src/merlin/dhrlib ./build/maplib

# Assemble, put, and archive DHRLIB
./scripts/config-asm -target dhrlib
Merlin32 ./src/merlin ./src/merlin/link32.S
a2kit get -f ./src/merlin/dhrlib | a2kit put -d $floppy -f dhrlib -t bin -a 16384
a2kit get -f ./src/merlin/dhrlib | a2kit pack -a 16384 -t bin -o prodos -f dhrlib > ./fimg/dhrlib.json
Move-Item ./src/merlin/dhrlib ./build/dhrlib

# Copy over file images
a2kit get -f ./fimg/disklib.json | a2kit put -d $floppy -f disklib -t any
a2kit get -f ./fimg/font1.json | a2kit put -d $floppy -f font1 -t any
a2kit get -f ./src/basic/config.txt | a2kit put -d $floppy -f sdpii.config -t txt

# Verify
./scripts/verify-distro -disk $floppy -path "/SDPII/"

# Cleanup
Remove-Item ./src/merlin/_FileInformation.txt -Force

# If disk image notebook available, leave out the catalog,
# so the merlin output is more readily viewable.

#a2kit catalog -d $floppy