# Variables relating to HTML output using the PsWriteHtml Module
$ReportTitle = "Groups and their Members"
$DashboardName = 'Some Dashboard Name'
$BackGroundColor = 'DarkCerulean'
$ForeGroundColor = 'White'
$FontSize = 22
$FontFamily = 'Arial'
$FontVariant = 'small-caps'
$TableStyleFontSize = 16
$TableHeaderAlignment = 'center'
$TableStyleTextAlignment = 'left'
$TableStyle = 'stripe'

Dashboard -Name $DashboardName -FilePath $OutputFile -Online {
    Panel {
        $tableSplat = @{
            DataTable      = $arrayResults
            ScrollCollapse = $true
            FixedHeader    = $true
            HideButtons    = $true
            DisablePaging  = $true
            Style          = $TableStyle
            HideFooter     = $true
            HTML           = {
                $tableStyleSplat = @{
                    Type      = 'Table'
                    FontSize  = $TableStyleFontSize
                    TextAlign = $TableStyleTextAlignment
                }

                TableStyle @tableStyleSplat

                $tableHeaderSplat = @{
                    BackGroundColor = $BackGroundColor
                    FontSize        = $FontSize
                    Color           = $ForeGroundColor
                    Title           = $ReportTitle
                    FontFamily      = $FontFamily
                    FontVariant     = $FontVariant
                    Alignment       = $TableHeaderAlignment
                }

                TableHeader @tableHeaderSplat
            }
        }

        Table @tableSplat
    }
}