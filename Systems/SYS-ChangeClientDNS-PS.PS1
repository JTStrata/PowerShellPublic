$report = @()
$report2 = @()


$sb = "OU=ford,OU=Windows-workstations,OU=Devices,DC=dealerships,DC=local"
$comp = Get-ADComputer -Filter * -SearchBase $sb -Properties *

foreach($c in $comp){
    $tnc = Test-NetConnection -ComputerName $c.name
    IF($tnc.pingsucceeded -eq $true){
        Write-Host "Ready to change DNS on $($c.name)" -ForegroundColor Gray
        $sess = New-PSSession -ComputerName $c.Name
        Enter-PSSession $sess
        
        $gna = Get-NetAdapter | Select-Object InterfaceAlias , InterfaceIndex
            foreach($g in $gna){
                $GoogleDNS = Get-DnsClientServerAddress -InterfaceIndex $g.interfaceindex -AddressFamily IPv4 -ErrorAction SilentlyContinue
                IF(!$GoogleDNS.ServerAddresses){ Write-Host "No DNS Servers Present on $($g.interfacealias) on $($c.name)" -ForegroundColor Yellow }
                ELSEIF(($GoogleDNS.serveraddresses -contains "192.224.32.8") -and 
                ($GoogleDNS.serveraddresses -contains "192.224.32.9")) { 
                    Write-Host "DNS Server settings are correct on interface $($g.InterfaceAlias) $($c.name)" -ForegroundColor Green
            }ELSE {
                Write-Host "DNS Server settings are incorrect" -ForegroundColor Magenta
                Set-DnsClientServerAddress -InterfaceIndex $g.InterfaceIndex -ServerAddresses ("192.224.32.8, 192.224.32.9")}
        
                $obj = New-Object -TYPE psobject
                $obj | Add-Member -TYPE NoteProperty -Name Computer -Value $c.Name
                $obj | Add-Member -TYPE NoteProperty -Name InterfaceName -Value $g.InterfaceAlias
                $obj | Add-Member -TYPE NoteProperty -Name DNSValue -Value $GoogleDNS.ServerAddresses
                $report += $obj
        
        }
            Exit-PSSession
            Remove-PSSession *
            Clear-Variable sess
    }else{
  
                $obj2 = New-Object -TYPE psobject
                $obj2 | Add-Member -TYPE NoteProperty -Name ComputerCantPing -Value $c.Name
                $report2 += $obj2
    
    
    }
}


 
