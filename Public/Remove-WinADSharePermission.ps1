function Remove-WinADSharePermission {
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