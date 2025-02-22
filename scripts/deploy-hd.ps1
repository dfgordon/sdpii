# PowerShell script to deploy to development directory.
# Run from root project directory
# (from VSCode just push button)
# N.b. this assumes an existing project on the emulated HD.

#Requires -Version 7.4
Set-Variable ErrorActionPreference "Stop"

Set-Variable hd ($env:USERPROFILE + "\OneDrive\Documents\appleii\DISKS\microdrive.po")
Set-Variable prodosPath "dev/sdpii/"
Set-Variable basicFiles @("config","paint","tile","repaint","map")

if (!(Test-Path build)) {
    mkdir ./build
} else {
    Remove-Item ./build/*lib
}

# Get the version from the WOZ metadata
$vers = (Get-Content ./scripts/meta.json | ConvertFrom-Json).woz2.meta.version
# Check DHRLIB version
(Get-Content ./src/merlin/dhrlib.S -Raw) -match 'version\s+DFB\s+([0-9]+,[0-9]+,[0-9]+)'
$dhrlib_vers = $Matches[1] -replace ',','.'
if ($vers -ne $dhrlib_vers) {
    Write-Error ("DHRLIB version is " + $dhrlib_vers + ", but meta version is " + $vers)
    exit 1
}

# install the BASIC programs
foreach ($f in $basicFiles) {
    a2kit delete -d $hd -f ($prodosPath + $f)
    Get-Content ("./src/basic/" + $f + ".bas") |
      a2kit renumber -b 0 -e 64000 -f 1 -s 1 -t atxt |
        a2kit minify -t atxt --level 3 |
          a2kit tokenize -a 2049 -t atxt |
            a2kit put -d $hd -f ($prodosPath + $f) -t atok
}

# Assemble and put MAPLIB
./scripts/config-asm -target maplib
Merlin32 ./src/merlin ./src/merlin/link32.S
a2kit delete -d $hd -f ($prodosPath + "maplib")
a2kit get -f ./src/merlin/dhrlib | a2kit put -d $hd -f ($prodosPath + "maplib") -t bin -a 16384
a2kit get -f ./src/merlin/dhrlib | a2kit pack -a 16384 -t bin -o prodos -f maplib > ./fimg/maplib.json
Move-Item ./src/merlin/dhrlib ./build/maplib

# Assemble and put DHRLIB
./scripts/config-asm -target dhrlib
Merlin32 ./src/merlin ./src/merlin/link32.S
a2kit delete -d $hd -f ($prodosPath + "dhrlib")
a2kit get -f ./src/merlin/dhrlib | a2kit put -d $hd -f ($prodosPath + "dhrlib") -t bin -a 16384
a2kit get -f ./src/merlin/dhrlib | a2kit pack -a 16384 -t bin -o prodos -f dhrlib > ./fimg/dhrlib.json
Move-Item ./src/merlin/dhrlib ./build/dhrlib

# cleanup
Remove-Item ./src/merlin/_FileInformation.txt -Force
