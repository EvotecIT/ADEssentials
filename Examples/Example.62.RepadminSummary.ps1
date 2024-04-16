Import-Module .\ADEssentials.psd1 -Force

$FIle = @"
Replication Summary Start Time: 2024-04-15 04:00:01



Beginning data collection for replication summary, this may take awhile:

  ..................................................

  ..................................................

  ........


Source DSA          largest delta    fails/total %%   error
 XE-S-APC0666          13h:39m:36s    0 /  99    0
 XE-S-EUR0002          13h:39m:36s    0 / 145    0
 XE-S-EUR0001          13h:39m:36s    0 / 145    0

 XE-S-EUR0003          13h:24m:40s    0 /  79    0

 KZ-S-EUR0222          04h:46m:38s    9 /   9  100  (1722) The RPC server is unavailable.

 XP-S-ABB0031              14m:37s    0 /  32    0

 XP-S-APC0003              14m:37s    0 /  28    0

 XP-S-APC0009              14m:37s    0 /  29    0

 XE-S-ABB0012              14m:32s    0 /  59    0

 XP-S-APC0010              14m:03s    0 /   9    0

 XE-S-ABB0011              13m:50s    0 /  62    0

 XF-S-EUR0224              13m:26s    0 /  25    0

 XA-S-AME0002              13m:09s    0 /  91    0

 XQ-S-NME0777              13m:07s    0 /  23    0

 XQ-S-APC0086              13m:07s    0 /  18    0

 IN-S-APC0039              13m:07s    0 /   9    0

 XQ-S-EUR0777              13m:07s    0 /  23    0

 CN-S-APC0092              12m:54s    0 /  18    0

 XP-S-ABB0032              12m:32s    0 /  59    0

 XP-S-ABB0033              12m:32s    0 /  35    0

 XE-S-AME0666              12m:27s    0 /  85    0

 XA-S-AME0001              12m:24s    0 /  30    0

 XE-S-NME0002              12m:23s    0 / 104    0

 SA-S-EUR0213              12m:19s    0 /  30    0

 PL-S-EUR0217              12m:19s    0 /  30    0

 AE-S-EUR0177              12m:17s    0 /  30    0

 XE-S-EUR0197              12m:15s    0 /  41    0

 XA-S-EUR0555              12m:15s    0 /  48    0

 XF-S-EUR0209              12m:15s    0 /  48    0

 IT-S-EUR0007              12m:13s    0 /  39    0

 XP-S-EUR0555              12m:13s    0 /  55    0

 ZA-S-EUR0211              12m:13s    0 /  30    0

 DE-S-EUR0218              12m:13s    0 /  48    0

 XA-S-EUR0666              12m:13s    0 /  48    0

 EG-S-EUR0202              12m:13s    0 /  30    0

 TR-S-EUR0221              12m:13s    0 /  30    0

 XE-S-NME0086              11m:24s    0 /  32    0

 XP-S-APC0083              11m:15s    0 /  46    0

 XF-S-APC0777              11m:15s    0 /  23    0

 XA-S-APC0666              11m:13s    0 /  41    0

 SE-S-NME0091              11m:13s    0 /  43    0

 FI-S-NME0092              11m:12s    0 /  25    0

 XA-S-AME0009              11m:10s    0 /  15    0

 XA-S-ABB0022              10m:57s    0 /  50    0

 XP-S-NME0555              10m:56s    0 /  66    0

 XA-S-ABB0021              10m:56s    0 /  57    0

 XQ-S-AME0777              10m:56s    0 /  23    0

 XA-S-AME0003              10m:51s    0 /  37    0

 XQ-S-ABB0033              10m:36s    0 /  23    0

 XB-S-ABB0023              10m:35s    0 /  32    0

 JP-S-APC0095              10m:21s    0 /   5    0

 AU-S-APC0088              10m:20s    0 /   5    0

 XB-S-NME0777              10m:18s    0 /  32    0

 XB-S-EUR0777              10m:12s    0 /  32    0

 XA-S-NME0555              10m:08s    0 /  59    0

 US-S-AME0196              10m:07s    0 /   9    0

 US-S-AME0182              10m:06s    0 /   9    0

 XE-S-NME0001              10m:05s    0 / 104    0

 XA-S-NME0666              10m:05s    0 /  59    0

 XE-S-NME0003              10m:01s    0 /  97    0

 XB-S-APC0777              09m:58s    0 /  23    0

 XA-S-APC0555              09m:47s    0 /  23    0

 XE-S-APC0555              09m:22s    0 /  30    0

 XQ-S-APC0085              09m:22s    0 /   9    0

 XA-S-AME0184              09m:21s    0 /  36    0

 CN-S-APC0093              09m:00s    0 /   9    0

 XQ-S-APC0004              09m:00s    0 /  41    0

 IT-S-EUR0080              08m:39s    0 /  18    0

 DE-S-EUR0220              08m:02s    0 /   9    0

 DE-S-EUR0219              08m:02s    0 /   9    0

 XP-S-APC0001              07m:33s    0 /  42    0

 XP-S-APC0002              07m:30s    0 /  46    0

 IN-S-APC0038              07m:30s    0 /  18    0

 CZ-S-EUR0212              07m:02s    0 /   9    0

 XF-S-NME0004              05m:36s    0 /  50    0

 XB-S-AME0004              05m:22s    0 /  32    0

 XF-S-NME0089              05m:09s    0 /  25    0

 FI-S-NME0093              05m:06s    0 /  18    0

 XB-S-AME0186              05m:04s    0 /  18    0

 XF-S-NME0088              04m:53s    0 /  16    0

 XP-S-AME0666              04m:51s    0 /  25    0

 XP-S-APC0084              04m:38s    0 /  18    0

 XP-S-AME0555              04m:28s    0 /  28    0

 CA-S-AME0177              04m:20s    0 /   9    0

 US-S-AME0180              04m:19s    0 /   9    0

 XP-S-EUR0666              04m:06s    0 /  23    0

 XA-S-AME0183              04m:05s    0 /  27    0

 XE-S-EUR0010              04m:04s    0 /  39    0

 NO-S-NME0095              03m:37s    0 /  34    0

 XB-S-AME0185              03m:33s    0 /   9    0

 BR-S-AME0197              03m:29s    0 /   9    0

 US-S-AME0193              03m:26s    0 /   9    0

 CL-S-AME0194              03m:26s    0 /   9    0

 XP-S-NME0666              03m:26s    0 /  26    0

 XE-S-NME0010              03m:03s    0 /  34    0

 XE-S-AME0555              02m:45s    0 /  16    0

 XE-S-NME0087              02m:36s    0 /  41    0

 IT-S-EUR0223              02m:11s    0 /   9    0

 XF-S-EUR0004              02m:06s    0 /  25    0

 SE-S-NME0090              01m:49s    0 /   9    0

 XE-S-EUR0207              01m:14s    0 /  25    0

 XF-S-ABB0013              01m:06s    0 /  32    0

 XF-S-AME0777                 :51s    0 /  23    0

 XE-S-EUR0208                 :46s    0 /  18    0

 XF-S-EUR0210                   0s    0 /  16    0





