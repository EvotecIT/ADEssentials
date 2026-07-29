# Tests for the CustomIcons feature (issue #35): pattern resolution in Get-WinADCustomDiagramIcon and
# propagation through Show-WinADGroupMember / Show-WinADGroupMemberOf into the diagram builders.
# Functions are dot-sourced with the PSWriteHTML surface stubbed - New-DiagramNode records every node it
# is asked to draw, scriptblock-hosting commands simply execute their content, everything else is a no-op.
BeforeAll {
    . "$PSScriptRoot\..\Private\Configuration.Icons.ps1"
    . "$PSScriptRoot\..\Private\Get-WinADCustomDiagramIcon.ps1"
    . "$PSScriptRoot\..\Private\New-HTMLGroupDiagramDefault.ps1"
    . "$PSScriptRoot\..\Private\New-HTMLGroupDiagramHierachical.ps1"
    . "$PSScriptRoot\..\Private\New-HTMLGroupOfDiagramDefault.ps1"
    . "$PSScriptRoot\..\Private\New-HTMLGroupOfDiagramHierarchical.ps1"
    . "$PSScriptRoot\..\Public\Show-WinADGroupMember.ps1"
    . "$PSScriptRoot\..\Public\Show-WinADGroupMemberOf.ps1"
    . "$PSScriptRoot\..\Public\Get-WinADGroupMemberOf.ps1"

    $Script:OriginalHTMLIcons = $Global:HTMLIcons

    # --- PSWriteHTML stubs: execute nested scriptblocks, record diagram nodes, ignore the rest ---
    function New-HTML { foreach ($Arg in $args) { if ($Arg -is [scriptblock]) { & $Arg } } }
    function New-HTMLHeader { foreach ($Arg in $args) { if ($Arg -is [scriptblock]) { & $Arg } } }
    function New-HTMLSection { foreach ($Arg in $args) { if ($Arg -is [scriptblock]) { & $Arg } } }
    function New-HTMLTab { foreach ($Arg in $args) { if ($Arg -is [scriptblock]) { & $Arg } } }
    function New-HTMLTable { foreach ($Arg in $args) { if ($Arg -is [scriptblock]) { & $Arg } } }
    function New-HTMLDiagram { foreach ($Arg in $args) { if ($Arg -is [scriptblock]) { & $Arg } } }
    function New-HTMLText { }
    function New-HTMLSectionStyle { }
    function New-HTMLTableOption { }
    function New-HTMLTabStyle { }
    function New-TableHeader { }
    function New-TableCondition { }
    function New-DiagramOptionsLayout { }
    function New-DiagramOptionsPhysics { }
    function New-DiagramLink { }
    function New-DiagramEvent { }
    function New-DiagramNode {
        param(
            $Id, $Label, $Image, $Level, $ColorBorder,
            $IconSolid, $IconRegular, $IconBrands, $IconColor,
            [switch] $ArrowsToEnabled
        )
        $Script:CapturedNodes.Add([PSCustomObject] @{
                Label      = "$Label" -split "`n" | Select-Object -First 1
                Image      = $Image
                IconSolid  = $IconSolid
                IconBrands = $IconBrands
                IconColor  = $IconColor
            })
    }
    # --- Non-PSWriteHTML dependencies of the Show functions ---
    function Get-GitHubVersion { '1.0.0' }
    function Get-FileName { [System.IO.Path]::GetTempFileName() }
    function Convert-DomainFqdnToNetBIOS { 'TEST' }
    function Get-RandomStringName { 'teststring' }
    function ConvertFrom-DistinguishedName { [CmdletBinding()] param($DistinguishedName, [switch] $ToDomainCN) 'test.local' }
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
    function New-TestRow {
        # Row shaped like Get-WinADGroupMember -All -AddSelf output, for the visualize-only path of Show-WinADGroupMember
        param([string] $Name, [string] $Type = 'Group', [int] $Nesting = 0, [string] $Parent = 'GG-RBAC-Root')
        [PSCustomObject] @{
            GroupName         = 'GG-RBAC-Root'
            GroupDomainName   = 'test.local'
            Name              = $Name
            DomainName        = 'test.local'
            DistinguishedName = (Get-TestDN $Name)
            ParentGroupDomain = if ($Nesting -eq -1) { '' } else { 'test.local' }
            ParentGroupDN     = if ($Nesting -eq -1) { '' } else { (Get-TestDN $Parent) }
            Type              = $Type
            Nesting           = $Nesting
            CircularDirect    = $false
            CircularIndirect  = $false
            TotalMembers      = 3; DirectMembers = 2; DirectGroups = 1; IndirectMembers = 1
        }
    }
}
AfterAll {
    $Global:HTMLIcons = $Script:OriginalHTMLIcons
}

