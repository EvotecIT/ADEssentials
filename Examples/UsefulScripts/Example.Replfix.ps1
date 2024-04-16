<#
Generate an ldifde dump of just the replPropertyMetadata,objectGuid and replUptodateVector metadata for all objects in the affected naming context from a DC hosting a writable copy of the domain by using a LDFIDE export:
Make sure you are "Domain Admin", so you have access to all of the objects, including Deleted Objects container.
Prior to the exports, make the garbage collector run so the set of deleted objects is the same:


repadmin /setattr DCNAME "" doGarbageCollection add "1"



ldifde.exe -f ChiDC01-Child-389.ldf -d DC=Chi,DC=Contoso,DC=com -s ChiDC01.child.contoso.com -r "(objectclass=*)" -x -p subtree -l "replPropertyMetadata,objectGuid,replUptodateVector" -1

We're going to get two ldif exports - one from a writeable copy, and one from the GC copy


ldifde.exe -f ChiDC01-Child-389.ldf -d DC=Chi,DC=Contoso,DC=com -s ChiDC01.child.contoso.com -r "(objectclass=*)" -x -p subtree -l "replPropertyMetadata,objectGuid,replUptodateVector" -1




Second step:

Generate an ldifde dump of just the replPropertyMetadata,objectGuid and replUptodateVector metadata for all objects in the affected naming context from a GC hosting a read-only copy of the domain by using a LDFIDE export:
It would be preferred if you were doing this as "Enterprise Admin", so you have access to all of the objects, including Deleted Objects container. You can also consider running this as LocalSystem. For this you may consider PSEXEC to get a command line in this identity:
psexec /i /s cmd

Prior to the exports, make the garbage collector run so the set of deleted objects is the same:
repadmin /setattr DCNAME "" doGarbageCollection add "1"

ldifde.exe -f RootDC03-Chi-3268.ldf -d DC=Chi,DC=Contoso,DC=com -s RootDC03.contoso.com -r "(objectclass=*)" -x -p subtree -l "replPropertyMetadata,objectGuid,replUptodateVector" -t 3268 -1


You give me those two LDIF exports, and I run replfix on it to generate an LDIF that shows the difference -- i.e. objects that exist in the GC but not in the writeable copy
#>

repadmin /setattr ad1.ad.evotec.xyz "" doGarbageCollection add "1"



ldifde.exe -f ChiDC01-Child-389.ldf -d DC=Chi,DC=Contoso,DC=com -s ChiDC01.child.contoso.com -r "(objectclass=*)" -x -p subtree -l "replPropertyMetadata,objectGuid,replUptodateVector" -1