Destination DSA     largest delta    fails/total %%   error

 PL-S-EUR0217          13h:41m:53s    0 /  30    0

 XF-S-EUR0004          04h:47m:26s    9 /  43   20  (1722) The RPC server is unavailable.

 XE-S-ABB0011              17m:30s    0 /  63    0

 XE-S-ABB0012              17m:25s    0 /  59    0

 XF-S-EUR0210              15m:43s    0 /  25    0

 XA-S-AME0009              15m:41s    0 /  15    0

 XE-S-EUR0001              15m:17s    0 / 145    0

 XP-S-APC0084              15m:17s    0 /  18    0

 XP-S-APC0083              15m:15s    0 /  42    0

 IN-S-APC0038              15m:05s    0 /   9    0

 XP-S-ABB0031              15m:01s    0 /  32    0

 XE-S-EUR0010              14m:51s    0 /  32    0

 XA-S-AME0003              14m:43s    0 /  37    0

 XE-S-NME0086              14m:40s    0 /  34    0

 BR-S-AME0197              14m:17s    0 /   9    0

 XQ-S-APC0004              13m:57s    0 /  37    0

 XQ-S-ABB0033              13m:56s    0 /  23    0

 XB-S-ABB0023              13m:52s    0 /  32    0

 DE-S-EUR0220              13m:49s    0 /   9    0

 XQ-S-NME0777              13m:38s    0 /  23    0

 XA-S-AME0184              13m:22s    0 /  27    0

 XA-S-NME0555              13m:21s    0 /  59    0

 XA-S-AME0001              13m:20s    0 /  30    0

 XQ-S-EUR0777              13m:14s    0 /  23    0

 US-S-AME0193              13m:10s    0 /   9    0

 XA-S-EUR0555              13m:06s    0 /  55    0

 XA-S-APC0555              13m:05s    0 /  23    0

 XA-S-NME0666              12m:56s    0 /  59    0

 XA-S-ABB0022              12m:55s    0 /  50    0

 XF-S-AME0777              12m:22s    0 /  23    0

 XA-S-ABB0021              12m:22s    0 /  50    0

 XA-S-EUR0666              12m:22s    0 /  55    0

 XQ-S-APC0086              12m:21s    0 /   9    0

 IT-S-EUR0223              12m:14s    0 /   9    0

 XE-S-APC0666              12m:12s    0 /  99    0

 CN-S-APC0092              12m:03s    0 /  18    0

 XP-S-APC0009              12m:00s    0 /  28    0

 XB-S-NME0777              11m:22s    0 /  32    0

 CL-S-AME0194              11m:13s    0 /   9    0

 CA-S-AME0177              10m:53s    0 /   9    0

 XF-S-APC0777              10m:01s    0 /  23    0

 XQ-S-APC0085              09m:46s    0 /  18    0

 XF-S-EUR0209              09m:19s    0 /  39    0

 IN-S-APC0039              09m:00s    0 /  18    0

 JP-S-APC0095              08m:28s    0 /   9    0

 FI-S-NME0092              08m:19s    0 /  25    0

 DE-S-EUR0218              08m:06s    0 /  48    0

 XF-S-NME0088              07m:59s    0 /  16    0

 XF-S-NME0089              07m:53s    0 /  25    0

 SE-S-NME0090              07m:35s    0 /   9    0

 FI-S-NME0093              07m:33s    0 /  27    0

 XP-S-AME0555              07m:26s    0 /  29    0

 XE-S-NME0003              07m:14s    0 /  79    0

 SA-S-EUR0213              07m:11s    0 /  30    0

 TR-S-EUR0221              07m:10s    0 /  30    0

 ZA-S-EUR0211              06m:57s    0 /  30    0

 US-S-AME0182              06m:55s    0 /   9    0

 XP-S-NME0666              06m:47s    0 /  27    0

 XB-S-AME0185              06m:44s    0 /  18    0

 XA-S-APC0666              06m:43s    0 /  41    0

 XE-S-EUR0003              06m:43s    0 /  78    0

 XP-S-NME0555              06m:41s    0 /  59    0

 XB-S-AME0004              06m:23s    0 /  32    0

 XP-S-APC0001              06m:14s    0 /  51    0

 XP-S-APC0002              06m:04s    0 /  42    0

 XP-S-ABB0032              06m:01s    0 /  59    0

 XE-S-AME0555              05m:58s    0 /  23    0

 XP-S-AME0666              05m:56s    0 /  32    0

 XE-S-EUR0002              05m:56s    0 / 145    0

 XE-S-NME0087              05m:55s    0 /  41    0

 EG-S-EUR0202              05m:41s    0 /  30    0

 XB-S-EUR0777              05m:41s    0 /  32    0

 AU-S-APC0088              05m:40s    0 /   9    0

 CZ-S-EUR0212              05m:38s    0 /   9    0

 XA-S-AME0002              05m:38s    0 /  84    0

 XQ-S-AME0777              05m:33s    0 /  23    0

 XA-S-AME0183              05m:31s    0 /  36    0

 XE-S-NME0010              05m:29s    0 /  34    0

 XB-S-APC0777              05m:25s    0 /  23    0

 IT-S-EUR0080              05m:25s    0 /  18    0

 XE-S-NME0001              05m:14s    0 /  97    0

 XF-S-EUR0224              05m:11s    0 /  16    0

 XP-S-APC0003              05m:02s    0 /  21    0

 SE-S-NME0091              05m:01s    0 /  43    0

 XE-S-EUR0207              04m:59s    0 /  34    0

 XE-S-NME0002              04m:59s    0 / 104    0

 XB-S-AME0186              04m:58s    0 /   9    0

 IT-S-EUR0007              04m:44s    0 /  39    0

 XP-S-ABB0033              04m:37s    0 /  36    0

 XE-S-APC0555              04m:21s    0 /  23    0

 CN-S-APC0093              04m:20s    0 /   9    0

 AE-S-EUR0177              04m:20s    0 /  30    0

 XF-S-ABB0013              04m:19s    0 /  32    0

 XF-S-NME0004              04m:09s    0 /  50    0

 NO-S-NME0095              03m:50s    0 /  34    0

 XE-S-EUR0208              03m:42s    0 /  27    0

 XE-S-EUR0197              03m:35s    0 /  37    0

 US-S-AME0196              03m:30s    0 /   9    0

 XP-S-EUR0666              03m:28s    0 /  23    0

 XP-S-EUR0555              03m:16s    0 /  55    0

 DE-S-EUR0219              02m:38s    0 /   9    0

 XE-S-AME0666              01m:13s    0 /  92    0

 XP-S-APC0010              01m:11s    0 /   9    0

 US-S-AME0180                 :41s    0 /   9    0





