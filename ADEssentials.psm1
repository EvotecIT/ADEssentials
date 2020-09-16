#Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue -Recurse )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue -Recurse )

#Dot source the files
Foreach ($import in @($Public + $Private)) {
    Try {
        . $import.fullname
    } Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

<# To be implemented as part of PSPublishModule
$FunctionsAll = 'Get-WinADObject', 'Get-WinADLastBackup', 'Get-WinADDuplicateObject'
$ModuleFunctions = @{
    ActiveDirectory = 'Get-WinADObject', 'Get-WinADLastBackup'
    GroupPolicy     = 'Get-WinADDuplicateObject'
}


[Array] $FunctionsToRemove = foreach ($Module in $ModuleFunctions.Keys) {
    try {
        Import-Module -Name $Module -ErrorAction Stop
    } catch {
        $ModuleFunctions[$Module]
    }
}
$FunctionsToLoad = foreach ($Function in $FunctionsAll) {
    if ($Function -notin $FunctionsToRemove) {
        $Function
    }
}
Export-ModuleMember -Function $FunctionsToLoad -Alias $AliasesToLoad
#>
Export-ModuleMember -Function '*' -Alias '*'