# PowerShell script to verify distribution.
# Normally run as part of build.

#Requires -Version 7.4

param (
	[Parameter(Mandatory)]
	[string]$disk,
    [Parameter(Mandatory)]
    [string]$path
)

Set-Variable ErrorActionPreference "Stop"

function Get-ProdosEof {
    param (
        $FileName
    )
    $eof = (a2kit get -d $disk -f ($path + $FileName) -t any | ConvertFrom-Json).eof
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

function Test-Load {
    param (
        [string]$FileName,
        [string]$expected
    )
    $aux = (a2kit get -d $disk -f ($path + $FileName) -t any | ConvertFrom-Json).aux
    if ($aux -ne $expected) {
        Write-Error($FileName + " should have aux = " + $expected + ", got " + $aux)
    }
}

# Check sizes

$env:RUST_LOG = "error"
Set-Variable lomem 0x8b00
Set-Variable largestMap (8 + 6 + 128*128 + 4)
Test-Size "maplib" ($lomem-$largestMap-0x4000)
Test-Size "dhrlib" 0x1820
Test-Size "paint" 0x1800
Test-Size "repaint" 0x1800
Test-Size "map" 0x1800
Test-Size "tile" 0x1800

# Check load addresses

Test-Load "font1" "0060"