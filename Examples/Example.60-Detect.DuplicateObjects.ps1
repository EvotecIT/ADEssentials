Import-Module .\ADEssentials.psd1 -Force

#Get-WinADDuplicateObject -Verbose

$ForestInformation = Get-WinADForestDetails -PreferWritable
$NamingContext = @(
    $Root = Get-ADRootDSE
    [PSCustomObject] @{
        NC       = $Root.configurationNamingContext
        DomainDN = $Root.defaultNamingContext
        Domain   = ConvertFrom-DistinguishedName -DistinguishedName $Root.defaultNamingContext -ToDomainCN
        DC       = $ForestInformation['QueryServers']['Forest'].HostName[0]
    }

    #$Root.schemaNamingContext

    $Forest = Get-ADForest
    #Forest.ApplicationPartitions
    foreach ($Domain in $Forest.Domains) {
        $DomainInformation = Get-ADDomain -Server $Domain
        #$DomainInformation.SubordinateReferences
        #$DomainInformation.DistinguishedName
        $DomainInformation.SubordinateReferences | ForEach-Object {
            if ($_.StartsWith("DC=ForestDnsZones")) {
                continue
            } elseif ($_.StartsWith("DC=DomainDnsZones")) {
                $TempValue = $_ -replace "DC=DomainDnsZones,", ""
                $DomainCN = ConvertFrom-DistinguishedName -DistinguishedName $TempValue -ToDomainCN
                [PSCustomObject] @{
                    NC       = $_
                    DomainDN = $DomainInformation.DistinguishedName
                    Domain   = $DomainCN
                    DC       = $ForestInformation['QueryServers'][$DomainCN].HostName[0]
                }
            } else {
                [PSCustomObject] @{
                    NC       = $_
                    DomainDN = $DomainInformation.DistinguishedName
                    Domain   = $Domain
                    DC       = $ForestInformation['QueryServers'][$Domain].HostName[0]
                }
            }
        }
        [PSCustomObject] @{
            NC       = $DomainInformation.DistinguishedName
            DomainDN = $DomainInformation.DistinguishedName
            Domain   = $Domain
            DC       = $ForestInformation['QueryServers'][$Domain].HostName[0]
        }
    }
)

$NamingContext = $NamingContext | Sort-Object -Unique -Property NC
$NamingContext

return

$Summary = [ordered] @{}
foreach ($NC in $NamingContext) {
    $DC = $NC.Domain

    $getADObjectSplat = @{
        LDAPFilter  = "(|(cn=*\0ACNF:*)(ou=*CNF:*))"
        Properties  = 'DistinguishedName', 'ObjectClass', 'DisplayName', 'SamAccountName', 'Name', 'ObjectCategory', 'WhenCreated', 'WhenChanged', 'ProtectedFromAccidentalDeletion', 'ObjectGUID'
        Server      = $DC
        SearchScope = 'Subtree'
        SearchBase  = $NC.NC
        #Filter      = "*"
    }

    $Converted = ConvertFrom-DistinguishedName -DistinguishedName $NC
    $Converted

    Write-Color -Text "Processing $($NC.NC) ", "on", " $($NC.DC)" -Color Green
    $Summary[$NC.NC] = Get-ADObject @getADObjectSplat
    $Summary[$NC.NC].Count
}
