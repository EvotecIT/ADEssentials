This is a plan we can use if they have live lingering objects (change server names as necessary).  The recovery is actually to bring the live lingering objects BACK into the GCs...:

GC cleanup procedure for DC12.child.contoso.com (which is logging 8606):

Disable KCC on GC to rehost:
repadmin /options DC12.child.contoso.com +disable_ntdsconn_xlate

Unhost the GC:
repadmin /unhost DC12.child.contoso.com DC=child2,DC=contoso,DC=com

At this point, you may need to trigger the KCC multiple times to clean up the database (use "repadmin /kcc" multiple times).  Ensure the Directory Service event log of the DC12.child.contoso.com GC logs 1658 event(s) followed by a completion 1660 event.

Event ID 1658 is the status event logged in the Directory Services event log to indicate how many objects still need to be removed before the partition is completely removed.  Event ID 1660 is logged in the Directory Services event log when the partition has been successfully removed from the database.  Run the "repadin /kcc" command as many times as needed to result in the 1660 event.

Create temporary connection to GC from healthy DC (DC with the object):
Repadmin /add DC=child2,DC=contoso,DC=com DC12.child.contoso.com dc8.child.contoso.com /readonly
Or, if there is a local writable DC, fill in the appropriate root/other domain controller for <DCNAME>:
Repadmin /add DC=child2,DC=contoso,DC=com DC12.child.contoso.com DCNAME.child2.contoso.com /readonly


During this phase, please ensure that replication completes.  If it reports that replication was preempted, precede no further until replication of the partition completes.  You may use "repadmin /showrepl" on DC12.child.contoso.com to monitor replication (it has completed when the connection for DC=child2,DC=contoso,DC=com no longer reports last success at “(never)” and instead reports a recent time/date in the output).


Enable KCC on DC12.child.contoso.com:
repadmin /options DC12.child.contoso.com -disable_ntdsconn_xlate

Trigger the KCC on GC to build the necessary connections to other partners:
repadmin /kcc DC12.child.contoso.com

Verify necessary connections have been built by the KCC with partners:
Repadmin /showrepl DC12.child.contoso.com DC=child2,DC=contoso,DC=com


```powershell
# Disable KCC on GC
repadmin /options xp-s-eur0555.europe.abb.com +disable_ntdsconn_xlate

# Unhost the GC, it takes 15 minutes on big GCs
repadmin /unhost xp-s-eur0555.europe.abb.com "DC=ABB,DC=COM"

# At this point, you may need to trigger the KCC multiple times to clean up the database (use "repadmin /kcc" multiple times).  Ensure the Directory Service event log of the DC12.child.contoso.com GC logs 1658 event(s) followed by a completion 1660 event.
repadmin /kcc
repadmin /kcc
repadmin /kcc
repadmin /kcc

# check log for 1658, and wait for 1660
# this next command is the long running one (15 minutes+)
Repadmin /add "DC=abb,DC=com" xp-s-eur0555.europe.abb.com XP-S-EUR0666.europe.abb.com /readonly
Repadmin /add "DC=abb,DC=com" xp-s-eur0555.europe.abb.com XE-S-EUR0002.europe.abb.com /readonly
#Repadmin /add "DC=abb,DC=com" xp-s-eur0555.europe.abb.com XP-S-ABB0032.abb.com /readonly
#Repadmin /add "DC=abb,DC=com" xp-s-eur0555.europe.abb.com XP-S-ABB0031.abb.com /readonly
#Repadmin /add "DC=abb,DC=com" xp-s-eur0555.europe.abb.com XP-S-ABB0033.abb.com /readonly

# Once added, wait?  Check replication?

repadmin /showrepl xp-s-eur0555.europe.abb.com /V
repadmin /showrepl xp-s-eur0555.europe.abb.com
# wait and wait and wait
Repadmin /showrepl xp-s-eur0555.europe.abb.com "DC=abb,DC=com"
Repadmin /showrepl xp-s-eur0555.europe.abb.com "DC=abb,DC=com"
Repadmin /showrepl xp-s-eur0555.europe.abb.com "DC=abb,DC=com"


# Enable KCC, once replication shows up properly

repadmin /options xp-s-eur0555.europe.abb.com -disable_ntdsconn_xlate
repadmin /kcc xp-s-eur0555.europe.abb.com
Repadmin /showrepl xp-s-eur0555.europe.abb.com "DC=abb,DC=com"
```

Events:
1660,1658,1664,1869

Term: Abandoned delete / Live lingering object

Description: An object is deleted on one DC. The deletion is never replicated to other DCs hosting a writable copy of the NC for that object. The deletion replicates to DCs/GCs hosting a read-only copy of the NC. The DC that originated the object deletion goes offline prior to replicating the change to other DCs hosting a writable copy of the partition.

Notes:

Symptoms: GCs report source DCs have lingering objects in source DC partition:
Root.contoso.com: DC1 and DC2
Child.root.contoso.com: ChildDC1
ChildDC1 replicates Root partition from DC1 and replication fails with error 8606


# During replication you may get those while waitingf for replication to complete

https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/adrepl-troubleshoot-replication-error-8461


Cause
This replication status is returned when there are higher priority replication tasks in the destination DCs inbound queue. It doesn't indicate a failure condition; the replication task isn't cancelled, instead, the task is put into a holding pattern until the higher priority work is completed. It's normal to see this message returned periodically in larger environments, and it's important to note that the condition is transient.



 https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/replication-error-8477#cause


Cause
The 8477 (The replication request has been posted; waiting for reply) status is informational and represents normal Active Directory replication operation, indicating that replication is currently in progress from the source and hasn't yet been applied to the destination Domain Controllers database replica.


repadmin /queue



repadmin /showrepl /all