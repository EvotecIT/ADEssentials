function Compare-PingCastleReport {
    [CmdletBinding()]
    param(
        [string] $FilePathBefore,
        [string] $FilePathAfter,
        [ValidateSet("Points", "Rationale", "Points&Rationale", "Same", "New", "Removed", "All")]
        [string[]] $Status,
        [switch] $Advanced
    )
    $PingCastleOutput1 = Get-PingCastleReport -FilePath $FilePathBefore
    $PingCastleOutput2 = Get-PingCastleReport -FilePath $FilePathAfter

    if (-not $PingCastleOutput1 -or -not $PingCastleOutput2) {
        Write-Warning -Message "Compare-PingCastleReport - One of the reports is missing. Cannot compare. "
        return
    }
    if ($PingCastleOutput1.DomainName -ne $PingCastleOutput2.DomainName) {
        Write-Warning -Message "Compare-PingCastleReport - Domains are different. Cannot compare. "
        return
    }
    $Summary = @(
        # find differences
        foreach ($RiskID in $PingCastleOutput1.RisksIds.Keys) {
            $Risk1 = $PingCastleOutput1.RisksIds[$RiskID]
            $Risk2 = $PingCastleOutput2.RisksIds[$RiskID]
            if ($Risk1.Points -ne $Risk2.Points -or $Risk1.Rationale -ne $Risk2.Rationale) {
                [PSCustomObject] @{
                    DomainName      = $PingCastleOutput1.DomainName
                    RiskId          = $RiskID
                    Category        = $Risk2.Category
                    DateDifference  = ($PingCastleOutput2.DateScan - $PingCastleOutput1.DateScan).Days
                    Status          = if ($Risk1.Points -ne $Risk2.Points -and $Risk1.Rationale -ne $Risk2.Rationale) {
                        "Points&Rationale"
                    } elseif ($Risk1.Points -ne $Risk2.Points) {
                        "Points"
                    } else {
                        "Rationale"
                    }
                    PointsBefore    = $Risk1.Points
                    PointsAfter     = $Risk2.Points
                    PointsDiff      = $Risk2.Points - $Risk1.Points
                    RationaleBefore = $Risk1.Rationale
                    RationaleAfter  = $Risk2.Rationale
                }
            } else {
                [PSCustomObject] @{
                    DomainName      = $PingCastleOutput1.DomainName
                    RiskId          = $RiskID
                    Category        = $Risk1.Category
                    DateDifference  = ($PingCastleOutput2.DateScan - $PingCastleOutput1.DateScan).Days
                    Status          = "Same"
                    PointsBefore    = $Risk1.Points
                    PointsAfter     = $Risk2.Points
                    PointsDiff      = 0
                    RationaleBefore = $Risk1.rationale
                    RationaleAfter  = $Risk2.Rationale
                }
            }
        }
        # find if there are any new risks
        foreach ($RiskID in $PingCastleOutput2.RisksIds.Keys) {
            $Risk1 = $PingCastleOutput1.RisksIds[$RiskID]
            $Risk2 = $PingCastleOutput2.RisksIds[$RiskID]
            if (-not $Risk1) {
                [PSCustomObject] @{
                    DomainName      = $PingCastleOutput1.DomainName
                    RiskId          = $RiskID
                    Category        = $Risk2.Category
                    DateDifference  = ($PingCastleOutput2.DateScan - $PingCastleOutput1.DateScan).Days
                    Status          = "New"
                    PointsBefore    = 0
                    PointsAfter     = $Risk2.Points
                    PointsDiff      = $Risk2.Points
                    RationaleBefore = ""
                    RationaleAfter  = $Risk2.Rationale
                }
            }
        }
        # find if there are any removed risks
        foreach ($RiskID in $PingCastleOutput1.RisksIds.Keys) {
            $Risk1 = $PingCastleOutput1.RisksIds[$RiskID]
            $Risk2 = $PingCastleOutput2.RisksIds[$RiskID]
            if (-not $Risk2) {
                [PSCustomObject] @{
                    DomainName      = $PingCastleOutput1.DomainName
                    RiskId          = $RiskID
                    Category        = $Risk1.Category
                    DateDifference  = ($PingCastleOutput2.DateScan - $PingCastleOutput1.DateScan).Days
                    Status          = "Removed"
                    PointsBefore    = $Risk1.Points
                    PointsAfter     = 0
                    PointsDiff      = 0 - $Risk1.Points
                    RationaleBefore = $Risk1.Rationale
                    RationaleAfter  = ""
                }
            }

        }
    )
    if ($null -eq $Status -or $Status -contains "All") {
        $SummaryOutput = $Summary | Sort-Object -Property Category, RiskId
    } else {
        $SummaryOutput = foreach ($Item in $Summary) {
            if ($Status -contains $Item.Status) {
                $Item
            }
        }
    }

    # Summary per category
    $SummaryPerCategory = @(
        foreach ($Category in $PingCastleOutput1.Categories.Keys) {
            $Category1 = $PingCastleOutput1.Categories[$Category]
            $Category2 = $PingCastleOutput2.Categories[$Category]
            $Points1 = $Category1 | Measure-Object -Sum Points
            $Points2 = $Category2 | Measure-Object -Sum Points

            $NewRisks = [System.Collections.Generic.List[object]]::new()
            $RemovedRisks = [System.Collections.Generic.List[object]]::new()
            $SameRisks = [System.Collections.Generic.List[object]]::new()
            $ChangedRisks = [System.Collections.Generic.List[object]]::new()

            # Lets find "New" and "Removed" risks
            foreach ($Risk in $SummaryOutput) {
                if ($Risk.Category -eq $Category) {
                    if ($Risk.Status -eq "New") {
                        $NewRisks.Add($Risk)
                    } elseif ($Risk.Status -eq "Removed") {
                        $RemovedRisks.Add($Risk)
                    } elseif ($Risk.Status -eq "Same") {
                        $SameRisks.Add($Risk)
                    } else {
                        $ChangedRisks.Add($Risk)
                    }
                }
            }

            [PSCustomObject] @{
                DomainName     = $PingCastleOutput1.DomainName
                Category       = $Category
                DateDifference = ($PingCastleOutput2.DateScan - $PingCastleOutput1.DateScan).Days
                PointsBefore   = $Points1.Sum
                PointsAfter    = $Points2.Sum
                PointsDiff     = $Points2.Sum - $Points1.Sum
                NewRisks       = $NewRisks
                RemovedRisks   = $RemovedRisks
                ChangedRisks   = $ChangedRisks
                SameRisks      = $SameRisks
            }

        }
    )

    if ($Advanced) {
        [ordered] @{
            Summary            = $SummaryOutput
            SummaryPerCategory = $SummaryPerCategory
        }
    } else {
        $SummaryOutput
    }
}