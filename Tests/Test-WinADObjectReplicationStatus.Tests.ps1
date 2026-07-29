# Regression tests for Test-WinADObjectReplicationStatus DC selection (PR #84).
# The previous defect read $ObjectInformation.Domain (a property Get-WinADObject never emits, the key
# is DomainName), so the non-GlobalCatalog path matched zero domain controllers and returned an empty
# result WITHOUT throwing - exactly the failure mode a test must guard against. The function is
# dot-sourced with stubbed directory commands: a two-domain forest with two DCs per domain and the
# object living in the child domain.
BeforeAll {
    . "$PSScriptRoot\..\Public\Test-WinADObjectReplicationStatus.ps1"

    function Get-WinADObject {
        [CmdletBinding()] param([Parameter(Position = 0)] $Identity)
        [PSCustomObject] @{
            Name              = 'TestUser'
            SamAccountName    = 'TestUser'
            DomainName        = 'child.test.local'   # Get-WinADObject emits DomainName - there is no Domain property
            DistinguishedName = 'CN=TestUser,DC=child,DC=test,DC=local'
            ObjectClass       = 'user'
        }
    }
    function Get-WinADForestDetails {
        [CmdletBinding()] param([switch] $Extended, [switch] $PreferWritable)
        [PSCustomObject] @{
            ForestDomainControllers = @(
                [PSCustomObject] @{ HostName = 'dc1.test.local'; Domain = 'test.local'; IsGlobalCatalog = $true }
                [PSCustomObject] @{ HostName = 'dc2.test.local'; Domain = 'test.local'; IsGlobalCatalog = $false }
                [PSCustomObject] @{ HostName = 'dc1.child.test.local'; Domain = 'child.test.local'; IsGlobalCatalog = $true }
                [PSCustomObject] @{ HostName = 'dc2.child.test.local'; Domain = 'child.test.local'; IsGlobalCatalog = $false }
            )
        }
    }
    function Get-ADObject {
        [CmdletBinding()] param($Identity, $Server, $Properties)
        $Script:QueriedServers.Add($Server)
        [PSCustomObject] @{
            userAccountCOntrol = 512
            Created            = [datetime] '2026-01-01'
            uSNChanged         = 100
            uSNCreated         = 50
            whenCreated        = [datetime] '2026-01-01'
            WhenChanged        = [datetime] '2026-06-01'
        }
    }
}

Describe 'Test-WinADObjectReplicationStatus DC selection' {
    BeforeEach {
        $Script:QueriedServers = [System.Collections.Generic.List[string]]::new()
    }
    It 'queries every writable DC of the object''s own domain without -GlobalCatalog' {
        $Results = Test-WinADObjectReplicationStatus -Identity 'TestUser'
        # The pre-fix code selected zero DCs here and returned nothing, silently
        @($Results).Count | Should -Be 2
        $Script:QueriedServers.Count | Should -Be 2
        $Script:QueriedServers | Should -Contain 'dc1.child.test.local'
        $Script:QueriedServers | Should -Contain 'dc2.child.test.local'
    }
    It 'does not query domain controllers from other domains' {
        $null = Test-WinADObjectReplicationStatus -Identity 'TestUser'
        $Script:QueriedServers | Should -Not -Contain 'dc1.test.local'
        $Script:QueriedServers | Should -Not -Contain 'dc2.test.local'
    }
    It 'returns rows that carry the object''s domain and data from each DC' {
        $Results = Test-WinADObjectReplicationStatus -Identity 'TestUser'
        @($Results | Where-Object { $_.Domain -eq 'child.test.local' }).Count | Should -Be 2
        @($Results | Where-Object { $null -ne $_.WhenChanged }).Count | Should -Be 2
        ($Results.Error | Where-Object { $_ }) | Should -BeNullOrEmpty
    }
    It 'still queries all global catalogs on port 3268 with -GlobalCatalog' {
        $Results = Test-WinADObjectReplicationStatus -Identity 'TestUser' -GlobalCatalog
        @($Results).Count | Should -Be 2
        $Script:QueriedServers.Count | Should -Be 2
        $Script:QueriedServers | Should -Contain 'dc1.test.local:3268'
        $Script:QueriedServers | Should -Contain 'dc1.child.test.local:3268'
    }
}
