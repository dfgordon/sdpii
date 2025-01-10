# PowerShell script to deploy to development directory.
# Run from root project directory
# (from VSCode just push button)
# N.b. this assumes an existing project on the emulated HD.

#Requires -Version 7.4

Set-Variable hd ($env:USERPROFILE + "\OneDrive\Documents\appleii\DISKS\microdrive-prodos-working.po")
Set-Variable prodosPath "programming/merlin/sdpii/"
Set-Variable basicFiles @("paint","tile","repaint","map")

if (!(Test-Path build)) {
    mkdir ./build
} else {
    Remove-Item ./build/dhrlib
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

# install the BASIC programs
foreach ($f in $basicFiles) {
    a2kit delete -d $hd -f ($prodosPath + $f)
    Get-Content ("./src/" + $f + ".bas") |
     a2kit minify -t atxt --level 3 |
      a2kit tokenize -a 2049 -t atxt |
       a2kit put -d $hd -f ($prodosPath + $f) -t atok
}

# cross assemble and install object code
Merlin32 ./src ./src/link32.S
a2kit delete -d $hd -f ($prodosPath + "dhrlib")
a2kit get -f ./src/dhrlib | a2kit put -d $hd -f ($prodosPath + "dhrlib") -t bin -a 16384

# cleanup
Move-Item ./src/dhrlib ./build/dhrlib
Remove-Item ./src/_FileInformation.txt -Force
# update the project's DHRLIB file image
a2kit get -d $hd -f ($prodosPath + "dhrlib") -t any > ./fimg/dhrlib.json

#a2kit catalog -d $hd -f $prodosPath