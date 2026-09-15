Describe 'PSEventViewer 4 integration' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../ADEssentials.psd1" -Force
    }

    It 'uses the EventViewerX 4 query command' {
        Get-Command Get-EVXEvent -Module PSEventViewer -ErrorAction Stop |
            Should -Not -BeNullOrEmpty
    }

    It 'contains no calls to the removed Get-Events command' {
        $sourcePaths = @(
            "$PSScriptRoot/../Public/Get-WinADDFSHealth.ps1"
            "$PSScriptRoot/../Public/Get-WinADLdapBindingsSummary.ps1"
        )
        $commandNames = foreach ($sourcePath in $sourcePaths) {
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $sourcePath,
                [ref] $null,
                [ref] $parseErrors
            )
            $parseErrors | Should -BeNullOrEmpty
            $ast.FindAll(
                { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
                $true
            ).GetCommandName()
        }

        $commandNames | Should -Not -Contain 'Get-Events'
        @($commandNames | Where-Object { $_ -eq 'Get-EVXEvent' }).Count | Should -Be 2
    }

    It 'maps LDAP binding events from the EventViewerX 4 result contract' {
        InModuleScope ADEssentials {
            Mock Get-WinADForestDetails {
                [pscustomobject] @{
                    ForestDomainControllers = [pscustomobject] @{
                        HostName = @('dc01.ad.evotec.xyz', 'dc02.ad.evotec.xyz')
                    }
                }
            }
            Mock Get-EVXEvent {
                [pscustomobject] @{
                    ComputerName   = 'dc01.ad.evotec.xyz'
                    TimeCreated    = [datetime] '2026-09-15T09:00:00Z'
                    NoNameA0       = 12
                    NoNameA1       = 34
                    GatheredFrom   = 'dc01.ad.evotec.xyz'
                    GatheredLogName = 'Directory Service'
                }
            }

            $result = Get-WinADLDAPBindingsSummary -Forest 'ad.evotec.xyz' -Days 2

            $result.'Domain Controller' | Should -Be 'dc01.ad.evotec.xyz'
            $result.Date | Should -Be ([datetime] '2026-09-15T09:00:00Z')
            $result.'Number of simple binds performed without SSL/TLS' | Should -Be 12
            $result.'Number of Negotiate/Kerberos/NTLM/Digest binds performed without signing' | Should -Be 34
            $result.GatheredFrom | Should -Be 'dc01.ad.evotec.xyz'
            $result.GatheredLogName | Should -Be 'Directory Service'

            Should -Invoke Get-EVXEvent -Exactly 1 -ParameterFilter {
                $LogName -eq 'Directory Service' -and
                $EventId -contains 2887 -and
                $MachineName -contains 'dc01.ad.evotec.xyz' -and
                $MachineName -contains 'dc02.ad.evotec.xyz' -and
                $ReadMode -eq 'Full' -and
                $ExpandData -and
                $ContinueOnError -and
                $ErrorAction -eq 'SilentlyContinue'
            }
        }
    }
}