Experienced the following operational errors trying to retrieve replication information:

          58 - KZ-S-EUR0222.europe.abb.com

"@

$File2 = @"
Replication Summary Start Time: 2024-03-31 03:00:02



Beginning data collection for replication summary, this may take awhile:

  ..................................................

  ..................................................

  ........





Source DSA          largest delta    fails/total %%   error

 XP-S-EUR0555     >60 days            5 /  55    9  (8606) Insufficient attributes were given to create an object. This object may not exist because it may have been deleted and already garbage collected.

 XA-S-AME0002              13m:25s    0 /  91    0

 XA-S-AME0183              13m:21s    0 /  27    0

 XB-S-AME0004              13m:13s    0 /  32    0

 XF-S-EUR0209              13m:09s    0 /  25    0

 KZ-S-EUR0222              13m:09s    0 /   9    0

 XE-S-EUR0002              13m:09s    0 / 145    0

 XF-S-NME0004              13m:09s    0 /  50    0

 XE-S-EUR0001              13m:09s    0 / 145    0

 XE-S-AME0666              13m:06s    0 /  85    0

 XB-S-APC0777              13m:05s    0 /  23    0

 XE-S-APC0666              13m:05s    0 /  92    0

 XB-S-AME0185              12m:55s    0 /   9    0

 NO-S-NME0095              12m:53s    0 /  34    0

 TR-S-EUR0221              12m:53s    0 /  30    0

 DE-S-EUR0218              12m:53s    0 /  48    0

 XE-S-ABB0012              12m:53s    0 /  59    0

 XE-S-NME0086              12m:53s    0 /  50    0

 XE-S-AME0555              12m:53s    0 /  16    0

 XE-S-NME0003              12m:53s    0 /  97    0

 XE-S-APC0555              12m:53s    0 /  30    0

 IT-S-EUR0007              12m:51s    0 /  39    0

 EG-S-EUR0202              12m:51s    0 /  30    0

 SA-S-EUR0213              12m:50s    0 /  30    0

 PL-S-EUR0217              12m:50s    0 /  30    0

 XF-S-APC0777              12m:47s    0 /  23    0

 ZA-S-EUR0211              12m:47s    0 /  30    0

 XP-S-APC0083              12m:47s    0 /  53    0

 AE-S-EUR0177              12m:45s    0 /  30    0

 XA-S-APC0666              12m:45s    0 /  41    0

 SE-S-NME0091              12m:44s    0 /  43    0

 FI-S-NME0092              12m:44s    0 /  25    0

 XB-S-AME0186              12m:43s    0 /  18    0

 XF-S-AME0777              12m:43s    0 /  23    0

 XP-S-APC0003              12m:43s    0 /  28    0

 XP-S-APC0009              12m:43s    0 /  24    0

 XP-S-ABB0031              12m:43s    0 /  39    0

 XP-S-AME0666              12m:43s    0 /  25    0

 XP-S-APC0002              12m:42s    0 /  55    0

 JP-S-APC0095              12m:42s    0 /   5    0

 XP-S-AME0555              12m:42s    0 /  37    0

 XP-S-APC0001              12m:42s    0 /  42    0

 AU-S-APC0088              12m:40s    0 /   5    0

 XF-S-EUR0004              12m:26s    0 /  57    0

 XE-S-ABB0011              12m:18s    0 /  62    0

 XA-S-ABB0022              12m:05s    0 /  50    0

 IT-S-EUR0223              12m:02s    0 /  18    0

 XE-S-EUR0003              12m:02s    0 /  83    0

 XA-S-APC0555              12m:00s    0 /  23    0

 XA-S-ABB0021              11m:45s    0 /  48    0

 XP-S-EUR0666              11m:43s    0 /  23    0

 XP-S-NME0555              11m:43s    0 /  59    0

 XP-S-ABB0033              11m:43s    0 /  42    0

 SE-S-NME0090              11m:36s    0 /   9    0

 XF-S-NME0089              11m:35s    0 /  25    0

 XE-S-NME0001              11m:35s    0 /  97    0

 XE-S-NME0002              11m:34s    0 / 104    0

 XE-S-EUR0197              11m:28s    0 /  32    0

 XE-S-EUR0207              11m:28s    0 /  25    0

 XE-S-NME0010              11m:28s    0 /  25    0

 XA-S-EUR0666              11m:27s    0 /  48    0

 XF-S-EUR0224              11m:20s    0 /  25    0

 XA-S-AME0001              11m:19s    0 /  30    0

 XB-S-ABB0023              11m:18s    0 /  32    0

 XP-S-NME0666              11m:16s    0 /  26    0

 XF-S-ABB0013              11m:16s    0 /  32    0

 XP-S-ABB0032              11m:16s    0 /  59    0

 XA-S-NME0666              11m:15s    0 /  59    0

 XF-S-NME0088              11m:14s    0 /  16    0

 DE-S-EUR0219              11m:07s    0 /   9    0

 DE-S-EUR0220              11m:07s    0 /   9    0

 XE-S-NME0087              11m:06s    0 /  41    0

 XB-S-NME0777              11m:03s    0 /  32    0

 XA-S-AME0009              11m:02s    0 /  15    0

 XA-S-AME0003              11m:00s    0 /  37    0

 XA-S-NME0555              10m:58s    0 /  50    0

 XF-S-EUR0210              10m:58s    0 /  16    0

 BR-S-AME0197              10m:56s    0 /   9    0

 XB-S-EUR0777              10m:54s    0 /  32    0

 XA-S-EUR0555              10m:53s    0 /  39    0

 XA-S-AME0184              10m:51s    0 /  36    0

 CL-S-AME0194              10m:51s    0 /   9    0

 US-S-AME0193              10m:50s    0 /   9    0

 XE-S-EUR0010              10m:46s    0 /  43    0

 US-S-AME0196              10m:44s    0 /   9    0

 US-S-AME0182              10m:43s    0 /   9    0

 FI-S-NME0093              10m:40s    0 /  27    0

 XQ-S-EUR0777              09m:57s    0 /  46    0

 IN-S-APC0038              09m:19s    0 /  18    0

 XQ-S-AME0777              09m:05s    0 /  23    0

 XQ-S-APC0004              08m:46s    0 /  41    0

 XQ-S-ABB0033              08m:29s    0 /  23    0

 XP-S-APC0084              07m:49s    0 /  18    0

 CZ-S-EUR0212              07m:31s    0 /   9    0

 XQ-S-APC0085              07m:15s    0 /   9    0

 CN-S-APC0093              07m:11s    0 /   9    0

 XQ-S-NME0777              06m:14s    0 /  23    0

 XE-S-EUR0208              05m:32s    0 /  23    0

 CA-S-AME0177              05m:07s    0 /   9    0

 US-S-AME0180              05m:06s    0 /   9    0

 XP-S-APC0010              05m:03s    0 /   9    0

 CN-S-APC0092              05m:00s    0 /  18    0

 IN-S-APC0039              04m:10s    0 /   9    0

 IT-S-EUR0080              02m:26s    0 /   9    0

 XQ-S-APC0086              02m:10s    0 /  18    0





