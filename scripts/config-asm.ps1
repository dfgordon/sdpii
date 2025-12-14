# Configure conditional assembly flags.
# Usually invoked as part of a build script.

#Requires -Version 7.4

param (
    [Parameter(Mandatory)]
    [Int16]$load_addr,

	[Parameter(Mandatory)]
	[ValidateSet("dhrlib","maplib","dhrlib-game","maplib-game")]
	[string]$target
)

Set-Variable ErrorActionPreference "Stop"
$picpatt = '(?m)^(_pics\s+=\s*) [0-3]'
$tilpatt = '(?m)^(_tile\s+=\s*) [0-2]'
$sclpatt = '(?m)^(_scroll\s+=\s*) [0-1]'
$wrppatt = '(?m)^(_wrap\s+=\s*) [0-1]'
$bndpatt = '(?m)^(_bound\s+=\s*) [0-1]'
$endpatt = '(\r?\n)+$'
$orgpatt = '(?m)^\s+ORG\s+(\$[0-9a-fA-F]+)'

$equivs = Get-Content src/merlin/equiv.S -Raw
$link32 = Get-Content src/merlin/link32.S -Raw

# If no backups create them
if (!(Test-Path src/merlin/equiv.bak)) {
    Write-Information "creating equiv.bak" -InformationAction Continue
    $equivs > src/merlin/equiv.bak
}
if (!(Test-Path src/merlin/link32.bak)) {
    Write-Information "creating link32.bak" -InformationAction Continue
    $link32 > src/merlin/link32.bak
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
if ($link32 -notmatch $orgpatt) {
    Write-Error "link32.S is missing the ORG line"
    exit 1
}

# Now calculate the changes
$link32 = $link32 -replace $orgpatt, ('         ORG   $' + $load_addr.ToString("X"))
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
} elseif ($target -eq "dhrlib-game") {
    $equivs = $equivs -replace $picpatt,'$1 2'
    $equivs = $equivs -replace $tilpatt,'$1 2'
    $equivs = $equivs -replace $sclpatt,'$1 0'
    $equivs = $equivs -replace $wrppatt,'$1 0'
    $equivs = $equivs -replace $bndpatt,'$1 0'
} elseif ($target -eq "maplib-game") {
    $equivs = $equivs -replace $picpatt,'$1 0'
    $equivs = $equivs -replace $tilpatt,'$1 2'
    $equivs = $equivs -replace $sclpatt,'$1 0'
    $equivs = $equivs -replace $wrppatt,'$1 0'
    $equivs = $equivs -replace $bndpatt,'$1 0'
}

# Now change it
Set-Content src/merlin/equiv.S ($equivs -replace $endpatt,"")
Set-Content src/merlin/link32.S ($link32 -replace $endpatt,"")
