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
        $moduleRegex =  '^.+\|.+\|.+\|.+\|.+\|.+\|.+\|\s+(DSK|dsk)\s+(\S+)'
        $commentRegex = '^.+\|.+\|.+\|.+\|.+\|.+\|.+\|\s*(\*.*)'
        $entryRegex =   '^.+\|.+\|.+\|.+\|.+\|.+\|\s*00/([0-9A-F]+).*\|\s*(\S+)\s+(ENT|ent)(\s+|$)'
        $format = @(@{Expression='label'; width=9}, @{Expression='op'; width=6}, @{Expression='addr'})
        $outString = "* DHRLIB Header File`n"
        $outString += "* ------------------`n`n"
        $outString += "* To use DHRLIB with Merlin you will likely want to PUT both`n"
        $outString += "* equiv.S and this file. You may want to modify equiv.S to use`n"
        $outString += "* your own conventions for ROM and ZP locations, and modify the`n"
        $outString += "* docstrings herein to be consistent.`n`n"
        $tempString = "* DHRLIB " + $vers + " Entry Points`n"
        $outString += $tempString + "* " + "-" * ($tempString.Length-3) + "`n`n"
        $moduleHeading = ""
        $docstring = ""
    }
    process {
        # this loop is over all the lines from all the sources
        $inLines | ForEach-Object {
            if ($_ -match $moduleRegex) {
                $moduleHeading = "* Entries from Module " + $Matches[2] + "`n"
                $moduleHeading += "* " + "-" * ($moduleHeading.Length-3) + "`n`n"
                $docstring = ""
            } elseif ($_ -match $commentRegex) {
                $docstring += $Matches[1] + "`n"
            } elseif ($docstring.Length -gt 0 -and $_ -match $entryRegex) {
                $outString += $moduleHeading
                $outString += $docstring
                $outString += (([PSCustomObject]@{
                    label = $Matches[2]
                    op = "EQU"
                    addr = "$" + $Matches[1]
                } | Format-Table -Property $format -HideTableHeaders | Out-String) -replace '(?m)^\s*\r?\n', '')
                $outString += "`n"
                $docstring = ""
                $moduleHeading = ""
            } else {
                $docstring = ""
            }
        }
    }
    end {
        return $outString
    }
}

$vers = (Get-Content ./scripts/meta.json | ConvertFrom-Json).woz2.meta.version
(Get-Content ./build/dhrlib_*_Output.txt) | Convert-AssemblyToEquivalences -vers $vers > ./build/dhrlib.g.equ.S