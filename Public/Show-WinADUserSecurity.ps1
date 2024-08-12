function Show-WinADUserSecurity {
    <#
    .SYNOPSIS
    Generates a detailed HTML report on the security settings for a specified Active Directory user.

    .DESCRIPTION
    This cmdlet creates a comprehensive HTML report that includes the user's properties, access control list (ACL), group memberships, and a diagram of their group hierarchy. The report is designed to provide a clear overview of the user's security settings and relationships within the Active Directory.

    .PARAMETER Identity
    Specifies the identity of the user for whom to generate the report. This can be a distinguished name, GUID, security identifier (SID), or SAM account name.

    .EXAMPLE
    Show-WinADUserSecurity -Identity "CN=User1,DC=example,DC=com"

    .NOTES
    This cmdlet is useful for auditing and analyzing the security settings of Active Directory users, helping administrators to identify potential security risks and ensure compliance with organizational policies.
    #>
    [cmdletBinding()]
    param(
        [string[]] $Identity
    )

    New-HTML {
        foreach ($I in $Identity) {
            $User = Get-WinADObject -Identity $I
            $ACL = Get-ADACL -ADObject $User.Distinguishedname
            $Objects = [ordered] @{}
            $GroupsList = foreach ($A in $ACL) {
                $Objects[$A.Principal] = Get-WinADObject -Identity $A.Principal
                if ($Objects[$A.Principal].ObjectClass -eq 'group') {
                    $Objects[$A.Principal].Distinguishedname
                }
            }

            $Groups = $Objects.Values | Where-Object {$_.ObjectClass -eq 'group'} | Sort-Object -Property Distinguishedname
            $GroupsList = foreach ($G in $Groups) {
                Get-WinADGroupMember -Identity $G.Distinguishedname -AddSelf
            }

            New-HTMLTab -Name "$($User.DomainName)\$($User.SamAccountName)" {
                New-HTMLSection -Invisible {
                    New-HTMLPanel {
                        New-HTMLTable -DataTable $User
                    }
                    New-HTMLPanel {
                        New-HTMLTable -Filtering -DataTable $ACL -IncludeProperty Principal, AccessControlType, ActiveDirectoryRights, ObjectTypeName, InheritedObjectTypeName, InhertitanceType, IsInherited
                    }
                }
                New-HTMLSection -Invisible {

                    New-HTMLTable -Filtering -DataTable $Objects.Keys
                }
                $HideAppliesTo = 'Default'
                New-HTMLTabPanel {
                    New-HTMLTab -TabName 'Diagram Basic' {
                        New-HTMLSection -Title "Diagram for Summary" {
                            New-HTMLGroupDiagramSummary -ADGroup $GroupsList -HideAppliesTo $HideAppliesTo -HideUsers:$HideUsers -HideComputers:$HideComputers -HideOther:$HideOther -DataTableID $DataTableID -ColumnID 1 -Online:$Online
                        }
                    }
                    New-HTMLTab -TabName 'Diagram Hierarchy' {
                        New-HTMLSection -Title "Diagram for Summary" {
                            New-HTMLGroupDiagramSummaryHierarchical -ADGroup $GroupsList -HideAppliesTo $HideAppliesTo -HideUsers:$HideUsers -HideComputers:$HideComputers -HideOther:$HideOther -Online:$Online
                        }
                    }
                }
            }
        }

    } -Online -ShowHTML
}