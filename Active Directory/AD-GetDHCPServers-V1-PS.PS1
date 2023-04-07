<# This script will go through the domain and find any DHCP servers that are 
    registered in the domain and perform the following:
    
    1. Pull any failover configurations and relationships
    2. Pull the scopes and modes
    3. Export to a CSV report 
    
    This script should be run as a domain admin, DHCP admin or account that 
    has permissions to pull the DHCP servers in the domain and their 
    accompaniying scopes and modes.

    VERSON 1.0
    DATE: 2022-02-15
    AUTHOR: Julian Thibeault

    #>

<# Varibles #>
$failoverReport = @()
$standaloneReport = @()
$StandaloneDHCPservers = @()
$errorReport = @()
$errors = @()
$obj = @()
$obj2 = @()

<# Set Execution Policy #>
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

<# Get all domain DHCP servers #>
$dhcpS = Get-DhcpServerInDC | Select-Object dnsname

<# Loop through and get the information on each server  #>
foreach ($dhcp in $dhcpS) {
    Clear-Variable dhcpfailover -ErrorAction SilentlyContinue
    try {
        $dhcpFailover = Get-DhcpServerv4Failover -ComputerName $dhcp.dnsname 
    }
    catch { $errors += $dhcp }
    if ($dhcpfailover) {
        <# Loop through each server that has failover configured #>
        foreach ($failover in $dhcpFailover) {
            foreach ($scope in $failover.ScopeId) {
                $obj = New-Object -TypeName PSObject
                $obj | Add-Member -MemberType NoteProperty -Name 'Failover Name' -Value $failover.Name
                $obj | Add-Member -MemberType NoteProperty -Name 'Server' -Value $dhcp.dnsname
                $obj | Add-Member -MemberType NoteProperty -Name 'Partner Server' -Value $failover.PartnerServer
                $obj | Add-Member -MemberType NoteProperty -Name 'Failover Mode' -Value $failover.mode
                $obj | Add-Member -MemberType NoteProperty -Name 'LB Percentage' -Value $failover.LoadBalancePercent
                $obj | Add-Member -MemberType NoteProperty -Name 'Scope ID' -Value $scope.ipaddresstostring
             
                $failoverReport += $obj  
            }
        }
        
    }
    else {
        $StandaloneDHCPservers += $dhcp.dnsname 
    }
}
<# Loop through the servers without a failover configuration #>
foreach ($StandaloneDHCPserver in $StandaloneDHCPservers) {

    $standaloneScopes = Get-DhcpServerv4Scope -ComputerName $StandaloneDHCPserver
    foreach ($standaloneScope in $standaloneScopes) {

        $obj2 = New-Object -TypeName PSObject
        $obj2 | Add-Member -MemberType NoteProperty -Name 'Server' -Value $dhcp.dnsname
        $obj2 | Add-Member -MemberType NoteProperty -Name 'Scope ID' -Value $standaloneScope.scopeid
        $obj2 | Add-Member -MemberType NoteProperty -Name 'Subnet Mask' -Value $standaloneScope.subnetmask
        $obj2 | Add-Member -MemberType NoteProperty -Name 'Name' -Value $standaloneScope.name
        $obj2 | Add-Member -MemberType NoteProperty -Name 'Start Range' -Value $standaloneScope.StartRange
        $obj2 | Add-Member -MemberType NoteProperty -Name 'End Range' -Value $standaloneScope.EndRange
        $obj2 | Add-Member -MemberType NoteProperty -Name 'Lease Duration' -Value $standaloneScope.LeaseDuration
 
        $standaloneReport += $obj 
    }
}
<# Loop through any servers that had an error collecting information #>
foreach ($error in $errors) {

    $obj3 = New-Object -TypeName PSObject
    $obj3 | Add-Member -MemberType NoteProperty -Name 'Server' -Value $error.dnsname
    $errorReport += $obj3
}
<# Export the reports to the desktop #>
$failoverReport | Export-Csv .\DHCPFailoverServerExport.csv
$standaloneReport | Export-Csv .\DHCPStandAloneServerExport.csv
$errorReport | Export-Csv .\DHCPErrorExport.csv