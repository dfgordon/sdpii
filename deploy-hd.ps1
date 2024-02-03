# PowerShell script to deploy to development directory.
# N.b. this assumes an existing project on the emulated HD.

#Requires -Version 7.4

Set-Variable hd ($env:USERPROFILE + "\OneDrive\Documents\appleii\DISKS\microdrive-prodos-working.po")
Set-Variable prodosPath "programming/merlin/sdpii/"
Set-Variable asmFiles @("dhrlib.s")
Set-Variable basicFiles @("paint","tile","repaint")

if (!(Test-Path build)) {
    mkdir build
} else {
    Remove-Item build\dhrlib
}

# even though we are cross assembling, let's update the source on the emulator
foreach ($f in $asmFiles) {
    a2kit delete -d $hd -f ($prodosPath + $f)
    a2kit get -f $f |
     a2kit tokenize -t mtxt |
      a2kit put -d $hd -f ($prodosPath + $f) -t mtok
}
# install the BASIC programs
foreach ($f in $basicFiles) {
    a2kit delete -d $hd -f ($prodosPath + $f)
    a2kit get -f ($f + ".bas") |
     a2kit minify -t atxt |
      a2kit tokenize -a 2049 -t atxt |
       a2kit put -d $hd -f ($prodosPath + $f) -t atok
}
# cross assemble and install object code
Merlin32 . dhrlib.S
a2kit delete -d $hd -f ($prodosPath + "dhrlib")
a2kit get -f dhrlib | a2kit put -d $hd -f ($prodosPath + "dhrlib") -t bin -a 16384
# cleanup
Move-Item .\dhrlib .\build\dhrlib
Remove-Item .\_FileInformation.txt -Force
# update the project's DHRLIB file image
a2kit get -d $hd -f ($prodosPath + "dhrlib") -t any > .\fimg\dhrlib.json

a2kit catalog -d $hd -f $prodosPath