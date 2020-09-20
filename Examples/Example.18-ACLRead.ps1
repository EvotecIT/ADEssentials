Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

function Get-WinADForestAccessList {
    [cmdletBinding()]
    param(
        [string] $Forest,
        [alias('Domain')][string[]] $IncludeDomains,
        [string[]] $ExcludeDomains,
        [string] $FolderPath,
        [switch] $SameWorksheet,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation -Extended

    foreach ($Domain in $ForestInformation.Domains) {
        if (-not $SameWorksheet) {
            $FilePath = [System.IO.Path]::Combine($FolderPath, "$($Domain)_ACLOutput.xlsx")
        } else {
            $FilePath = [System.IO.Path]::Combine($FolderPath, "$($ForestInformation.Forest)_ACLOutput.xlsx")
        }
        $Server = $ForestInformation.QueryServers[$Domain].HostName[0]
        $DomainStructure = @(
            Get-ADObject -Filter * -Properties canonicalName -SearchScope Base -Server $Server
            Get-ADObject -Filter * -Properties canonicalName -SearchScope OneLevel -Server $Server
        )
        $DomainStructure = $DomainStructure | Sort-Object -Property canonicalName
        $PermissionsDomain = foreach ($Structure in $DomainStructure) {
            if ($Structure.ObjectClass -eq 'organizationalUnit') {
                $Containers = Get-ADOrganizationalUnit -Filter '*' -Server $Server -SearchBase $Structure.DistinguishedName -Properties canonicalName
            } elseif ($Structure.ObjectClass -eq 'domainDNS') {
                $Containers = $Structure
            } elseif ($Structure.ObjectClass -eq 'container') {
                $Ignore = @(
                    # lets ignore GPO, we deal with it in GPOZaurr
                    -join ('*CN=Policies,CN=System,', $ForestInformation['DomainsExtended'][$DOmain].DistinguishedName)
                )
                #$Containers = Get-ADObject -SearchBase $Structure.DistinguishedName -Filter { ObjectClass -eq 'container' } -Properties canonicalName -Server $Server -SearchScope Subtree
                $Containers = Get-ADObject -SearchBase $Structure.DistinguishedName -Filter * -Properties canonicalName -Server $Server -SearchScope Subtree | ForEach-Object {
                    foreach ($I in $Ignore) {
                        if ($_.DistinguishedName -notlike $I) {
                            $_
                        }
                    }
                } | Sort-Object canonicalName
            } else {
                continue
            }
            $MYACL = Get-ADACL -ADObject $Containers -Verbose -NotInherited -ResolveTypes
            if ($SameWorksheet -eq $false) {
                $MyACL | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName $Structure.Name -AutoFilter -AutoFit -FreezeTopRowFirstColumn
            } else {
                $MYACL
            }
        }
        if ($SameWorksheet -eq $true) {
            $PermissionsDomain | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName $Domain -AutoFilter -AutoFit -FreezeTopRowFirstColumn
        }
    }

}

Get-WinADForestAccessList -FolderPath $Env:USERPROFILE\Desktop -SameWorksheet:$false

<#
$CsvFile = @(
    [PSCustomObject] @{
        Parameter = 'ADOrganizationName'; Value = 'test'
    }
    [PSCustomObject] @{
        Parameter = 'AzureNS1'; Value = 'test2'
    }
)
$Variable = [ordered]@{}
foreach ($A in $CsvFile) {
    $Variable[$($A.Parameter)] = $A.Value
}

$Variable['ADOrganizationName']
$Variable['AzureNS1']
#>