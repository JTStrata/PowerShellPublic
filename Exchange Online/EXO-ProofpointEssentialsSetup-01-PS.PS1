# Connect to Exchange Online
Connect-ExchangeOnline

# Define the IP ranges
$IPRanges = @(
    '67.231.152.0/24', '67.231.153.0/24', '67.231.154.0/24', '67.231.155.0/24', '67.231.156.0/24',
    '67.231.144.0/24', '67.231.145.0/24', '67.231.146.0/24', '67.231.147.0/24', '67.231.148.0/24',
    '67.231.149.0/24',
    '148.163.128.0/24', '148.163.129.0/24', '148.163.130.0/24', '148.163.131.0/24', '148.163.132.0/24',
    '148.163.133.0/24', '148.163.134.0/24', '148.163.135.0/24', '148.163.136.0/24', '148.163.137.0/24',
    '148.163.138.0/24', '148.163.139.0/24', '148.163.140.0/24', '148.163.141.0/24', '148.163.142.0/24',
    '148.163.143.0/24', '148.163.144.0/24', '148.163.145.0/24', '148.163.146.0/24', '148.163.147.0/24',
    '148.163.148.0/24', '148.163.149.0/24', '148.163.150.0/24', '148.163.151.0/24', '148.163.152.0/24',
    '148.163.153.0/24', '148.163.154.0/24', '148.163.155.0/24', '148.163.156.0/24', '148.163.157.0/24',
    '148.163.158.0/24', '148.163.159.0/24'
)

# Create the transport rule to allow the SCL adjustment for spam bypass for Proofpoint
New-TransportRule -Name 'SPAM-BYPASS-Proofpoint_essentials-01' `
    -SenderIpRanges $IPRanges `
    -SetSCL -1 `
    -SetHeaderName 'X-MS-Exchange-Organization-SkipSafeLinksProcessing' `
    -SetHeaderValue 'True' `
    -Mode 'Enforce'

# Create the inbound connector
New-InboundConnector -Name 'INBOUND-Proofpoint_Essentials-01' `
    -Comment 'This connector is used to allow inbound connections from Proofpoint essentials, forcing TLS.' `
    -ConnectorType Partner `
    -SenderIPAddresses $IPRanges `
    -SenderDomains '*' `
    -RequireTls $true `
    -Enabled $true

# Create the outbound connector
New-OutboundConnector -Name 'OUTBOUND-Proofpoint_Essentials-01' `
    -Comment 'This connector is used to enforce outbound connections to Proofpoint essentials, with enforced TLS.' `
    -RecipientDomains '*' `
    -SmartHosts 'outbound-us1.ppe-hosted.com' `
    -TlsSettings 'EncryptionOnly' `
    -UseMXRecord $false `
    -IsTransportRuleScoped $false `
    -Enabled $true