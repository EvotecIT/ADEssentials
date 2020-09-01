function Get-WinADObjectMember {
    [cmdletBinding()]
    param(
        [parameter(Position = 0, Mandatory)][Array] $Identity,
        [switch] $AddSelf,
        [switch] $ClearCache,
        [Parameter(DontShow)][int] $Nesting = -1,
        [Parameter(DontShow)][System.Collections.Generic.List[object]] $CollectedGroups,
        [Parameter(DontShow)][System.Object] $Circular,
        [Parameter(DontShow)][System.Collections.IDictionary] $InitialObject,
        [Parameter(DontShow)][switch] $Nested
    )
    Begin {
        if (-not $Script:WinADGroupObjectCache -or $ClearCache) {
            $Script:WinADGroupObjectCache = @{}
            #$Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            #$Script:WinADForestCache = @{
            #    Forest  = $Forest
            #    Domains = $Forest.Domains.Name
            #}
        }
    }
    Process {
        [Array] $Output = foreach ($MyObject in $Identity) {
            $Object = Get-WinADObject -Identity $MyObject
            Write-Verbose "Get-WinADObjectMember - starting $($Object.Name)/$($Object.DomainName)"
            if (-not $Nested.IsPresent) {
                $InitialObject = [ordered] @{
                    ObjectName           = $Object.Name
                    ObjectSamAccountName = $Object.SamAccountName
                    Name                 = $Object.Name
                    SamAccountName       = $Object.SamAccountName
                    DomainName           = $Object.DomainName
                    DisplayName          = $Object.DisplayName
                    Enabled              = $Object.Enabled
                    Type                 = $Object.ObjectClass
                    Nesting              = $Nesting
                    Circular             = $false
                    #CrossForest          = $false
                    ParentGroup          = ''
                    ParentGroupDomain    = ''
                    ObjectDomainName     = $Object.DomainName
                    DistinguishedName    = $Object.Distinguishedname
                    Sid                  = $Object.ObjectSID
                }
                $CollectedGroups = [System.Collections.Generic.List[string]]::new()
                $Nesting = -1
            }

            $Nesting++

            if ($Object) {
                # Lets cache our object
                $Script:WinADGroupObjectCache[$Object.DistinguishedName] = $Object
                if ($Circular) {
                    [Array] $NestedMembers = foreach ($MyIdentity in $Object.MemberOf) {
                        if ($Script:WinADGroupObjectCache[$MyIdentity]) {
                            $Script:WinADGroupObjectCache[$MyIdentity]
                        } else {
                            Write-Verbose "Get-WinADObjectMember - Requesting more data on $MyIdentity (Circular: $true)"
                            $ADObject = Get-WinADObject -Identity $MyIdentity
                            $Script:WinADGroupObjectCache[$MyIdentity] = $ADObject
                            $Script:WinADGroupObjectCache[$MyIdentity]
                        }
                    }
                    [Array] $NestedMembers = foreach ($Member in $NestedMembers) {
                        if ($CollectedGroups -notcontains $Member.DistinguishedName) {
                            $Member
                        }
                    }
                    $Circular = $null
                } else {
                    [Array] $NestedMembers = foreach ($MyIdentity in $Object.MemberOf) {
                        if ($Script:WinADGroupObjectCache[$MyIdentity]) {
                            $Script:WinADGroupObjectCache[$MyIdentity]
                        } else {
                            Write-Verbose "Get-WinADObjectMember - Requesting more data on $MyIdentity (Circular: $false)"
                            $ADObject = Get-WinADObject -Identity $MyIdentity
                            $Script:WinADGroupObjectCache[$MyIdentity] = $ADObject
                            $Script:WinADGroupObjectCache[$MyIdentity]
                        }
                    }
                }
                foreach ($NestedMember in $NestedMembers) {
                    Write-Verbose "Get-WinADObjectMember - processing $($InitialObject.ObjectName) nested member $($NestedMember.name)"
                    #$DomainParentGroup = ConvertFrom-DistinguishedName -DistinguishedName $Object.DistinguishedName -ToDomainCN
                    $CreatedObject = [ordered] @{
                        ObjectName           = $InitialObject.ObjectName
                        ObjectSamAccountName = $InitialObject.SamAccountName
                        Name                 = $NestedMember.name
                        SamAccountName       = $NestedMember.SamAccountName
                        DomainName           = $NestedMember.DomainName
                        DisplayName          = $NestedMember.DisplayName
                        Enabled              = $NestedMember.Enabled
                        Type                 = $NestedMember.ObjectClass
                        Nesting              = $Nesting
                        Circular             = $false
                        #CrossForest          = $false
                        ParentGroup          = $Object.name
                        ParentGroupDomain    = $Object.DomainName
                        ObjectDomainName     = $InitialObject.DomainName
                        DistinguishedName    = $NestedMember.DistinguishedName
                        Sid                  = $NestedMember.ObjectSID
                    }
                    #if ($NestedMember.DomainName -notin $Script:WinADForestCache['Domains']) {
                    #    $CreatedObject['CrossForest'] = $true
                    #}
                    if ($NestedMember.ObjectClass -eq "group") {
                        if ($Object.members -contains $NestedMember.DistinguishedName) {
                            $Circular = $Object.DistinguishedName
                            $CreatedObject['Circular'] = $true
                        }
                        $CollectedGroups.Add($Object.DistinguishedName)
                        [PSCustomObject] $CreatedObject
                        Write-Verbose "Get-WinADObjectMember - Going deeper with $($NestedMember.name)"
                        $OutputFromGroup = Get-WinADObjectMember -Identity $NestedMember -Nesting $Nesting -Circular $Circular -InitialObject $InitialObject -CollectedGroups $CollectedGroups -Nested
                        $OutputFromGroup
                    } else {
                        [PSCustomObject] $CreatedObject
                    }
                }
            }
        }
    }
    End {
        if ($Output.Count -gt 0) {
            if ($Nesting -eq 0) {
                if ($AddSelf) {
                    [PSCustomObject] $InitialObject
                }
                foreach ($MyObject in $Output) {
                    $MyObject
                }
            } else {
                # this is nested call so we want to get whatever it gives us
                $Output
            }
        }
    }
}