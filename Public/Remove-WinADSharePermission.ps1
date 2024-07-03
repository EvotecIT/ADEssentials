function Remove-WinADSharePermission {
    <#
    .SYNOPSIS
    Removes permissions from a specified path or recursively from all items within a specified path.

    .DESCRIPTION
    This cmdlet removes permissions from a specified path or recursively from all items within a specified path. It targets permissions of a specific type, defaulting to 'Unknown'. The cmdlet also allows for limiting the number of processing operations.

    .PARAMETER Path
    Specifies the path from which to remove permissions. This parameter is mandatory and can be a file or a directory.

    .PARAMETER Type
    Specifies the type of permissions to remove. The default value is 'Unknown'. This parameter is validated to only accept 'Unknown'.

    .PARAMETER LimitProcessing
    Specifies the maximum number of processing operations to perform. This parameter is optional.

    .EXAMPLE
    Remove-WinADSharePermission -Path 'C:\Example\Path' -Type 'Unknown' -LimitProcessing 100

    This example removes 'Unknown' type permissions from 'C:\Example\Path' and all items within it, limiting the processing to 100 operations.

    .NOTES
    This cmdlet requires the Get-FilePermission and Set-Acl cmdlets to function properly.
    #>
    [cmdletBinding(DefaultParameterSetName = 'Path', SupportsShouldProcess)]
    param(
        [Parameter(ParameterSetName = 'Path', Mandatory)][string] $Path,
        [ValidateSet('Unknown')][string] $Type = 'Unknown',
        [int] $LimitProcessing
    )
    Begin {
        [int] $Count = 0
    }
    Process {
        if ($Path -and (Test-Path -Path $Path)) {
            $Data = @(Get-Item -Path $Path) + @(Get-ChildItem -Path $Path -Recurse:$true)
            foreach ($_ in $Data) {
                $PathToProcess = $_.FullName
                $Permissions = Get-FilePermission -Path $PathToProcess -Extended -IncludeACLObject -ResolveTypes
                $OutputRequiresCommit = foreach ($Permission in $Permissions) {
                    if ($Type -eq 'Unknown' -and $Permission.PrincipalType -eq 'Unknown' -and $Permission.IsInherited -eq $false) {
                        try {
                            Write-Verbose "Remove-WinADSharePermission - Removing permissions from $PathToProcess for $($Permission.Principal) / $($Permission.PrincipalType)"
                            $Permission.AllACL.RemoveAccessRule($Permission.ACL)
                            $true
                        } catch {
                            Write-Warning "Remove-WinADSharePermission - Removing permissions from $PathToProcess for $($Permission.Principal) / $($Permission.PrincipalType) failed: $($_.Exception.Message)"
                            $false
                        }
                    }
                }
                if ($OutputRequiresCommit -notcontains $false -and $OutputRequiresCommit -contains $true) {
                    try {
                        Set-Acl -Path $PathToProcess -AclObject $Permissions[0].ALLACL -ErrorAction Stop
                    } catch {
                        Write-Warning "Remove-WinADSharePermission - Commit for $($PathToProcess) failed: $($_.Exception.Message)"
                    }
                    $Count++
                    if ($Count -eq $LimitProcessing) {
                        break
                    }
                }
            }
        }
    }
    End {

    }
}