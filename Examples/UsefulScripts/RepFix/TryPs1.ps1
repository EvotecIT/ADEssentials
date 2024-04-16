
function Get-WinADConfigurationSettings {
    [CmdletBinding()]
    param()
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    $QueryServer = $ForestInformation.QueryServers[$($ForestInformation.Forest.Name)]['HostName'][0]
    $ForestDN = ConvertTo-DistinguishedName -ToDomain -CanonicalName $ForestInformation.Forest.Name

    $getADObjectSplat = @{
        Server     = $QueryServer

        Identity   = "CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,$($($ForestDN))"
        Properties = "*" #'Name', 'distinguishedName', 'CanonicalName', 'WhenCreated', 'whenchanged', 'ProtectedFromAccidentalDeletion', 'siteObject', 'location', 'objectClass', 'Description'
    }
    Write-Verbose -Message "Get-WinADConfigurationSettings - Querying $($getADObjectSplat.Identity) on $QueryServer"

    $Objects = Get-ADObject @getADObjectSplat -ErrorAction Stop
    $Objects
}

function Set-WinADConfigurationSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('EnableHeuristics', 'DisableHeuristics')]
        [string] $Value
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    $QueryServer = $ForestInformation.QueryServers[$($ForestInformation.Forest.Name)]['HostName'][0]
    $ForestDN = ConvertTo-DistinguishedName -ToDomain -CanonicalName $ForestInformation.Forest.Name

    Write-Verbose -Message "Set-WinADConfigurationSettings - Setting $Value on $QueryServer"
    if ($Value -eq 'EnableHeuristics') {
        Set-ADObject -Identity "CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,$($($ForestDN))" -Clear 'dsHeuristics' -Server $QueryServer
        Set-ADObject -Identity "CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,$($($ForestDN))" -Add @{ dsHeuristics = "00000000011" } -Server $QueryServer
    } elseif ($Value -eq 'DisableHeuristics') {
        Set-ADObject -Identity "CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,$($($ForestDN))" -Clear 'dsHeuristics' -Server $QueryServer
    }
}


function New-WinADRecoveryObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $DistinguishedName,
        [Parameter(Mandatory)][string] $Server,
        [Parameter(Mandatory)][string] $TargetOrganizationalUnit,
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string] $OutputFilePath
    )
    $BadObject = Get-ADObject -Identity $DistinguishedName -Server $Server
    if ($BadObject) {
        $GUID = [guid]::new($BadObject.ObjectGUID.Guid)
        $ObjectGUID = [System.Convert]::ToBase64String($GUID.toByteArray())

        @("dn: CN=$Name,$TargetOrganizationalUnit"
            "changetype: add"
            "objectClass: user"
            "objectGUID:: $ObjectGUID"
        ) | Out-File -FilePath "$OutputFilePath\$Name.ldif" -Encoding default -Force

        Write-Verbose "New-WinADRecoveryObject - Created $OutputFilePath\$Name.ldif"
        Write-Verbose "New-WinADRecoveryObject - You can use it: ldifde /i /f $OutputFilePath\$Name.ldif"
    }
}

Get-WinADConfigurationSettings | Format-Table

Set-WinADConfigurationSettings -Value EnableHeuristics -verbose

Get-WinADConfigurationSettings | Format-Table

Set-WinADConfigurationSettings -Value DisableHeuristics -verbose

Get-WinADConfigurationSettings | Format-Table

#New-WinADRecoveryObject -DistinguishedName "CN=Przemysław Kłys,OU=Default,OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz" -TargetOrganizationalUnit "OU=Temporary,DC=ad,DC=evotec,DC=xyz" -Name "Cleanup-PrzemyslawwKlys" -OutputFilePath "C:\Support\GitHub\ADEssentials\Examples\UsefulScripts\RepFix" -Verbose

#Set-WinADConfigurationSettings -Value DisableHeuristics