Destination DSA     largest delta    fails/total %%   error

 SA-S-EUR0213        (unknown)        0 /  25    0

 XP-S-NME0555     >60 days            1 /  66    1  (8606) Insufficient attributes were given to create an object. This object may not exist because it may have been deleted and already garbage collected.

 XP-S-EUR0666     >60 days            1 /  30    3  (8606) Insufficient attributes were given to create an object. This object may not exist because it may have been deleted and already garbage collected.

 XE-S-EUR0001     >60 days            1 / 154    0  (8606) Insufficient attributes were given to create an object. This object may not exist because it may have been deleted and already garbage collected.

 XQ-S-EUR0777     >60 days            1 /  46    2  (8606) Insufficient attributes were given to create an object. This object may not exist because it may have been deleted and already garbage collected.

 XF-S-NME0004              15m:31s    0 /  50    0

 XE-S-ABB0012              15m:24s    0 /  59    0

 XA-S-AME0003              14m:45s    0 /  37    0

 XF-S-ABB0013              14m:41s    0 /  32    0

 IT-S-EUR0007              14m:33s    0 /  39    0

 SE-S-NME0091              14m:22s    0 /  43    0

 XP-S-APC0002              14m:21s    0 /  42    0

 XB-S-ABB0023              14m:15s    0 /  23    0

 TR-S-EUR0221              14m:12s    0 /  12    0

 XB-S-AME0185              14m:12s    0 /  18    0

 BR-S-AME0197              14m:11s    0 /   9    0

 XA-S-AME0009              14m:06s    0 /  15    0

 XP-S-NME0666              14m:02s    0 /  27    0

 XF-S-NME0088              13m:58s    0 /  16    0

 XB-S-AME0186              13m:56s    0 /   9    0

 XP-S-APC0009              13m:56s    0 /  28    0

 XF-S-NME0089              13m:55s    0 /  25    0

 XA-S-NME0555              13m:54s    0 /  59    0

 XA-S-AME0001              13m:49s    0 /  30    0

 FI-S-NME0092              13m:43s    0 /  25    0

 XA-S-EUR0555              13m:39s    0 /  55    0

 XF-S-EUR0004              13m:37s    0 /  43    0

 CZ-S-EUR0212              13m:37s    0 /   9    0

 XA-S-APC0555              13m:34s    0 /  23    0

 XA-S-AME0184              13m:32s    0 /  27    0

 XA-S-APC0666              13m:32s    0 /  41    0

 US-S-AME0196              13m:27s    0 /   9    0

 AE-S-EUR0177              13m:25s    0 /  30    0

 ZA-S-EUR0211              13m:24s    0 /  30    0

 XE-S-AME0666              13m:21s    0 /  92    0

 XE-S-APC0666              13m:21s    0 /  92    0

 XE-S-NME0087              13m:18s    0 /  41    0

 NO-S-NME0095              13m:17s    0 /  34    0

 XA-S-NME0666              13m:08s    0 /  59    0

 XA-S-ABB0022              13m:07s    0 /  50    0

 XP-S-ABB0031              13m:00s    0 /  32    0

 XE-S-NME0010              12m:56s    0 /  34    0

 XP-S-ABB0033              12m:55s    0 /  36    0

 XF-S-APC0777              12m:49s    0 /  23    0

 FI-S-NME0093              12m:46s    0 /  27    0

 JP-S-APC0095              12m:45s    0 /   9    0

 XE-S-EUR0197              12m:45s    0 /  41    0

 XA-S-ABB0021              12m:43s    0 /  50    0

 XA-S-AME0002              12m:38s    0 /  84    0

 XA-S-EUR0666              12m:34s    0 /  55    0

 XE-S-AME0555              12m:26s    0 /  20    0

 DE-S-EUR0219              12m:24s    0 /   9    0

 XE-S-NME0086              12m:08s    0 /  34    0

 XE-S-NME0001              12m:05s    0 /  97    0

 XF-S-AME0777              11m:42s    0 /  23    0

 XE-S-EUR0002              11m:38s    1 / 154    0  (8606) Insufficient attributes were given to create an object. This object may not exist because it may have been deleted and already garbage collected.

 XF-S-EUR0210              11m:38s    0 /  25    0

 XE-S-EUR0208              11m:37s    0 /  23    0

 KZ-S-EUR0222              11m:34s    0 /   9    0

 EG-S-EUR0202              11m:32s    0 /  30    0

 XQ-S-ABB0033              11m:30s    0 /  23    0

 DE-S-EUR0218              11m:11s    0 /  48    0

 XQ-S-NME0777              11m:02s    0 /  23    0

 XE-S-NME0002              11m:00s    0 / 104    0

 IN-S-APC0039              10m:55s    0 /  18    0

 XE-S-NME0003              10m:28s    0 /  97    0

 AU-S-APC0088              10m:06s    0 /   9    0

 XP-S-APC0010              09m:49s    0 /   9    0

 CN-S-APC0092              09m:48s    0 /  18    0

 XQ-S-APC0086              09m:47s    0 /   9    0

 SE-S-NME0090              09m:34s    0 /   9    0

 XF-S-EUR0209              09m:21s    0 /  39    0

 PL-S-EUR0217              08m:54s    0 /  30    0

 XE-S-EUR0207              08m:20s    0 /  34    0

 XP-S-AME0555              08m:17s    0 /  29    0

 XE-S-APC0555              07m:41s    0 /  23    0

 XE-S-EUR0003              07m:34s    0 /  83    0

 XP-S-APC0083              06m:55s    0 /  42    0

 XB-S-AME0004              06m:41s    0 /  32    0

 XP-S-ABB0032              06m:36s    0 /  59    0

 XP-S-AME0666              06m:32s    0 /  32    0

 CN-S-APC0093              06m:28s    0 /   9    0

 XP-S-APC0003              06m:21s    0 /  21    0

 XP-S-EUR0555              06m:06s    0 /  55    0

 XB-S-APC0777              06m:02s    0 /  23    0

 XB-S-EUR0777              06m:01s    0 /  23    0

 XA-S-AME0183              05m:57s    0 /  36    0

 XP-S-APC0084              05m:54s    0 /  18    0

 XE-S-EUR0010              05m:48s    0 /  32    0

 IN-S-APC0038              05m:41s    0 /   9    0

 IT-S-EUR0223              05m:34s    0 /   9    0

 XB-S-NME0777              05m:33s    0 /  23    0

 IT-S-EUR0080              05m:29s    0 /  18    0

 XQ-S-AME0777              03m:35s    0 /  32    0

 US-S-AME0182              03m:14s    0 /   9    0

 XE-S-ABB0011              03m:12s    0 /  63    0

 XF-S-EUR0224              03m:05s    0 /  16    0

 XQ-S-APC0085              02m:48s    0 /  18    0

 XQ-S-APC0004              02m:00s    0 /  41    0

 XP-S-APC0001              01m:46s    0 /  51    0

 CL-S-AME0194              01m:31s    0 /   9    0

 US-S-AME0180                 :35s    0 /   9    0

 DE-S-EUR0220                 :22s    0 /   9    0

 US-S-AME0193                 :04s    0 /   9    0

 CA-S-AME0177                 :01s    0 /   9    0





