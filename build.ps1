# PowerShell script to create floppy distro

#Requires -Version 7.4

Set-Variable floppy "./build/sdpii.woz"
Set-Variable basicFiles @("startup","paint","tile","repaint")

if (!(Test-Path build)) {
    mkdir build
} else {
    Remove-Item build/*
}
a2kit mkdsk -d $floppy -t woz2 -o prodos -v sdpii
a2kit get -f ./fimg/prodos.json | a2kit put -d $floppy -f prodos -t any
a2kit get -f ./fimg/basic.system.json | a2kit put -d $floppy -f basic.system -t any

foreach ($f in $basicFiles) {
    a2kit get -f ($f + ".bas") |
     a2kit minify -t atxt |
      a2kit tokenize -a 2049 -t atxt |
       a2kit put -d $floppy -f $f -t atok
}

Merlin32 . dhrlib.S
a2kit get -f dhrlib | a2kit put -d $floppy -f dhrlib -t bin -a 16384
a2kit get -f ./fimg/font1.json | a2kit put -d $floppy -f font1 -t any
Move-Item ./dhrlib ./build/dhrlib
Remove-Item ./_FileInformation.txt -Force

# update the project's DHRLIB file image
a2kit get -d $floppy -f dhrlib -t any > ./fimg/dhrlib.json

a2kit catalog -d $floppy