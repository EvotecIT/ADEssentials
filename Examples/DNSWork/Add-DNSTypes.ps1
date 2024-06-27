function Add-DNSTypes {
    [CmdletBinding()]
    param(

    )
    <#
Add-Type -TypeDefinition @"
using System;

namespace Indented.Dns
{
    public enum Rank : byte
    {
        None              = 0, // Tombstoned record
        CacheBit          = 1, // The record came from the cache.
        RootHint          = 8, // The record is a preconfigured root hint.
        OutsideGlue       = 32, // This value is not used.
        CacheNAAdditional = 49, // The record was cached from the additional section of a nonauthoritative response.
        CacheNAAuthority  = 65, // The record was cached from the authority section of a nonauthoritative response.
        CacheAAdditional  = 81, // The record was cached from the additional section of an authoritative response.
        CacheNAAnswer     = 97, // The record was cached from the answer section of a nonauthoritative response.
        CacheAAuthority   = 113, // The record was cached from the authority section of an authoritative response.
        Glue              = 128, // The record is a glue record in an authoritative zone.
        NSGlue            = 130, // The record is a delegation (type NS) record in an authoritative zone.
        CacheAAnswer      = 193, // The record was cached from the answer section of an authoritative response.
        ZoneRecord        = 240, // The record comes from an authoritative zone.
    }
}
"@
#>

    Add-Type -TypeDefinition @"


public enum Rank : byte
{
    None              = 0, // Tombstoned record
    CacheBit          = 1, // The record came from the cache.
    RootHint          = 8, // The record is a preconfigured root hint.
    OutsideGlue       = 32, // This value is not used.
    CacheNAAdditional = 49, // The record was cached from the additional section of a nonauthoritative response.
    CacheNAAuthority  = 65, // The record was cached from the authority section of a nonauthoritative response.
    CacheAAdditional  = 81, // The record was cached from the additional section of an authoritative response.
    CacheNAAnswer     = 97, // The record was cached from the answer section of a nonauthoritative response.
    CacheAAuthority   = 113, // The record was cached from the authority section of an authoritative response.
    Glue              = 128, // The record is a glue record in an authoritative zone.
    NSGlue            = 130, // The record is a delegation (type NS) record in an authoritative zone.
    CacheAAnswer      = 193, // The record was cached from the answer section of an authoritative response.
    ZoneRecord        = 240, // The record comes from an authoritative zone.
}

public enum IanaAddressFamily : ushort {
    IPv4 = 1, // IP version 4
    IPv6 = 2, // IP version 6
    NSAP = 3, // NSAP
    HDLC = 4, // HDLC (8-bit multidrop)
    BBN = 5, // BBN 1822
    _802 = 6, // 802 (includes all 802 media plus Ethernet "canonical format")
    E163 = 7, // E.163
    E164 = 8, // E.164 (SMDS, Frame Relay, ATM)
    F69 = 9, // F.69 (Telex)
    X121 = 10, // X.121 (X.25, Frame Relay)
    IPX = 11, // IPX
    Appletalk = 12, // Appletalk
    DecNetIV = 13, // DecNet IV
    BanyanVines = 14, // Banyan Vines
    E164NSAP = 15, // E.164 with NSAP format subaddress         [ATM Forum UNI 3.1. October 1995.][Andy_Malis]
    DNS = 16, // DNS (Domain Name System)
    DistinguishedName = 17, // Distinguished Name                        [Charles_Lynn]
    ASNumber = 18, // AS Number                                 [Charles_Lynn]
    XTPOverIpv4 = 19, // XTP over IP version 4                     [Mike_Saul]
    XTPOverIPv6 = 20, // XTP over IP version 6                     [Mike_Saul]
    XTPNativeMode = 21, // XTP native mode XTP                       [Mike_Saul]
    FibreChannelWWPortName = 22, // Fibre Channel World-Wide Port Name        [Mark_Bakke]
    FibreChannelWWNodeName = 23, // Fibre Channel World-Wide Node Name        [Mark_Bakke]
    GWID = 24, // GWID                                      [Subra_Hegde]
    AFIForL2VPN = 25, // AFI for L2VPN information                 [RFC4761][RFC6074]
    MPLSTPSectionID = 26, // MPLS-TP Section Endpoint Identifier       [RFC-ietf-mpls-gach-adv-08]
    MPLSTPLSPID = 27, // MPLS-TP LSP Endpoint Identifier           [RFC-ietf-mpls-gach-adv-08]
    MPLSTPPseudowireID = 28, // MPLS-TP Pseudowire Endpoint Identifier    [RFC-ietf-mpls-gach-adv-08]
    EIGRPCommon = 16384, // EIGRP Common Service Family               [Donnie_Savage]
    EIGRPIPv4 = 16385, // EIGRP IPv4 Service Family                 [Donnie_Savage]
    EIGRPIPv6 = 16386, // EIGRP IPv6 Service Family                 [Donnie_Savage]
    LCAF = 16387, // LISP Canonical Address Format (LCAF)      [David_Meyer]
    BGPLS = 16388, // BGP-LS                                    [draft-ietf-idr-ls-distribution]
    MAC48bit = 16389, // 48-bit MAC                                [RFC-eastlake-rfc5342bis-05]
    MAC64bit = 16390, // 64-bit MAC                                [RFC-eastlake-rfc5342bis-05]
    OUI = 16391, // OUI                                       [draft-eastlake-trill-ia-appsubtlv]
    MAC24 = 16392, // MAC/24                                    [draft-eastlake-trill-ia-appsubtlv]
    MAC40 = 16393, // MAC/40                                    [draft-eastlake-trill-ia-appsubtlv]
    IPv664 = 16394, // IPv6/64                                   [draft-eastlake-trill-ia-appsubtlv]
    RBridgePortID = 16395 // RBridge Port ID                           [draft-eastlake-trill-ia-appsubtlv]
}

public enum CertificateType : ushort {
    PKIX    = 1, // X.509 as per PKIX
    SPKI    = 2, // SPKI certificate
    PGP     = 3, // OpenPGP packet
    IPKIX   = 4, // The URL of an X.509 data object
    ISPKI   = 5, // The URL of an SPKI certificate
    IPGP    = 6, // The fingerprint and URL of an OpenPGP packet
    ACPKIX  = 7, // Attribute Certificate
    IACPKIX = 8, // The URL of an Attribute Certificate
    URI     = 253, // URI private
    OID     = 254, // OID private
}

public enum DigestType : byte {
    SHA1   = 1, // MANDATORY    [RFC3658]
    SHA256 = 2, // MANDATORY    [RFC4059]
    GOST   = 3, // OPTIONAL     [RFC5933]
    SHA384 = 4, // OPTIONAL     [RFC6605]
}

public enum EncryptionAlgorithm : byte {
    RSAMD5               = 1, // RSA/MD5 (deprecated, see 5)    [RFC3110][RFC4034]
    DH                   = 2, // Diffie-Hellman                 [RFC2539]
    DSA                  = 3, // DSA/SHA1                       [RFC3755]
    RSASHA1              = 5, // RSA/SHA-1                      [RFC3110][RFC4034]
    DSA_NSEC3_SHA1       = 6, // DSA-NSEC3-SHA1                 [RFC5155]
    RSASHA1_NSEC3_SHA1   = 7, // RSASHA1-NSEC3-SHA1             [RFC5155]
    RSASHA256            = 8, // RSA/SHA-256                    [RFC5702]
    RSASHA512            = 10, // RSA/SHA-512                    [RFC5702]
    ECC_GOST             = 12, // GOST R 34.10-2001              [RFC5933]
    ECDSAP256SHA256      = 13, // ECDSA Curve P-256 with SHA-256 [RFC6605]
    ECDSAP384SHA384      = 14, // ECDSA Curve P-384 with SHA-384 [RFC6605]
    INDIRECT             = 252, // Reserved for indirect keys     [RFC4034]
    PRIVATEDNS           = 253, // Private algorithm              [RFC4034]
    PRIVATEOID           = 254, // Private algorithm OID          [RFC4034]
}

public enum SSHAlgorithm : byte {
    RSA = 1, // [RFC4255]
    DSS = 2, // [RFC4255]
}

public enum SSHFPType : byte {
    SHA1 = 1, // [RFC4255]
}

public enum Flags : ushort {
    None = 0,
    AA   = 1024, // Authoritative Answer  [RFC1035]
    TC   = 512, // Truncated Response    [RFC1035]
    RD   = 256, // Recursion Desired     [RFC1035]
    RA   = 128, // Recursion Allowed     [RFC1035]
    AD   = 32, // Authenticated Data    [RFC4035]
    CD   = 16, // Checking Disabled     [RFC4035]
}

public enum MessageCompression : byte {
    Enabled  = 192,
    Disabled = 0,
}

public enum ATMAFormat : ushort {
    AESA = 0, // ATM End System Address
    E164 = 1, // E.164 address format
    NSAP = 2, // Network Service Access Protocol (NSAP) address model
}

public enum MSDNSOption : uint {
    CompressXFR = 19795,
}

public enum OpCode : ushort {
    Query  = 0, // [RFC1035]
    IQuery = 1, // [RFC3425]
    Status = 2, // [RFC1035]
    Notify = 4, // [RFC1996]
    Update = 5, // [RFC2136]
}

public enum QR : ushort {
    Query    = 0,
    Response = 32768,
}

public enum RecordClass : ushort {
    IN   = 1, // [RFC1035]
    CH   = 3, // [Moon1981]
    HS   = 4, // [Dyer1987]
    NONE = 254, // [RFC2136]
    ANY  = 255, // [RFC1035]
}

public enum RecordType : ushort {
    EMPTY      = 0, // an empty record                             [RFC1034] [MS DNS]
    A          = 1, // a host address                              [RFC1035]
    NS         = 2, // an authoritative name server                [RFC1035]
    MD         = 3, // a mail destination (Obsolete - use MX)      [RFC1035]
    MF         = 4, // a mail forwarder (Obsolete - use MX)        [RFC1035]
    CNAME      = 5, // the canonical name for an alias             [RFC1035]
    SOA        = 6, // marks the start of a zone of authority      [RFC1035]
    MB         = 7, // a mailbox domain name (EXPERIMENTAL)        [RFC1035]
    MG         = 8, // a mail group member (EXPERIMENTAL)          [RFC1035]
    MR         = 9, // a mail rename domain name (EXPERIMENTAL)    [RFC1035]
    NULL       = 10, // a null RR (EXPERIMENTAL)                    [RFC1035]
    WKS        = 11, // a well known service description            [RFC1035]
    PTR        = 12, // a domain name pointer                       [RFC1035]
    HINFO      = 13, // host information                            [RFC1035]
    MINFO      = 14, // mailbox or mail list information            [RFC1035]
    MX         = 15, // mail exchange                               [RFC1035]
    TXT        = 16, // text strings                                [RFC1035]
    RP         = 17, // for Responsible Person                      [RFC1183]
    AFSDB      = 18, // for AFS Data Base location                  [RFC1183]
    X25        = 19, // for X.25 PSDN address                       [RFC1183]
    ISDN       = 20, // for ISDN address                            [RFC1183]
    RT         = 21, // for Route Through                           [RFC1183]
    NSAP       = 22, // for NSAP address; NSAP style A record       [RFC1706]
    NSAPPTR    = 23, // for domain name pointer; NSAP style         [RFC1348]
    SIG        = 24, // for security signature                      [RFC4034][RFC3755][RFC2535]
    KEY        = 25, // for security key                            [RFC4034][RFC3755][RFC2535]
    PX         = 26, // X.400 mail mapping information              [RFC2163]
    GPOS       = 27, // Geographical Position                       [RFC1712]
    AAAA       = 28, // IP6 Address                                 [RFC3596]
    LOC        = 29, // Location Information                        [RFC1876]
    NXT        = 30, // Next Domain - OBSOLETE                      [RFC3755][RFC2535]
    EID        = 31, // Endpoint Identifier                         [Patton]
    NIMLOC     = 32, // Nimrod Locator                              [Patton]
    SRV        = 33, // Server Selection                            [RFC2782]
    ATMA       = 34, // ATM Address                                 [ATMDOC]
    NAPTR      = 35, // Naming Authority Pointer                    [RFC2915][RFC2168]
    KX         = 36, // Key Exchanger                               [RFC2230]
    CERT       = 37, // CERT                                        [RFC4398]
    A6         = 38, // A6 (Experimental)                           [RFC3226][RFC2874]
    DNAME      = 39, // DNAME                                       [RFC2672]
    SINK       = 40, // SINK                                        [Eastlake]
    OPT        = 41, // OPT                                         [RFC2671]
    APL        = 42, // APL                                         [RFC3123]
    DS         = 43, // Delegation Signer                           [RFC4034][RFC3658]
    SSHFP      = 44, // SSH Key Fingerprint                         [RFC4255]
    IPSECKEY   = 45, // IPSECKEY                                    [RFC4025]
    RRSIG      = 46, // RRSIG                                       [RFC4034][RFC3755]
    NSEC       = 47, // NSEC                                        [RFC4034][RFC3755]
    DNSKEY     = 48, // DNSKEY                                      [RFC4034][RFC3755]
    DHCID      = 49, // DHCID                                       [RFC4701]
    NSEC3      = 50, // NSEC3                                       [RFC5155]
    NSEC3PARAM = 51, // NSEC3PARAM                                  [RFC5155]
    HIP        = 55, // Host Identity Protocol                      [RFC5205]
    NINFO      = 56, // NINFO                                       [Reid]
    RKEY       = 57, // RKEY                                        [Reid]
    SPF        = 99, //                                             [RFC4408]
    UINFO      = 100, //                                             [IANA-Reserved]
    UID        = 101, //                                             [IANA-Reserved]
    GID        = 102, //                                             [IANA-Reserved]
    UNSPEC     = 103, //                                             [IANA-Reserved]
    TKEY       = 249, // Transaction Key                             [RFC2930]
    TSIG       = 250, // Transaction Signature                       [RFC2845]
    IXFR       = 251, // incremental transfer                        [RFC1995]
    AXFR       = 252, // transfer of an entire zone                  [RFC1035]
    MAILB      = 253, // mailbox-related RRs (MB; MG or MR)          [RFC1035]
    MAILA      = 254, // mail agent RRs (Obsolete - see MX)          [RFC1035]
    ANY        = 255, // A request for all records (*)               [RFC1035]
    TA         = 32768, // DNSSEC Trust Authorities                    [Weiler] 2005-12-13
    DLV        = 32769, // DNSSEC Lookaside Validation                 [RFC4431]
    WINS       = 65281, // WINS records (WINS Lookup record)           [MS DNS]
    WINSR      = 65282, // WINSR records (WINS Reverse Lookup record)  [MS DNS]
}

public enum RCode : ushort {
    NoError  = 0, // No Error                                    [RFC1035]
    FormErr  = 1, // Format Error                                [RFC1035]
    ServFail = 2, // Server Failure                              [RFC1035]
    NXDomain = 3, // Non-Existent Domain                         [RFC1035]
    NotImp   = 4, // Not Implemented                             [RFC1035]
    Refused  = 5, // Query Refused                               [RFC1035]
    YXDomain = 6, // Name Exists when it should not              [RFC2136]
    YXRRSet  = 7, // RR Set Exists when it should not            [RFC2136]
    NXRRSet  = 8, // RR Set that should exist does not           [RFC2136]
    NotAuth  = 9, // Server Not Authoritative for zone           [RFC2136]
    NotZone  = 10, // Name not contained in zone                  [RFC2136]
    BadVers  = 16, // Bad OPT Version                             [RFC2671]
    BadSig   = 16, // TSIG Signature Failure                      [RFC2845]
    BadKey   = 17, // Key not recognized                          [RFC2845]
    BadTime  = 18, // Signature out of time window                [RFC2845]
    BadMode  = 19, // Bad TKEY Mode                               [RFC2930]
    BadName  = 20, // Duplicate key name                          [RFC2930]
    BadAlg   = 21, // Algorithm not supported                     [RFC2930]
    BadTrunc = 22, // Bad Truncation                              [RFC4635]
}

public enum AFSDBSubType : ushort {
    AFSv3Loc   = 1, // Andrews File Service v3.0 Location Service  [RFC1183]
    DCENCARoot = 2, // DCE/NCA root cell directory node            [RFC1183]
}

public enum IPSECGatewayType : byte {
    NoGateway  = 0, // No gateway is present                    [RFC4025]
    IPv4       = 1, // A 4-byte IPv4 address is present         [RFC4025]
    IPv6       = 2, // A 16-byte IPv6 address is present        [RFC4025]
    DomainName = 3, // A wire-encoded domain name is present    [RFC4025]
}

public enum IPSECAlgorithm : byte {
    DSA = 1, // [RFC4025]
    RSA = 2, // [RFC4025]
}

public enum KEYAC : byte {
    AuthAndConfPermitted = 0, // Use of the key for authentication and/or confidentiality is permitted.
    AuthProhibited       = 2, // Use of the key is prohibited for authentication.
    ConfProhibited       = 1, // Use of the key is prohibited for confidentiality.
    NoKey                = 3, // No key information
}

public enum KEYNameType : byte {
    UserKey  = 0, // Indicates that this is a key associated with a "user" or "account" at an end entity, usually a host.
    ZoneKey  = 1, // Indicates that this is a zone key for the zone whose name is the KEY RR owner name.
    NonZone  = 2, // Indicates that this is a key associated with the non-zone "entity" whose name is the RR owner name.
    Reserved = 3, // Reserved
}

public enum KEYProtocol : byte {
    Reserved = 0,
    TLS      = 1,
    EMmail   = 2,
    DNSSEC   = 3,
    IPSEC    = 4,
    All      = 255,
}

public enum EDnsOptionCode : ushort {
    LLQ                  = 1, // On-hold      [http://files.dns-sd.org/draft-sekar-dns-llq.txt]
    UL                   = 2, // On-hold      [http://files.dns-sd.org/draft-sekar-dns-ul.txt]
    NSID                 = 3, // Standard     [RFC5001]
    DAU                  = 5, // Standard     [RFC6975]
    DHU                  = 6, // Standard     [RFC6975]
    N3U                  = 7, // Standard     [RFC6975]
    EDNS_client_subnet   = 8, // Optional     [draft-vandergaast-edns-client-subnet][Wilmer_van_der_Gaast]
}

public enum EDnsDNSSECOK : ushort {
    NONE = 0,
    DO   = 32768, // DNSSEC answer OK    [RFC4035][RFC3225]
}

public enum LLQOpCode : ushort {
    LLQSetup   = 1,
    LLQRefresh = 2,
    LLQEvent   = 3,
}

public enum LLQErrorCode : ushort {
    NoError    = 0,
    ServFull   = 1,
    Static     = 2,
    FormatErr  = 3,
    NoSuchLLQ  = 4,
    BadVers    = 5,
    UnknownErr = 6,
}

public enum NSEC3Flags : byte {
    OptOut = 1, // [RFC5155]
}

public enum NSEC3HashAlgorithm : byte {
    SHA1 = 1, // [RFC5155]
}

public enum TKEYMode : ushort {
    ServerAssignment   = 1, // Server assignment          [RFC2930]
    DH                 = 2, // Diffie-Hellman Exchange    [RFC2930]
    GSSAPI             = 3, // GSS-API negotiation        [RFC2930]
    ResolverAssignment = 4, // Resolver assignment        [RFC2930]
    KeyDeletion        = 5, // Key deletion               [RFC2930]
}

public enum WINSMappingFlag : uint {
    Replication   = 0,
    NoReplication = 65536,
}
"@

}