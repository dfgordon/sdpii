# Configure conditional assembly flags.
# Usually invoked as part of a build script.

#Requires -Version 7.4

param (
	[Parameter(Mandatory)]
	[ValidateSet("dhrlib","maplib")]
	[string]$target
)

Set-Variable ErrorActionPreference "Stop"
$picpatt = '(?m)^(_pics\s+=\s*) [0-3]'
$tilpatt = '(?m)^(_tile\s+=\s*) [0-2]'
$sclpatt = '(?m)^(_scroll\s+=\s*) [0-1]'
$wrppatt = '(?m)^(_wrap\s+=\s*) [0-1]'
$bndpatt = '(?m)^(_bound\s+=\s*) [0-1]'
$endpatt = '(\r?\n)+$'

$equivs = Get-Content src/merlin/equiv.S -Raw

# If no backup create one
if (!(Test-Path src/merlin/equiv.bak)) {
    Write-Information "creating equiv.bak" -InformationAction Continue
    $equivs > src/merlin/equiv.bak
}

# Check pattern existence
if ($equivs -notmatch $picpatt -or
$equivs -notmatch $tilpatt -or
$equivs -notmatch $sclpatt -or
$equivs -notmatch $wrppatt -or
$equivs -notmatch $bndpatt) {
    Write-Error "equiv.S is missing a conditional assembly flag"
    exit 1
}

# Now calculate the changes
if ($target -eq "dhrlib") {
    $equivs = $equivs -replace $picpatt,'$1 3'
    $equivs = $equivs -replace $tilpatt,'$1 2'
    $equivs = $equivs -replace $sclpatt,'$1 1'
    $equivs = $equivs -replace $wrppatt,'$1 1'
    $equivs = $equivs -replace $bndpatt,'$1 1'
} elseif ($target -eq "maplib") {
    $equivs = $equivs -replace $picpatt,'$1 0'
    $equivs = $equivs -replace $tilpatt,'$1 2'
    $equivs = $equivs -replace $sclpatt,'$1 0'
    $equivs = $equivs -replace $wrppatt,'$1 0'
    $equivs = $equivs -replace $bndpatt,'$1 0'
}

# Now change it
Set-Content src/merlin/equiv.S ($equivs -replace $endpatt,"")
