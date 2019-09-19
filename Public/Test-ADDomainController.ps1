function Test-ADDomainController {
    [CmdletBinding()]
    param(
        [string[]] $ComputerName,
        [Parameter(Mandatory = $false)][PSCredential] $Credential = $null
    )

    $CredentialParameter = @{ }
    if ($null -ne $Credential) {
        $CredentialParameter['Credential'] = $Credential
    }

    $Output = foreach ($Computer in $ComputerName) {
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