<#
.SYNOPSIS
    Copy AD security from one OU to another.

.DESCRIPTION
    Copies the security for one OU to another with the ability to use a different target group with source group as reference.

.PARAMETER SourceOU
    The reference OU.

.PARAMETER TargetOU
    Target OU to apply security.

.PARAMETER SourceGroup
    The reference group.

.PARAMETER TargetGroup
    Target group to apply security

.PARAMETER Execute
    Switch to execute - leaving this out will result in a dry run (whatif).

.EXAMPLE
    Copy-ADOUSecurity -SourceOU "OU=Finance,DC=contoso,DC=com" -TargetOU "OU=Sales,DC=contoso,DC=com" -SourceGroup "FinanceAdmins" -TargetGroup "SalesAdmins"
#>
function Copy-ADOUSecurity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$SourceOU,
        [Parameter(Mandatory)][string]$TargetOU,
        [Parameter(Mandatory)][string]$SourceGroup,
        [Parameter(Mandatory)][string]$TargetGroup,
        [Parameter][switch]$Execute
    )
    begin { }

    process {

        [string]$sDomain = (Get-ADDomain).NetBIOSName
        [string]$sServer = (Get-ADDomainController -Writable -Discover).HostName

        $sSourceOU = $SourceOU.Trim()
        $sDestOU = $TargetOU.Trim()
        $sSourceAccount = $SourceGroup.Trim()
        $sDestAccount = $TargetGroup.Trim()

        [ADSI]$oSourceOU = "LDAP://{0}/{1}" -f $sServer, $sSourceOU
        [ADSI]$oTargetOU = "LDAP://{0}/{1}" -f $sServer, $sDestOU

        $oDestAccountNT = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $sDomain, $sDestAccount

        $oSourceOU.ObjectSecurity.Access | Where-Object { $_.IdentityReference -like "$sDomain\$sSourceAccount" } | ForEach-Object {
            $ActiveDirectoryRights = $_.ActiveDirectoryRights
            $AccessControlType = $_.AccessControlType
            $InheritanceType = $_.InheritanceType
            $InheritedObjectType = $_.InheritedObjectType
            $ObjectType = $_.ObjectType

            $oAce = New-Object System.DirectoryServices.ActiveDirectoryAccessRule ($oDestAccountNT, $ActiveDirectoryRights, $AccessControlType, $ObjectType, $InheritanceType, $InheritedObjectType)
            $oTargetOU.ObjectSecurity.AddAccessRule($oAce)
        }

        $oSourceOU.ObjectSecurity.Access | Where-Object { $_.IdentityReference -like "$sDomain\$sSourceAccount" }
        $oTargetOU.ObjectSecurity.Access | Where-Object { $_.IdentityReference -like "$sDomain\$sDestAccount" }

        if ($Execute) {
            try {
                $oTargetOU.CommitChanges()
                Write-Output -InputObject "[Info] : Permissions commited"
            } catch {
                $ErrorMessage = $_.Exception.Message
                Write-Warning -Message $ErrorMessage
            }
        } else {
            Write-Output -InputObject "[Info] : Use the switch -Execute to apply..."
        }
    }

    end { }
}
