

repadmin /showattr gc: "DC=ABB,DC=COM" /gc /atts:partialattributeset > ABB_pas_domain.txt

Repadmin /showrepl XP-S-NME0555 /verbose > ABB_repl_destDC.txt
Repadmin /showrepl XP-S-EUR0555 /verbose > ABB_repl_sourceDC.txt
Repadmin /showrepl * /csv > ABB_showrepl.csv

repadmin /showattr fsmo_schema: ncobj:schema: /filter:"(ismemberofpartialattributeset=TRUE)" /subtree /atts:dn > ABB_pas.txt