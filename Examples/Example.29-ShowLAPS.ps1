Import-Module .\ADEssentials.psd1 -Force

#Show-WinADBitlockerLaps -FilePath $PSScriptRoot\Reports\LAPSBitlocker.html

#(Total enabled computers with LAPS/Total Enabled Computers)*100 = % of computers with LAPS
#$LAPS = Get-WinADBitlockerLapsSummary -LapsOnly

function Get-SummaryLaps {
    [cmdletBinding()]
    param(
        [Array] $Computers
    )

    $Today = Get-Date
    $Summary = [ordered] @{
        $Today = [ordered] @{}
    }

    foreach ($Computer in $Computers) {
        if ($Computer.Enabled) {
            $Summary[$Today].Enabled++
        }
        if ($Computer.Enabled -and $Computer.LAPS) {
            $Summary[$Today].EnabledWithLAPS++

            if ($Computer.LapsExpirationDays -lt -360) {
                $Summary[$Today].LapsExpiredOver360++
            }
            if ($Computer.LapsExpirationDays -lt -180) {
                $Summary[$Today].LapsExpiredOver180++
            }

        } elseif ($Computer.Enabled) {
            $Summary[$Today].EnabledWithoutLAPS++
        }
    }

    if ($Summary[0]['Enabled']) {
        $Summary[0]['PercentageComputersWithLAPS'] = $Summary[0]['EnabledWithLAPS'] / $Summary[0]['Enabled'] * 100
    }
    if ($Summary[0]['LapsExpiredOver180']) {
        $Summary[0]['PercentageComputersWithExpiredLAPS180'] = $Summary[0]['EnabledWithLAPS'] / $Summary[0]['LapsExpiredOver180'] * 100
    } else {
        $Summary[0]['PercentageComputersWithExpiredLAPS180'] = 0
    }
    if ($Summary[0]['LapsExpiredOver360']) {
        $Summary[0]['PercentageComputersWithExpiredLAPS360'] = $Summary[0]['EnabledWithLAPS'] / $Summary[0]['LapsExpiredOver360'] * 100
    } else {
        $Summary[0]['PercentageComputersWithExpiredLAPS360'] = 0
    }
    $Summary
}

$Summary = Get-SummaryLaps -Computers $LAPS
#$Summary[0] | Format-Table Key, Value

Start-Sleep -Seconds 3

$Summary1 = Get-SummaryLaps -Computers $LAPS
#$Summary1[0] | Format-Table Key, Value



$Summary + $Summary1 | Format-Table *