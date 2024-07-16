function Get-WinADDomain {
    <#
    .SYNOPSIS
    Retrieves information about a specified Active Directory domain.

    .DESCRIPTION
    This function retrieves detailed information about the specified Active Directory domain.
    It queries the domain to gather information such as domain controllers, domain name, and other domain-related details.

    .PARAMETER Domain
    Specifies the target domain to retrieve information from.

    .EXAMPLE
    Get-WinADDomain -Domain "example.com"

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires appropriate permissions to query the Active Directory domain.
    #>
    [cmdletBinding()]
    param(
        [string] $Domain
    )
    try {
        if ($Domain) {
            $Type = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain
            $Context = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new($Type, $Domain)
            $DomainInformation = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
        } else {
            $DomainInformation = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()
        }
    } catch {
        Write-Warning "Get-WinADDomain - Can't get $Domain information, error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
    }
    $DomainInformation
}