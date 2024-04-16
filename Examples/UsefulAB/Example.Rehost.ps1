repadmin /showobjmeta * CN=Schema,CN=Configuration,DC=ABB,DC=COM | findstr "objectVersion"


repadmin /rehost 'XP-S-EUR0555.europe.abb.com' "DC=ABB,DC=COM" "XP-S-ABB0032.abb.com"
repadmin /showrepl 'XP-S-EUR0555.europe.abb.com' "DC=ABB,DC=COM"

repadmin /showattr fsmo_schema: ncobj:schema: /filter:"(ismemberofpartialattributeset=TRUE)" /subtree /atts:dn >pas.txt
repadmin /showattr gc: "DC=AD,DC=EVOTEC,DC=XYZ" /gc /atts:partialattributeset >pas_domain.txt

Repadmin /showrepl <DestinationDC> /verbose >repl_destDC.txt
Repadmin /showrepl <SourceDC> /verbose >repl_sourceDC.txt
Repadmin /showrepl * /csv >showrepl.csv