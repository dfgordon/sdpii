# PowerShell script to generate a header file for DHRLIB.
# This expects the Merlin32 output files to be in the build directory, and should work for any configuration of DHRLIB.
# Normally run as part of build.

#Requires -Version 7.4

function Convert-AssemblyToEquivalences {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$inList
    )

    begin {
        $entryRegex = '^.{88}(\S+)\s+(ENT|ent)(\s+|$)'
        $format = @(@{Expression='label'; width=9}, @{Expression='op'; width=6}, @{Expression='addr'})
        $outString = ""
        $docstring = ""
    }
    process {
        $inList | ForEach-Object {
            if ($_.Length -gt 88) {
                if ($_.Substring(88).StartsWith("*")) {
                    $docstring += $_.Substring(88) + [System.Environment]::NewLine
                }
                elseif ($docstring.Length -gt 0 -and $_ -match $entryRegex) {
                    $outString += $docstring
                    $outString += (([PSCustomObject]@{
                        label = $Matches[1]
                        op = "EQU"
                        addr = "$" + $_.Substring(67,4)
                    } | Format-Table -Property $format -HideTableHeaders | Out-String) -replace '(?m)^\s*\r?\n', '')
                    $outString += [System.Environment]::NewLine
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

(Get-Content ./build/dhrlib_*_Output.txt) | Convert-AssemblyToEquivalences > ./build/dhrlib.equ.S