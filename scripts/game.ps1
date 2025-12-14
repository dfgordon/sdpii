# PowerShell script to create library images for game deployment, i.e.,
# DHRLIB and MAPLIB with error checking and development features omitted.
# These are persisted in the repository as file images.
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

if (!(Test-Path ./build)) {
    mkdir ./build
} else {
    Remove-Item ./build/*
}

# Assemble game version of MAPLIB
./scripts/config-asm -target maplib-game -load_addr 2048
Merlin32 ./src/merlin ./src/merlin/link32.S
a2kit get -f ./src/merlin/dhrlib | a2kit pack -a 2048 -t bin -o prodos -f maplib.g > ./fimg/maplib.g.json
Move-Item ./src/merlin/dhrlib ./build/maplib.g

# Assemble game version of DHRLIB
./scripts/config-asm -target dhrlib-game -load_addr 2048
Merlin32 ./src/merlin ./src/merlin/link32.S
a2kit get -f ./src/merlin/dhrlib | a2kit pack -a 2048 -t bin -o prodos -f dhrlib.g > ./fimg/dhrlib.g.json
Move-Item ./src/merlin/dhrlib ./build/dhrlib.g

# cleanup
Remove-Item ./src/merlin/_FileInformation.txt -Force
