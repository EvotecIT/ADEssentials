$DataSet = [ordered]@{}
$DataSet['Summary'] = @{}
$DataSet['Summary']['Groups'] = 0
$DataSet['Summary']['Users'] = 0
$DataSet['Summary']['Computers'] = 0
$DataSet['Summary']['GPO'] = 0
$ForestInformation = Get-WinADForestDetails -Extended

foreach ($Domain in $ForestInformation.Domains) {
    $DataSet['SummaryPerDomain'] = [ordered] @{}
    $DataSet['SummaryPerDomain'][$Domain] = [ordered] @{}
    $DataSet[$Domain] = [ordered] @{}
    $DataSet[$Domain]['Groups'] = Get-ADGroup -Filter * -Server $ForestInformation['QueryServers'][$Domain]['Hostname'][0] | ForEach-Object {
        [PSCustomObject] @{
            Name              = $_.Name
            DomainName        = $Domain
            DistinguishedName = $_.DistinguishedName
            GroupCategory     = $_.GroupCategory
            GroupScope        = $_.GroupScope
            Enabled           = $_.Enabled
            ObjectGUID        = $_.ObjectGUID.GUID
            SamAccountName    = $_.SamAccountName
            SID               = $_.SID.Value
        }
    }
    $DataSet[$Domain]['Users'] = Get-ADUser -Filter * -Server $ForestInformation['QueryServers'][$Domain]['Hostname'][0] | ForEach-Object {
        [PSCustomObject] @{
            Name              = $_.Name
            DomainName        = $Domain
            UserPrincipalName = $_.UserPrincipalName
            Enabled           = $_.Enabled
            DistinguishedName = $_.DistinguishedName
            SamAccountName    = $_.SamAccountName
            ObjectGUID        = $_.ObjectGUID.GUID
            SID               = $_.SID.Value
        }
    }
    $DataSet[$Domain]['Computers'] = Get-ADComputer -Filter * -Server $ForestInformation['QueryServers'][$Domain]['Hostname'][0] | ForEach-Object {
        [PSCustomObject] @{
            Name              = $_.Name
            DomainName        = $Domain
            DNSHostName       = $_.DNSHostName
            Enabled           = $_.Enabled
            DistinguishedName = $_.DistinguishedName
            SamAccountName    = $_.SamAccountName
            ObjectGUID        = $_.ObjectGUID.GUID
            SID               = $_.SID.Value
        }
    }
    $DataSet[$Domain]['GPO'] = Get-GPO -All -Domain $Domain | ForEach-Object {
        [PSCustomObject] @{
            Name       = $_.DisplayName
            DomainName = $_.DomainName
            GpoStatus  = $_.GpoStatus
            Id         = $_.Id
        }
    }
    $DataSet['SummaryPerDomain'][$Domain]['Groups'] = $DataSet[$Domain]['Groups'].Count
    $DataSet['SummaryPerDomain'][$Domain]['Users'] = $DataSet[$Domain]['Users'].Count
    $DataSet['SummaryPerDomain'][$Domain]['Computers'] = $DataSet[$Domain]['Computers'].Count
    $DataSet['SummaryPerDomain'][$Domain]['GPO'] = $DataSet[$Domain]['GPO'].Count

    $DataSet['Summary']['Groups'] = + $DataSet[$Domain]['Groups'].Count
    $DataSet['Summary']['Users'] = + $DataSet[$Domain]['Users'].Count
    $DataSet['Summary']['Computers'] = + $DataSet[$Domain]['Computers'].Count
    $DataSet['Summary']['GPO'] = + $DataSet[$Domain]['GPO'].Count
}
foreach ($Domain in $ForestInformation.Domains) {
    foreach ($Type in $DataSet[$Domain].Keys) {

    }
}

# Export
$FilePath = "$PSScriptRoot\Example.24.xlsx"
foreach ($Domain in $ForestInformation.Domains) {
    foreach ($Type in $DataSet[$Domain].Keys) {
        #ConvertTo-Excel -FilePath $FilePath -AutoFilter -AutoFit -ExcelWorkSheetName "$($Type)_$($Domain)" -DataTable $DataSet[$Domain][$Type]
    }
}