Describe 'Get-WinADCustomDiagramIcon pattern resolution' {
    BeforeEach {
        $Script:WinADCustomDiagramIconWarnings = $null
        $Global:HTMLIcons = @{
            FontAwesomeSolid   = @{ 'user-shield' = 'f505'; 'users' = 'f0c0' }
            FontAwesomeRegular = @{ 'user' = 'f007' }
            FontAwesomeBrands  = @{ 'windows' = 'f17a' }
        }
    }
    It 'first matching pattern wins in an ordered dictionary' {
        $Icons = [ordered] @{ 'GG-*' = 'https://cdn/first.png'; '*RBAC*' = @{ IconSolid = 'users' } }
        $Result = Get-WinADCustomDiagramIcon -Name 'GG-RBAC-FileShares' -CustomIcons $Icons
        $Result.Image | Should -Be 'https://cdn/first.png'
        $Result.Keys | Should -Not -Contain 'IconSolid'
    }
    It 'resolves a string value to an image and a dictionary value to an icon with color' {
        (Get-WinADCustomDiagramIcon -Name 'AnyGroup' -CustomIcons @{ '*' = 'https://cdn/x.png' }).Image | Should -Be 'https://cdn/x.png'
        $IconResult = Get-WinADCustomDiagramIcon -Name 'Enterprise Admins' -CustomIcons @{ 'Enterprise Admins' = @{ IconSolid = 'user-shield'; IconColor = 'Red' } }
        $IconResult.IconSolid | Should -Be 'user-shield'
        $IconResult.IconColor | Should -Be 'Red'
        (Get-WinADCustomDiagramIcon -Name 'PC-01' -CustomIcons @{ 'PC-*' = @{ IconBrands = 'windows' } }).IconBrands | Should -Be 'windows'
    }
    It 'returns nothing when no pattern matches' {
        Get-WinADCustomDiagramIcon -Name 'Unrelated' -CustomIcons @{ 'GG-*' = 'https://cdn/x.png' } | Should -BeNullOrEmpty
    }
    It 'skips an invalid wildcard pattern with one warning and still evaluates later patterns' {
        $Warnings = $null
        $Icons = [ordered] @{ 'Bad[' = 'https://cdn/never.png'; '*RBAC*' = 'https://cdn/rbac.png' }
        $Result = Get-WinADCustomDiagramIcon -Name 'GG-RBAC-X' -CustomIcons $Icons -WarningVariable Warnings -WarningAction SilentlyContinue
        $Result.Image | Should -Be 'https://cdn/rbac.png'
        "$Warnings" | Should -Match 'Invalid wildcard'
        # the warning is deduplicated on repeated calls
        $Warnings2 = $null
        $null = Get-WinADCustomDiagramIcon -Name 'GG-RBAC-X' -CustomIcons $Icons -WarningVariable Warnings2 -WarningAction SilentlyContinue
        "$Warnings2" | Should -BeNullOrEmpty
    }
    It 'falls back to default icons with a warning when the icon name is not in the PSWriteHTML icon set' {
        $Warnings = $null
        $Result = Get-WinADCustomDiagramIcon -Name 'GG-RBAC-X' -CustomIcons @{ '*RBAC*' = @{ IconSolid = 'user-sheild' } } -WarningVariable Warnings -WarningAction SilentlyContinue
        $Result | Should -BeNullOrEmpty
        "$Warnings" | Should -Match 'does not exist'
    }
    It 'passes icon names through when the PSWriteHTML icon dictionary is not loaded' {
        $Global:HTMLIcons = $null
        (Get-WinADCustomDiagramIcon -Name 'X' -CustomIcons @{ 'X' = @{ IconSolid = 'anything-goes' } }).IconSolid | Should -Be 'anything-goes'
    }
    It 'treats a matched entry without a usable value as no override' {
        Get-WinADCustomDiagramIcon -Name 'X' -CustomIcons @{ 'X' = @{ Wrong = 'key' } } | Should -BeNullOrEmpty
        Get-WinADCustomDiagramIcon -Name 'X' -CustomIcons @{ 'X' = '' } | Should -BeNullOrEmpty
    }
    It 'matches names containing brackets when the pattern escapes them' {
        (Get-WinADCustomDiagramIcon -Name 'Group[1]' -CustomIcons @{ 'Group`[1`]' = 'https://cdn/b.png' }).Image | Should -Be 'https://cdn/b.png'
    }
}

