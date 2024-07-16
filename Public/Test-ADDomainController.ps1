function Test-ADDomainController {
    <#
    .SYNOPSIS
    Tests the domain controllers in a specified forest for various aspects of their functionality.

    .DESCRIPTION
    This cmdlet tests the domain controllers in a specified forest for various aspects of their functionality, including DNS resolution, LDAP connectivity, and FSMO role availability. It returns a custom object with detailed information about the domain controllers, their status, and any errors encountered during the test.

    .PARAMETER Forest
    The name of the forest to test domain controllers for. If not specified, the current user's forest is used.

    .PARAMETER ExcludeDomains
    An array of domain names to exclude from the test.

    .PARAMETER ExcludeDomainControllers
    An array of domain controller names to exclude from the test.

    .PARAMETER IncludeDomains
    An array of domain names to include in the test. If specified, only these domains will be tested.

    .PARAMETER IncludeDomainControllers
    An array of domain controller names to include in the test. If specified, only these domain controllers will be tested.

    .PARAMETER SkipRODC
    A switch to skip Read-Only Domain Controllers (RODCs) during the test.

    .PARAMETER Credential
    A PSCredential object to use for authentication when connecting to domain controllers.

    .PARAMETER ExtendedForestInformation
    A dictionary containing extended information about the forest, which can be used to speed up processing.

    .EXAMPLE
    Test-ADDomainController -Forest "example.com"

    .NOTES
    This cmdlet is useful for monitoring the health and functionality of domain controllers in a forest.
    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers', 'DomainController', 'ComputerName')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [Parameter(Mandatory = $false)][PSCredential] $Credential = $null,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )

    $CredentialParameter = @{ }
    if ($null -ne $Credential) {
        $CredentialParameter['Credential'] = $Credential
    }

    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    $Output = foreach ($Computer in $ForestInformation.ForestDomainControllers.HostName) {
        $Result = Invoke-Command -ComputerName $Computer -ScriptBlock {
            dcdiag.exe /v /c /Skip:OutboundSecureChannels
        } @CredentialParameter

        for ($Line = 0; $Line -lt $Result.length; $Line++) {
            # Correct wrong line breaks
            if ($Result[$Line] -match '^\s{9}.{25} (\S+) (\S+) test$') {
                $Result[$Line] = $Result[$Line] + ' ' + $Result[$Line + 2].Trim()
            }
            # Verify test start line
            if ($Result[$Line] -match '^\s{6}Starting test: \S+$') {
                $LineStart = $Line
            }
            # Verify test end line
            if ($Result[$Line] -match '^\s{9}.{25} (\S+) (\S+) test (\S+)$') {
                $DiagnosticResult = [PSCustomObject] @{
                    ComputerName = $Computer
                    #Domain       = $Domain
                    Target       = $Matches[1]
                    Test         = $Matches[3]
                    Result       = $Matches[2] -eq 'passed'
                    Data         = $Result[$LineStart..$Line] -join [System.Environment]::NewLine
                }
                $DiagnosticResult
            }
        }
    }
    $Output
}