"@

$File3 = @"
Replication Summary Start Time: 2024-03-25 02:00:02



Beginning data collection for replication summary, this may take awhile:

  ..................................................

  ..................................................

  ........





Source DSA          largest delta    fails/total %%   error

 XP-S-EUR0555     >60 days            5 /  55    9  (8606) Insufficient attributes were given to create an object. This object may not exist because it may have been deleted and already garbage collected.

 CL-S-AME0194      01d.14h:42m:27s    9 /   9  100  (1722) The RPC server is unavailable.

 XE-S-ABB0012          06h:09m:04s   59 /  59  100  (1722) The RPC server is unavailable.

 XF-S-EUR0209              14m:24s    0 /  34    0

 XF-S-NME0004              14m:24s    0 /  50    0

 KZ-S-EUR0222              14m:22s    0 /   9    0

 XE-S-EUR0002              14m:22s    0 / 154    0

 XE-S-EUR0001              14m:22s    0 / 161    0

 XA-S-AME0002              13m:38s    0 /  82    0

 XA-S-AME0183              13m:37s    0 /  27    0

 XB-S-AME0004              13m:33s    0 /  32    0

 XB-S-AME0186              13m:33s    0 /  18    0

 XB-S-AME0185              13m:32s    0 /   9    0

 XB-S-APC0777              13m:26s    0 /  23    0

 XB-S-EUR0777              13m:26s    0 /  32    0

 XA-S-AME0184              13m:24s    0 /  36    0

 CA-S-AME0177              13m:24s    0 /   9    0

 US-S-AME0180              13m:23s    0 /   9    0

 XA-S-ABB0022              13m:23s    0 /  41    0

 XE-S-APC0666              13m:23s    0 /  92    0

 XA-S-ABB0021              13m:23s    0 /  48    0

 XA-S-APC0555              13m:23s    0 /  23    0

 XE-S-EUR0003              13m:20s    0 /  88    0

 XE-S-AME0666              13m:20s    0 /  85    0

 XA-S-APC0666              13m:14s    0 /  41    0

 XB-S-NME0777              13m:14s    0 /  32    0

 NO-S-NME0095              13m:12s    0 /  34    0

 XE-S-AME0555              13m:12s    0 /  16    0

 XE-S-APC0555              13m:12s    0 /  23    0

 TR-S-EUR0221              13m:11s    0 /  30    0

 EG-S-EUR0202              13m:10s    0 /  30    0

 IT-S-EUR0007              13m:10s    0 /  39    0

 XE-S-NME0003              13m:06s    0 /  97    0

 ZA-S-EUR0211              13m:06s    0 /  30    0

 XE-S-NME0086              13m:06s    0 /  41    0

 DE-S-EUR0218              13m:05s    0 /  48    0

 AE-S-EUR0177              13m:04s    0 /  30    0

 PL-S-EUR0217              13m:03s    0 /  30    0

 SA-S-EUR0213              13m:03s    0 /  30    0

 XF-S-AME0777              13m:02s    0 /  23    0

 XF-S-APC0777              13m:00s    0 /  23    0

 XP-S-APC0083              13m:00s    0 /  53    0

 XP-S-AME0555              12m:59s    0 /  37    0

 SE-S-NME0091              12m:58s    0 /  43    0

 FI-S-NME0092              12m:57s    0 /  16    0

 CN-S-APC0092              12m:53s    0 /  18    0

 XB-S-ABB0023              12m:46s    0 /  32    0

 XA-S-NME0555              12m:46s    0 /  59    0

 XP-S-AME0666              12m:45s    0 /  25    0

 XP-S-APC0002              12m:45s    0 /  55    0

 JP-S-APC0095              12m:45s    0 /   5    0

 XP-S-APC0009              12m:45s    0 /  24    0

 XP-S-ABB0031              12m:45s    0 /  39    0

 XP-S-APC0003              12m:45s    0 /  28    0

 XA-S-NME0666              12m:45s    0 /  59    0

 XP-S-APC0001              12m:45s    0 /  42    0

 AU-S-APC0088              12m:44s    0 /   5    0

 XF-S-EUR0004              12m:35s    0 /  48    0

 XA-S-AME0001              12m:34s    0 /  30    0

 XF-S-ABB0013              12m:30s    0 /  23    0

 IN-S-APC0038              12m:27s    0 /  18    0

 XA-S-AME0009              12m:25s    0 /  15    0

 XA-S-AME0003              12m:25s    0 /  37    0

 BR-S-AME0197              12m:23s    0 /   9    0

 XE-S-ABB0011              12m:20s    0 /  53    0

 XF-S-EUR0224              12m:17s    0 /  25    0

 XF-S-NME0088              12m:17s    0 /  16    0

 XF-S-NME0089              12m:16s    0 /  25    0

 XF-S-EUR0210              12m:16s    0 /  16    0

 XA-S-EUR0666              12m:07s    0 /  48    0

 XA-S-EUR0555              12m:06s    0 /  48    0

 XP-S-ABB0033              11m:49s    0 /  42    0

 XP-S-NME0555              11m:49s    0 /  59    0

 XP-S-EUR0666              11m:49s    0 /  23    0

 XE-S-EUR0207              11m:46s    0 /  34    0

 XE-S-NME0010              11m:46s    0 /  43    0

 XE-S-EUR0197              11m:46s    0 /  37    0

 US-S-AME0193              11m:40s    0 /   9    0

 XE-S-NME0002              11m:38s    0 / 104    0

 XE-S-NME0001              11m:37s    0 /  97    0

 DE-S-EUR0219              11m:23s    0 /   9    0

 DE-S-EUR0220              11m:23s    0 /   9    0

 XP-S-NME0666              11m:20s    0 /  26    0

 IN-S-APC0039              11m:20s    0 /   9    0

 XP-S-ABB0032              11m:20s    0 /  50    0

 XE-S-NME0087              11m:14s    0 /  32    0

 XE-S-EUR0010              11m:06s    0 /  25    0

 FI-S-NME0093              11m:03s    0 /  36    0

 XQ-S-EUR0777              10m:26s    0 /  46    0

 XE-S-EUR0208              10m:16s    0 /  27    0

 XQ-S-AME0777              10m:01s    0 /  23    0

 XQ-S-APC0004              09m:38s    0 /  41    0

 XQ-S-ABB0033              09m:20s    0 /  23    0

 XQ-S-APC0085              08m:11s    0 /   9    0

 XP-S-APC0084              07m:55s    0 /  18    0

 CZ-S-EUR0212              07m:47s    0 /   9    0

 CN-S-APC0093              07m:23s    0 /   9    0

 XQ-S-NME0777              06m:18s    0 /  23    0

 IT-S-EUR0080              05m:57s    0 /  18    0

 XP-S-APC0010              05m:06s    0 /   9    0

 XQ-S-APC0086              03m:08s    0 /  18    0

 IT-S-EUR0223              02m:59s    0 /   9    0

 US-S-AME0196                   0s    0 /   9    0

 US-S-AME0182                   0s    0 /   9    0

 SE-S-NME0090                   0s    0 /   9    0





