$Test = get-adobject "cn=Cleanup-user1,OU=Temporary,DC=ad,DC=evotec,DC=xyz"
$GUID = [guid]::new($Test.ObjectGUID.Guid)
[System.Convert]::ToBase64String($GUID.toByteArray())