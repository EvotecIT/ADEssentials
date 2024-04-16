function Set-ADKerberosPassword {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [switch] $ReadOnlyDomainController,
        [switch] $All
    )

    $ForestInformation = Get-WinADForestDetails -Extended
    foreach ($Domain in $ForestInformation.Domains) {
        $Server = Get-ADDomainController -DomainName $Domain -Service PrimaryDC -Discover
        if ($All) {
            $KeberosAccounts = Get-ADUser -Filter "Name -like 'krbtgt*'" -Server $Server.HostName[0] -Properties 'msDS-KrbTgtLinkBl', 'PasswordLastSet'
        } elseif ($ReadOnlyDomainController) {
            $KeberosAccounts = Get-ADUser -Filter "Name -like 'krbtgt_*'" -Server $Server.HostName[0] -Properties 'msDS-KrbTgtLinkBl', 'PasswordLastSet'
        } else {
            $KeberosAccounts = Get-ADUser -Filter "Name -like 'krbtgt'" -Server $Server.HostName[0] -Properties 'msDS-KrbTgtLinkBl', 'PasswordLastSet'
        }
        $ProcessedAccounts = foreach ($Account in $KeberosAccounts) {
            $PasswordSetDays = (Get-Date) - $Account.PasswordLastSet
            if ($Account.SamAccountName -like "*_*") {
                if ($Account.'msDS-KrbTgtLinkBl') {
                    Write-Color -Text "[i] ", "Kerberos account ", $Account.SamAccountName, " is valid RODC account. ", "Processing..." -Color Yellow, Green, Green, White, Green
                    $Account
                } else {
                    Write-Color -Text "[i] ", "Kerberos account ", $Account.SamAccountName, " is not linked to any domain controller. ", "Please clean it up. Skipping." -Color Yellow, White, Yellow, White, Yellow
                }
            } else {
                Write-Color -Text "[i] ", "Kerberos account ", $Account.SamAccountName, " is valid DC account. ", "Processing..." -Color Yellow, Green, Green, White, Green
                $Account
            }
        }

        $ProcessedAccounts | Select-Object DistinguishedName, Name, Enabled, SamAccountName, msDS-KrbTgtLinkBl, 'PasswordLastSet'
    }

    <#
    Try { Set-ADAccountPassword -Identity (Get-ADUser krbtgt -Server $Server).DistinguishedName -Server $Server -Reset -NewPassword (ConvertTo-SecureString ((New-CtmADComplexPassword 32).ToString()) -AsPlainText -Force) }
    Catch {
        If (($Error.FullyQualifiedErrorId -eq 'ActiveDirectoryCmdlet:System.UnauthorizedAccessException,Microsoft.ActiveDirectory.Management.Commands.SetADAccountPassword') -and ($Error.CategoryInfo -like "*PermissionDenied*"))
        { Return (New-Object -TypeName PSObject -Property @{'Success' = $false; 'Message' = 'Krbtgt key reset failed due to insufficient permissions.' }) }
        Else { Return (New-Object -TypeName PSObject -Property @{'Success' = $false; 'Message' = 'Krbtgt key reset failed for an unknown reason.' }) }
    }
    Return (New-Object -TypeName PSObject -Property @{'Success' = $true; 'Message' = 'Krbtgt key reset successfully.' })
    #>


}