Describe 'CustomIcons propagation through Show-WinADGroupMember' {
    BeforeEach {
        $Script:CapturedNodes = [System.Collections.Generic.List[object]]::new()
        $Script:WinADCustomDiagramIconWarnings = $null
        $Global:HTMLIcons = $null
        # Pre-built membership rows exercise the visualize-only path without touching a directory
        $Script:Rows = @(
            New-TestRow -Name 'GG-RBAC-Root' -Nesting -1
            New-TestRow -Name 'GG-RBAC-Sub'
            New-TestRow -Name 'ADMIN-John' -Type 'User'
            New-TestRow -Name 'Plain-User' -Type 'User'
        )
    }
    It 'applies matching overrides on diagram nodes and leaves unmatched nodes on defaults' {
        Show-WinADGroupMember -Identity $Script:Rows -HideHTML -CustomIcons ([ordered] @{
                '*RBAC*'  = 'https://cdn/rbac.png'
                'ADMIN-*' = @{ IconSolid = 'user-shield'; IconColor = 'Red' }
            })
        $Script:CapturedNodes.Count | Should -BeGreaterThan 0
        $RbacNodes = @($Script:CapturedNodes | Where-Object { $_.Label -like 'GG-RBAC*' })
        $RbacNodes.Count | Should -BeGreaterThan 0
        $RbacNodes.Image | Should -Not -Contain $null
        @($RbacNodes | Where-Object { $_.Image -ne 'https://cdn/rbac.png' }).Count | Should -Be 0
        $AdminNodes = @($Script:CapturedNodes | Where-Object { $_.Label -like 'ADMIN-*' })
        @($AdminNodes | Where-Object { $_.IconSolid -ne 'user-shield' -or $_.IconColor -ne 'Red' }).Count | Should -Be 0
        $PlainNodes = @($Script:CapturedNodes | Where-Object { $_.Label -like 'Plain-*' })
        @($PlainNodes | Where-Object { $_.Image -or $_.IconColor -eq 'Red' }).Count | Should -Be 0
    }
    It 'changes nothing when CustomIcons is omitted' {
        Show-WinADGroupMember -Identity $Script:Rows -HideHTML
        $Script:CapturedNodes.Count | Should -BeGreaterThan 0
        @($Script:CapturedNodes | Where-Object { $_.Image -like 'https://cdn/*' }).Count | Should -Be 0
    }
}

Describe 'CustomIcons propagation through Show-WinADGroupMemberOf' {
    BeforeEach {
        $Script:CapturedNodes = [System.Collections.Generic.List[object]]::new()
        $Script:WinADCustomDiagramIconWarnings = $null
        $Global:HTMLIcons = $null
        $Script:TestGraph = @{}
        foreach ($Definition in @(
                @{ Name = 'GG-RBAC-Parent'; Members = @(Get-TestDN 'SomeUser'); MemberOf = @(); Class = 'group' }
                @{ Name = 'SomeUser'; Members = @(); MemberOf = @(Get-TestDN 'GG-RBAC-Parent'); Class = 'user' }
            )) {
            $Script:TestGraph[(Get-TestDN $Definition.Name)] = [PSCustomObject] @{
                Name              = $Definition.Name
                SamAccountName    = $Definition.Name
                DisplayName       = $Definition.Name
                Mail              = ''
                Enabled           = $true
                ObjectClass       = $Definition.Class
                GroupType         = 'Security'
                GroupScope        = 'Universal'
                DomainName        = 'test.local'
                DistinguishedName = (Get-TestDN $Definition.Name)
                ObjectSID         = "S-1-5-21-0-0-0-$($Definition.Name)"
                Members           = $Definition.Members
                MemberOf          = $Definition.MemberOf
            }
        }
        $Script:WinADGroupObjectCache = @{}
    }
    It 'applies matching overrides on the memberOf diagram nodes' {
        Show-WinADGroupMemberOf -Identity 'SomeUser' -HideHTML -CustomIcons @{ '*RBAC*' = 'https://cdn/rbac.png' }
        $ParentNodes = @($Script:CapturedNodes | Where-Object { $_.Label -like 'GG-RBAC*' })
        $ParentNodes.Count | Should -BeGreaterThan 0
        @($ParentNodes | Where-Object { $_.Image -ne 'https://cdn/rbac.png' }).Count | Should -Be 0
        $UserNodes = @($Script:CapturedNodes | Where-Object { $_.Label -like 'SomeUser*' })
        @($UserNodes | Where-Object { $_.Image }).Count | Should -Be 0
    }
}
