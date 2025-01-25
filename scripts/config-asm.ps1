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
$tilpatt = '(?m)^(_tile\s+=\s*) [0-3]'
$endpatt = '(\r?\n)+$'

$equivs = Get-Content src/merlin/equiv.S -Raw

# If no backup create one
if (!(Test-Path src/merlin/equiv.bak)) {
    Write-Information "creating equiv.bak" -InformationAction Continue
    $equivs > src/merlin/equiv.bak
}

# Now calculate the changes
if ($equivs -notmatch $picpatt) {
    Write-Error "equiv.S is missing _pics control flag"
    exit 1
}
if ($equivs -notmatch $tilepatt) {
    Write-Error "equiv.S is missing _tiles control flag"
    exit 1
}

if ($target -eq "dhrlib") {
    $equivs = $equivs -replace $picpatt,'$1 3'
    $equivs = $equivs -replace $tilpatt,'$1 3'
} elseif ($target -eq "maplib") {
    $equivs = $equivs -replace $picpatt,'$1 0'
    $equivs = $equivs -replace $tilpatt,'$1 3'
}

# Now change it
Set-Content src/merlin/equiv.S ($equivs -replace $endpatt,"")