Destination DSA     largest delta    fails/total %%   error

 XP-S-NME0555     >60 days            1 /  66    1  (8606) Insufficient attributes were given to create an object. This object may not exist because it may have been deleted and already garbage collected.

 XP-S-EUR0666     >60 days            1 /  30    3  (8606) Insufficient attributes were given to create an object. This object may not exist because it may have been deleted and already garbage collected.

 XE-S-EUR0001     >60 days            1 / 154    0  (8606) Insufficient attributes were given to create an object. This object may not exist because it may have been deleted and already garbage collected.

 XQ-S-EUR0777     >60 days            1 /  46    2  (8606) Insufficient attributes were given to create an object. This object may not exist because it may have been deleted and already garbage collected.

 XA-S-AME0002      01d.14h:44m:23s    9 /  84   10  (1722) The RPC server is unavailable.

 XE-S-NME0002          06h:11m:10s    7 / 111    6  (1722) The RPC server is unavailable.

 XE-S-APC0555          06h:08m:42s    7 /  30   23  (1722) The RPC server is unavailable.

 XF-S-ABB0013          06h:00m:25s    9 /  32   28  (1256) The remote system is not available. For information about network troubleshooting, see Windows Help.

 XA-S-ABB0022          06h:00m:00s    9 /  50   18  (1256) The remote system is not available. For information about network troubleshooting, see Windows Help.

 XA-S-ABB0021          05h:59m:22s    9 /  50   18  (1256) The remote system is not available. For information about network troubleshooting, see Windows Help.

 XP-S-ABB0032          05h:51m:36s    9 /  59   15  (1256) The remote system is not available. For information about network troubleshooting, see Windows Help.

 XE-S-ABB0011          05h:49m:28s    9 /  63   14  (1256) The remote system is not available. For information about network troubleshooting, see Windows Help.

 XF-S-NME0004              16m:51s    0 /  50    0

 XA-S-APC0555              16m:07s    0 /  23    0

 XA-S-AME0001              16m:01s    0 /  30    0

 XA-S-AME0009              15m:58s    0 /  15    0

 XA-S-NME0555              15m:57s    0 /  59    0

 XA-S-AME0184              15m:41s    0 /  27    0

 XA-S-EUR0555              15m:38s    0 /  55    0

 XB-S-ABB0023              15m:18s    0 /  32    0

 XF-S-NME0088              15m:17s    0 /  16    0

 XA-S-NME0666              15m:15s    0 /  59    0

 XF-S-EUR0004              15m:01s    0 /  43    0

 FI-S-NME0092              15m:00s    0 /  25    0

 XB-S-AME0186              14m:46s    0 /   9    0

 XP-S-NME0666              14m:46s    0 /  27    0

 XB-S-AME0185              14m:45s    0 /  18    0

 TR-S-EUR0221              14m:43s    0 /  30    0

 XP-S-APC0002              14m:37s    0 /  42    0

 BR-S-AME0197              14m:36s    0 /   9    0

 CN-S-APC0093              14m:36s    0 /   9    0

 XB-S-AME0004              14m:35s    0 /  32    0

 XA-S-AME0183              14m:25s    0 /  36    0

 XF-S-NME0089              14m:23s    0 /  25    0

 ZA-S-EUR0211              14m:13s    0 /  30    0

 XP-S-APC0009              14m:13s    0 /  28    0

 XA-S-EUR0666              14m:08s    0 /  55    0

 XA-S-APC0666              13m:59s    0 /  41    0

 XB-S-NME0777              13m:52s    0 /  32    0

 XE-S-NME0087              13m:52s    0 /  41    0

 XE-S-AME0666              13m:49s    0 /  92    0

 IN-S-APC0039              13m:46s    0 /  18    0

 XP-S-ABB0031              13m:43s    0 /  32    0

 XE-S-APC0666              13m:43s    0 /  92    0

 US-S-AME0196              13m:43s    0 /   9    0

 NO-S-NME0095              13m:43s    0 /  34    0

 XE-S-EUR0197              13m:42s    0 /  41    0

 AE-S-EUR0177              13m:25s    0 /  30    0

 XB-S-APC0777              13m:23s    0 /  23    0

 XE-S-AME0555              13m:23s    0 /  20    0

 DE-S-EUR0219              13m:22s    0 /   9    0

 XE-S-NME0010              13m:20s    0 /  34    0

 SE-S-NME0090              13m:12s    0 /   9    0

 XP-S-ABB0033              13m:12s    0 /  36    0

 XF-S-APC0777              13m:08s    0 /  23    0

 IN-S-APC0038              13m:07s    0 /   9    0

 FI-S-NME0093              13m:06s    0 /  27    0

 XF-S-AME0777              13m:05s    0 /  23    0

 JP-S-APC0095              13m:05s    0 /   9    0

 XQ-S-ABB0033              13m:04s    0 /  23    0

 XE-S-NME0001              13m:00s    0 /  97    0

 XE-S-EUR0002              12m:41s    1 / 154    0  (8606) Insufficient attributes were given to create an object. This object may not exist because it may have been deleted and already garbage collected.

 XE-S-EUR0208              12m:34s    0 /  23    0

 XQ-S-NME0777              12m:31s    0 /  23    0

 XE-S-NME0086              12m:30s    0 /  34    0

 EG-S-EUR0202              12m:18s    0 /  30    0

 XB-S-EUR0777              12m:18s    0 /  32    0

 KZ-S-EUR0222              12m:17s    0 /   9    0

 DE-S-EUR0220              12m:01s    0 /   9    0

 XF-S-EUR0210              12m:00s    0 /  25    0

 XE-S-NME0003              11m:46s    0 /  97    0

 DE-S-EUR0218              11m:26s    0 /  48    0

 XQ-S-APC0086              11m:21s    0 /   9    0

 CN-S-APC0092              10m:42s    0 /  18    0

 XP-S-APC0010              10m:32s    0 /   9    0

 AU-S-APC0088              10m:28s    0 /   9    0

 IT-S-EUR0223              10m:16s    0 /   9    0

 XF-S-EUR0209              09m:53s    0 /  39    0

 XE-S-EUR0207              09m:39s    0 /  34    0

 PL-S-EUR0217              09m:33s    0 /  30    0

 XA-S-AME0003              09m:29s    0 /  37    0

 XP-S-AME0555              08m:34s    0 /  29    0

 XE-S-EUR0003              08m:32s    0 /  83    0

 XP-S-APC0083              07m:02s    0 /  42    0

 IT-S-EUR0080              06m:56s    0 /  18    0

 XP-S-APC0003              06m:42s    0 /  21    0

 XP-S-AME0666              06m:39s    0 /  32    0

 XE-S-EUR0010              06m:31s    0 /  32    0

 XP-S-EUR0555              06m:28s    0 /  55    0

 XP-S-APC0084              06m:10s    0 /  18    0

 SA-S-EUR0213              05m:23s    0 /  30    0

 US-S-AME0182              04m:36s    0 /   9    0

 XQ-S-AME0777              04m:33s    0 /  32    0

 XQ-S-APC0085              03m:57s    0 /  18    0

 XF-S-EUR0224              03m:48s    0 /  16    0

 XQ-S-APC0004              03m:07s    0 /  41    0

 XP-S-APC0001              02m:06s    0 /  51    0

 US-S-AME0180              01m:47s    0 /   9    0

 US-S-AME0193              01m:21s    0 /   9    0

 CZ-S-EUR0212              01m:11s    0 /   9    0

 SE-S-NME0091                 :38s    0 /  43    0

 IT-S-EUR0007                 :16s    0 /  39    0

 CA-S-AME0177                 :04s    0 /   9    0





Experienced the following operational errors trying to retrieve replication information:

          58 - xe-s-abb0012.abb.com

          58 - CL-S-AME0194.americas.abb.com

"@

$Output1 = Get-WinADForestReplicationSummary # | Format-Table
$Output2 = Get-WinADForestReplicationSummary -InputContent $File # | Format-Table
$Output3 = Get-WinADForestReplicationSummary -InputContent $File2 # | Format-Table
$Output4 = Get-WinADForestReplicationSummary -InputContent $File3 # | Format-Table
$Output5 = Get-WinADForestReplicationSummary -FilePath "C:\Users\przemyslaw.klys\Downloads\replication_dc (9).txt"
$Output6 = Get-WinADForestReplicationSummary -FilePath "C:\Users\przemyslaw.klys\Downloads\replication_dc (8).txt"

New-HTML {
    New-HTMLTable -DataTable $Output1 -Filtering
    New-HTMLTable -DataTable $Output2 -Filtering
    New-HTMLTable -DataTable $Output3 -Filtering
    New-HTMLTable -DataTable $Output4 -Filtering
    New-HTMLTable -DataTable $Output5 -Filtering
    New-HTMLTable -DataTable $Output6 -Filtering
} -ShowHTML