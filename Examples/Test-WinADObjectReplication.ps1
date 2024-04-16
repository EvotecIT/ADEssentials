function Test-WinADObjectReplication {
    [CmdletBinding()]
    param (
        [string] $PDCEmulator = (Get-ADDomain).PDCEmulator,
        [string[]] $DomainController,
        [PSCredential]$Credential,
        [int]$MaxDurationSeconds = 100,
        [int]$DCSuccessPercent = 100,
        [switch]$EnableException
    )

    begin {
        #region Ensure Domain Controller parameter is filled
        $parameters = @{ Server = $PDCEmulator }
        $credParam = @{ }
        if ($Credential) {
            $parameters['Credential'] = $Credential
            $credParam = @{ Credential = $Credential }
        }

        if (-not $DomainController) {
            try {
                $DomainController = (Get-ADDomainController @parameters -Filter "*" -ErrorAction Stop).HostName | Where-Object {
                    $_ -ne $PDCEmulator
                }
            } catch {
                # Stop-PSFFunction -String 'Test-KrbPasswordReset.FailedDCResolution' -StringValues $PDCEmulator -ErrorRecord $_
                return
            }
        }
        #endregion Ensure Domain Controller parameter is filled

        #region Create a test account to test SO replication with
        try {
            $randomName = "krbtgt_test_$(Get-Random -Minimum 100 -Maximum 999)"
            Write-PSFMessage -String 'Test-KrbPasswordReset.CreatingCanary' -StringValues $randomName
            $canaryAccount = New-ADUser -Name $randomName -PassThru @parameters -ErrorAction Stop
        } catch {
            Stop-PSFFunction -String 'Test-KrbPasswordReset.FailedCanaryCreation' -StringValues $randomName -ErrorRecord $_
            return
        }
        try {
            $null = Sync-LdapObjectParallel @credParam -Object $canaryAccount -Server $DomainController -Target $PDCEmulator -Reverse
        } catch {
            # We don't care
        }
        #endregion Create a test account to test SO replication with
    }
    process {
        if (Test-PSFFunctionInterrupt) { return }

        $result = [PSCustomObject]@{
            PSTypeName       = 'Krbtgt.TestResult'
            PDCEmulator      = $PDCEmulator
            Start            = $null
            End              = $null
            Duration         = $null
            Reset            = $false
            Sync             = @()
            DCTotal          = ($DomainController | Measure-Object).Count
            DCSuccess        = 0
            DCSuccessPercent = 0
            DCFailed         = @()
            Errors           = @()
            Success          = $true
            Status           = $null
            RWDCs            = $DomainController
        }

        $result.Start = Get-Date

        #region Test 1: Password Reset
        #Write-PSFMessage -String 'Test-KrbPasswordReset.ResettingPassword' -StringValues $canaryAccount.DistinguishedName -Target $canaryAccount.DistinguishedName
        try {
            Reset-UserPassword @parameters -Identity $canaryAccount.DistinguishedName -EnableException
            $result.Reset = $true
        } catch {
            #Write-PSFMessage -Level Warning -String 'Test-KrbPasswordReset.ResettingPasswordFailed' -StringValues $canaryAccount.DistinguishedName -Target $canaryAccount.DistinguishedName -ErrorRecord $_
            $result.Reset = $false
            $result.Errors += $_
            $result.Success = $false
            $result.Status = $result.Status, 'ResetError' -join ", "
        }
        #endregion Test 1: Password Reset

        #region Test 2: Resync Domain Controllers
        # Write-PSFMessage -String 'Test-KrbPasswordReset.SynchronizingCanary' -StringValues $canaryAccount.DistinguishedName -Target $canaryAccount.DistinguishedName
        $result.Sync = Sync-WinADObject @credParam -SourceDC $DomainController -TargetDC $PDCEmulator -Identity $canaryAccount.DistinguishedName -EnableException:$false
        $result.End = Get-Date
        $result.Duration = $result.End - $result.Start
        $result.DCSuccess = $result.Sync | Where-Object Success
        $result.DCFailed = $result.Sync | Where-Object Success -EQ $false
        $result.DCSuccessPercent = ($result.DCSuccess | Measure-Object).Count / $result.DCTotal * 100
        $result.Sync.Error | ForEach-Object {
            if ($_) { $result.Errors += $_ }
        }
        if ($result.Duration.TotalSeconds -gt $MaxDurationSeconds) {
            $result.Success = $false
            $result.Status = $result.Status, 'TooSlowError' -join ", "
        }
        if ($result.DCSuccessPercent -lt $DCSuccessPercent) {
            $result.Success = $false
            $result.Status = $result.Status, 'SyncErrorRateError' -join ", "
        }
        Write-PSFMessage -String 'Test-KrbPasswordReset.Concluded' -StringValues $result.Success, $result.Status, $canaryAccount.DistinguishedName -Target $canaryAccount.DistinguishedName
        #endregion Test 2: Resync Domain Controllers

        $result
    }
    end {
        # Remove the test account after finishing its work
        $canaryAccount | Remove-ADUser @parameters -Confirm:$false -ErrorAction Stop

    }
}