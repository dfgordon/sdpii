# PowerShell script to verify floppy distro
# Run from root project directory
# (from VSCode just push button)

#Requires -Version 7.4
Set-Variable ErrorActionPreference "Stop"

Set-Variable floppy "./build/sdpii.woz"

function Get-ProdosEof {
    param (
        $FileName
    )
    $eof = (a2kit get -d $floppy -f $FileName -t any | ConvertFrom-Json).eof
    $eof = $eof.Substring(4,2) + $eof.Substring(2,2) + $eof.Substring(0,2)
    [int]("0x"+$eof)
}

function Test-Size {
    param (
        [string]$FileName,
        [int]$max
    )
    $eof = Get-ProdosEof $FileName
    if ($eof -gt $max) {
        Write-Error($FileName + " is too big " + $eof + "/" + $max)
    } else {
        Write-Output ($FileName + " size is " + $eof + "/" + $max)
    }
}

# Check sizes

$env:RUST_LOG = "error"
Test-Size "maplib" 0xb00
Test-Size "dhrlib" 0x1800
Test-Size "paint" 0x1800
Test-Size "repaint" 0x1800
Test-Size "map" 0x1800
Test-Size "tile" 0x1800
