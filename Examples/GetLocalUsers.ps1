$group = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"

$List = $group.Members() | ForEach-Object {
    $member = [ADSI]$_
    $name = $member.Name #$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
    $class = $member.Class #$_.GetType().InvokeMember("Class", 'GetProperty', $null, $_, $null)
    $adsPath = $member.ADsPath #$_.GetType().InvokeMember("ADsPath", 'GetProperty', $null, $_, $null)
    $description = $member.Description
    $SplitPath = $adsPath.Replace("WinNT://", "")
    $SplittedObject = $SplitPath.Split('/')
    if ($SplittedObject.Count -eq 3) {
        $FullObject = $SplittedObject[1] + "\" + $SplittedObject[2]
    } elseif ($SplittedObject.Count -eq 2) {
        $FullObject = $SplittedObject[0] + "\" + $SplittedObject[1]
    } else {
        $FullObject = $SplittedObject[0]
    }
    $domain = $SplitPath[1]
    $location = if ($domain -eq $env:COMPUTERNAME) { "Local" } else { "Domain" }

    [PSCustomObject]@{
        Name        = if ($name) { $name.ToString() } else { $name }
        Domain      = $domain
        Object      = $FullObject
        Sid         = $member.objectSid
        #AdsPath     = $adsPath
        Type        = $class
        Location    = $location
        Description = $description
    }
}
$List | Format-Table -AutoSize

return

$FullList = foreach ($Object in $List) {
    if ($Object.Location -eq "Local") {
        $Object
    } else {
        if ($Object.Type -eq "Group") {
            Get-WinADGroupMember -Identity $Object.Name -All
        }
    }
}
$FullList | Format-Table -AutoSize