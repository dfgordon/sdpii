# PowerShell script to deploy to development directory.
# Run from root project directory
# (from VSCode just push button)
# N.b. this assumes an existing project on the emulated HD.

#Requires -Version 7.4
Set-Variable ErrorActionPreference "Stop"
Set-Variable PSNativeCommandUseErrorActionPreference $true

$min_a2kit_vers = "3.7.0"
$a2kit_vers = (a2kit -V).Split()[1]
if ([Version]$a2kit_vers -lt [Version]$min_a2kit_vers) {
    Write-Error ("requires a2kit v" + $min_a2kit_vers)
}

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

# precleaning
foreach ($f in ($basicfiles + @("dhrlib","maplib"))) {
    try { a2kit delete -d $hd -f ($prodosPath + $f) } catch { Write-Warning ("no pre-existing " + $f) }
}

# install the BASIC programs
foreach ($f in $basicFiles) {
    Get-Content ("./src/basic/" + $f + ".bas") |
      a2kit renumber -b 0 -e 64000 -f 1 -s 1 -t atxt |
        a2kit minify -t atxt --level 3 |
          a2kit tokenize -a 2049 -t atxt |
            a2kit put -d $hd -f ($prodosPath + $f) -t atok
}

# Assemble and put MAPLIB
./scripts/config-asm -target maplib
Merlin32 ./src/merlin ./src/merlin/link32.S
a2kit get -f ./src/merlin/dhrlib | a2kit put -d $hd -f ($prodosPath + "maplib") -t bin -a 16384
a2kit get -f ./src/merlin/dhrlib | a2kit pack -a 16384 -t bin -o prodos -f maplib > ./fimg/maplib.json
Move-Item ./src/merlin/dhrlib ./build/maplib

# Assemble and put DHRLIB
./scripts/config-asm -target dhrlib
Merlin32 ./src/merlin ./src/merlin/link32.S
a2kit get -f ./src/merlin/dhrlib | a2kit put -d $hd -f ($prodosPath + "dhrlib") -t bin -a 16384
a2kit get -f ./src/merlin/dhrlib | a2kit pack -a 16384 -t bin -o prodos -f dhrlib > ./fimg/dhrlib.json
Move-Item ./src/merlin/dhrlib ./build/dhrlib

# Verify
./scripts/verify-distro -disk $hd -path $prodosPath

# cleanup
Remove-Item ./src/merlin/_FileInformation.txt -Force
