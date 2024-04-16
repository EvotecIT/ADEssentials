repadmin /options DC1.ad.evotec.pl +disable_ntdsconn_xlate
repadmin /unhost DC1.ad.evotec.pl "DC=AD,DC=EVOTEC,DC=XYZ"

repadmin /kcc DC1
repadmin /kcc DC1
repadmin /kcc DC1
repadmin /kcc DC1

# check log for 1658, 1660

Repadmin /add "DC=AD,DC=EVOTEC,DC=XYZ"  DC1.ad.evotec.pl AD2.ad.evotec.xyz /readonly

repadmin /showrepl DC1.ad.evotec.pl /v
repadmin /showrepl DC1.ad.evotec.pl /v
repadmin /showrepl DC1.ad.evotec.pl /v

repadmin /options DC1.ad.evotec.pl -disable_ntdsconn_xlate
repadmin /kcc DC1.ad.evotec.pl
Repadmin /showrepl DC1.ad.evotec.pl "DC=AD,DC=EVOTEC,DC=XYZ"

repadmin /replsum