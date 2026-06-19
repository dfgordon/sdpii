# PowerShell script to generate a header file for DHRLIB.
# This expects the Merlin32 output files to be in the build directory, and should work for any configuration of DHRLIB.
# Normally run as part of build.

#Requires -Version 7.4

function Convert-AssemblyToEquivalences {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$inLines,
        [Parameter(Mandatory = $true)]
        [string]$vers
    )

    begin {
        $entryRegex = '^.{88}(\S+)\s+(ENT|ent)(\s+|$)'
        $moduleRegex = '^.{88}\s+DSK\s+(\S+)'
        $format = @(@{Expression='label'; width=9}, @{Expression='op'; width=6}, @{Expression='addr'})
        $outString = "* DHRLIB " + $vers + " Entry Points`n"
        $outString += "* " + "-" * ($outString.Length-4) + "`n`n"
        $moduleHeading = ""
        $docstring = ""
    }
    process {
        # this loop is over all the lines from all the sources
        $inLines | ForEach-Object {
            if ($_.Length -gt 88) {
                if ($_ -match $moduleRegex) {
                    $moduleHeading = "* Entries from Module " + $Matches[1] + "`n"
                    $moduleHeading += "* " + "-" * ($moduleHeading.Length-3) + "`n`n"
                    $docstring = ""
                } elseif ($_.Substring(88).StartsWith("*")) {
                    $docstring += $_.Substring(88) + "`n"
                } elseif ($docstring.Length -gt 0 -and $_ -match $entryRegex) {
                    $outString += $moduleHeading
                    $outString += $docstring
                    $outString += (([PSCustomObject]@{
                        label = $Matches[1]
                        op = "EQU"
                        addr = "$" + $_.Substring(67,4)
                    } | Format-Table -Property $format -HideTableHeaders | Out-String) -replace '(?m)^\s*\r?\n', '')
                    $outString += "`n"
                    $docstring = ""
                    $moduleHeading = ""
                } else {
                    $docstring = ""
                }
            }
        }
    }
    end {
        return $outString
    }
}

$vers = (Get-Content ./scripts/meta.json | ConvertFrom-Json).woz2.meta.version
(Get-Content ./build/dhrlib_*_Output.txt) | Convert-AssemblyToEquivalences -vers $vers > ./build/dhrlib.g.equ.S