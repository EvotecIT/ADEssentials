# Tests that the mail attribute flows through Get-WinADGroupMember / Get-WinADGroupMemberOf (issue #41).
# The functions under test are dot-sourced directly and Get-WinADObject is replaced with an in-memory
# graph, because Get-WinADObject is called module-internally and cannot be mocked across the module
# boundary. This protects the additive output contract when the membership functions change again.
BeforeAll {
    . "$PSScriptRoot\..\Public\Get-WinADGroupMember.ps1"
    . "$PSScriptRoot\..\Public\Get-WinADGroupMemberOf.ps1"

    function ConvertFrom-DistinguishedName {
        [CmdletBinding()] param($DistinguishedName, [switch] $ToDomainCN)
        'test.local'
    }
    function Get-WinADObject {
        [CmdletBinding()]
        param([Parameter(Position = 0)] $Identity, [switch] $IncludeGroupMembership)
        foreach ($Item in $Identity) {
            if ($Item -is [System.Management.Automation.PSObject] -and $Item.PSObject.Properties['DistinguishedName'] -and $Item.DistinguishedName) {
                $DN = $Item.DistinguishedName
            } else {
                $DN = "$Item"
                if (-not $Script:TestGraph.ContainsKey($DN)) {
                    $Found = $Script:TestGraph.Values | Where-Object { $_.Name -eq "$Item" } | Select-Object -First 1
                    if ($Found) { $DN = $Found.DistinguishedName }
                }
            }
            $Script:TestGraph[$DN]
        }
    }
    function Get-TestDN([string] $Name) { "CN=$Name,DC=test,DC=local" }
    function Add-TestObject {
        param([string] $Name, [string[]] $Members = @(), [string[]] $MemberOf = @(), [string] $Class = 'group', [string] $Mail = '')
        $Script:TestGraph[(Get-TestDN $Name)] = [PSCustomObject] @{
            Name              = $Name
            SamAccountName    = $Name
            DisplayName       = $Name
            Mail              = $Mail
            Enabled           = $true
            ObjectClass       = $Class
            GroupType         = 'Distribution'
            GroupScope        = 'Universal'
            DomainName        = 'test.local'
            DistinguishedName = (Get-TestDN $Name)
            ObjectSID         = "S-1-5-21-0-0-0-$Name"
            Members           = @(foreach ($MemberName in $Members) { Get-TestDN $MemberName })
            MemberOf          = @(foreach ($GroupName in $MemberOf) { Get-TestDN $GroupName })
        }
    }
    function Reset-TestState {
        # A mail-enabled universal DL containing a mail-enabled nested group, a mail user and a mail-less user
        $Script:TestGraph = @{}
        Add-TestObject -Name 'DL-All' -Members 'DL-Sub', 'Joe' -Mail 'dl-all@contoso.com'
        Add-TestObject -Name 'DL-Sub' -Members 'NoMailUser' -MemberOf 'DL-All' -Mail 'dl-sub@contoso.com'
        Add-TestObject -Name 'Joe' -MemberOf 'DL-All' -Class 'user' -Mail 'joe@contoso.com'
        Add-TestObject -Name 'NoMailUser' -MemberOf 'DL-Sub' -Class 'user'
        # Prime the module-level caches so the functions skip forest discovery and start clean per test
        $Script:WinADGroupMemberCache = @{}
        $Script:WinADGroupObjectCache = @{}
        $Script:WinADForestCache = @{ Forest = $null; Domains = @('test.local') }
    }
}

Describe 'Mail attribute in Get-WinADGroupMember output' {
    BeforeEach {
        Reset-TestState
    }
    It 'carries the mail of the queried group on the AddSelf row' {
        $Rows = Get-WinADGroupMember -Identity 'DL-All' -All -AddSelf
        $SelfRow = @($Rows | Where-Object { $_.Nesting -eq -1 })
        $SelfRow.Count | Should -Be 1
        $SelfRow[0].Mail | Should -Be 'dl-all@contoso.com'
    }
    It 'carries the mail of nested groups and users on their rows' {
        $Rows = Get-WinADGroupMember -Identity 'DL-All' -All
        @($Rows | Where-Object { $_.Name -eq 'DL-Sub' })[0].Mail | Should -Be 'dl-sub@contoso.com'
        @($Rows | Where-Object { $_.Name -eq 'Joe' })[0].Mail | Should -Be 'joe@contoso.com'
    }
    It 'leaves Mail empty for objects without the attribute' {
        $Rows = Get-WinADGroupMember -Identity 'DL-All' -All
        @($Rows | Where-Object { $_.Name -eq 'NoMailUser' })[0].Mail | Should -BeNullOrEmpty
    }
    It 'includes Mail in the users-only default output' {
        $Rows = Get-WinADGroupMember -Identity 'DL-All'
        @($Rows).Count | Should -Be 2
        $Rows[0].PSObject.Properties['Mail'] | Should -Not -BeNullOrEmpty
        @($Rows | Where-Object { $_.Name -eq 'Joe' })[0].Mail | Should -Be 'joe@contoso.com'
    }
}

Describe 'Mail attribute in Get-WinADGroupMemberOf output' {
    BeforeEach {
        Reset-TestState
    }
    It 'carries the mail of each parent group on its row' {
        $Rows = Get-WinADGroupMemberOf -Identity 'NoMailUser'
        @($Rows | Where-Object { $_.Name -eq 'DL-Sub' })[0].Mail | Should -Be 'dl-sub@contoso.com'
        @($Rows | Where-Object { $_.Name -eq 'DL-All' })[0].Mail | Should -Be 'dl-all@contoso.com'
    }
    It 'carries the mail of the queried object on the AddSelf row' {
        $Rows = Get-WinADGroupMemberOf -Identity 'Joe' -AddSelf
        $SelfRow = @($Rows | Where-Object { $_.Nesting -eq -1 })
        $SelfRow.Count | Should -Be 1
        $SelfRow[0].Mail | Should -Be 'joe@contoso.com'
    }
    It 'leaves Mail empty on the AddSelf row of a mail-less object' {
        $Rows = Get-WinADGroupMemberOf -Identity 'NoMailUser' -AddSelf
        $SelfRow = @($Rows | Where-Object { $_.Nesting -eq -1 })
        $SelfRow.Count | Should -Be 1
        $SelfRow[0].Mail | Should -BeNullOrEmpty
    }
}
