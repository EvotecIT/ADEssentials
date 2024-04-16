Getting the current dsHeurisitics value

Note: The first thing to do is to verify if there is a value already set. If there is, then save it to restore it at the end.

1. At a command prompt, type ldp.exe and then press ENTER to start the LDP utility.
2. Click Connection , click connect and then click OK .
3. Click Connection , click Bind , type the user name and password of a forest root administrator, and then click OK .
4. Click View , click Tree , and then click OK .
5. Using View\Tree, open the following configuration CN:

CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=Forest root domain

6. Locate the Directory Service object, and then double-click it.
7. Check the object attribute listing on the right side to determine whether the dsHeuristics attribute is already set. If it is set, copy the existing value to the clipboard and save it to a text file.

Build two LDIFDE import files using Notepad, one with the original dsHeuristics value noted in 7 (if the dsHeuristics value was set), and one with the value that allows new objects with a predetermined objectGUID. For example the values are:

objectguid-enable.ldif

dn: CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=contoso,dc=com

Changetype: modify

replace: dsHeuristics

dsHeuristics: 00000000011

-

objectguid-disable.ldif

dn: CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=contoso,dc=com

Changetype: modify

replace: dsHeuristics

dsHeuristics: 0

-

Note: There is a blank space after the - character.
Note: The dsHeuristics value in the objectguid-enable file will be equal to the merged value of the original setting and the 10th and 11th bit enabled. E.G.: If the value was originally set to 01, then the new value will be 01000000011.
Note: The dsHeuristics value in the objectguid-disable file will be equal to the value originally set for your forest.

Setting the dsHeurisitics to enable the fSpecifyGUIDOnAdd flag

https://msdn.microsoft.com/en-us/library/cc223560.aspx

1. Run the objectguid_enable.ldif file from an elevated command prompt using this command:

ldifde /i /f objectguid-enable.ldif

2. Create a temporary organizational unit (OU) and name it Temporary.

3. Create another Ldif file called user-cleanup.ldif. This creates the new user in the temporary OU.

For the problematic member, create a file in Notepad called user-cleanup.ldif:

Dn: cn=Cleanup-user1,ou=Temporary,dc=contoso,dc=com

Changetype: add

Objectclass: user

Objectguid:: b1lEpF9A20+6QB/UWhd2DA==

Note: If you find you have to add more than one user to fix this, it's a good idea to use different names for each new user to avoid follow-up failures on errors. When you run it for the first time, it's also a good idea to test using a single object to see whether the settings and LDIF input files are working.

Note: You need to convert the GUID of the problem user to Base64. That is where I get b1lEpF9A20+6QB/UWhd2DA== value above. I used this PowerShell code to obtain that Base64 conversion of the objectguid.

[System.Convert]::ToBase64String( [guid]::new("GUID_STRING_OF_THE OFFENDING OBJECT").toByteArray())

E.G.: [System.Convert]::ToBase64String([guid]::new("d11dafc2-1b54-471e-af32-626c9f3bf12a").toByteArray())

You need to use the same GUID as the deleted user that resides in the read only partition (GC).

4. Create the user by running the ldif file and allow for AD replication to converge across all of the DCs:

ldifde /i /f user-cleanup.ldif

5. Both the newly created object, which resides in a writable partition, and the offending object, which resides in the read-only partition, are "linked" because they share the same object GUID. Now, deleting the object in the writable partition will also remove the abandoned information in the GC.

6. After deleting the object, waiting for replication to converge, and confirming that the objects are gone, you may revert back dsHeuristics to its original value.

ldifde /i /f objectguid-disable.ldif

Additional Information

The requester is allowed to specify the objectGUID if the following five conditions are all satisfied:

The fSpecifyGUIDOnAdd heuristic is true in the dSHeuristics attribute (see section 6.1.1.2.4.1.2).

The requester has the Add-GUID control access right (section 5.1.3.2.1) on the NC root of the NC where the object is being added.

The requester-specified objectGUID is not currently in use in the forest.

Active Directory is operating as AD DS.

The requester-specified objectGUID is not the NULL GUID.