#Zone name to import records
$ImportZone = "10.in-addr.arpa"
#Create format date
$date = get-date -Format yMMdd
#$LogFile = '.'+$date+'-Migration_RDNS.csv'
#DNS Server from import records
$ServDNS = "pcvit-dc01"
#Path to save reverse records
$PathSaveR = "C:\temp\"
foreach ($IZ in $ImportZone) {
    $zoneIZ = $IZ -replace ".in-addr.arpa", ""
    $FilterZoneName = $("*." + $zoneIZ + "*")
    #Collect all reverse zones start with filter
    $getDNSServerZone = Get-DnsServerZone -ComputerName $ServDNS | Where-Object { $_.ZoneName -like "$FilterZoneName" }

    foreach ($ZoneName in $getDNSServerZone) {
        Write-Host $ZoneName.ZoneName
        Start-Sleep 2
        $zone = $ZoneName.ZoneName -replace ".in-addr.arpa", ""
        $zonea = ($zone).Remove(($zone.LastIndexOf('.')))
        $zonea = "." + $zonea
        #Collect all records
        $Zoneb = Get-DnsServerResourceRecord -ZoneName $ZoneName.ZoneName -RRType Ptr -ComputerName $ServDNS | Select-Object Hostname, TimeToLive, TimeStamp, @{Name = 'RecordData'; Expression = { $_.RecordData.PtrDomainName } }
        #Export to local file
        $Zoneb | Export-Csv -Path $PathSaveR$date"-"$ServDNS"-"$($ZoneName.ZoneName)".csv" -NoTypeInformation -Encoding UTF8 -Delimiter ";"
        #Import to unique zone records
        $Zoneb | ForEach-Object { if ($_.TimeStamp -like "") {
                #Add Static record 
                $HN = $_.HostName + $zonea
                Write-Host "Add records" $_.RecordData "Static Address" -ForegroundColor Yellow
                Add-DnsServerResourceRecordPtr -ComputerName $ServDNS -Name $HN -ZoneName $ImportZone -AllowUpdateAny -TimeToLive $_.TimeToLive -PtrDomainName $_.RecordData -Verbose
            } # End IF
            Else {
                #Add Timestamped record
                $HN = $_.HostName + $zonea
                Write-Host "Add records" $_.RecordData "TimeStamp Address" -ForegroundColor Yellow
                Add-DnsServerResourceRecordPtr -ComputerName $ServDNS -Name $HN -ZoneName $ImportZone -AllowUpdateAny -TimeToLive $_.TimeToLive -AgeRecord -PtrDomainName $_.RecordData -Verbose
            } # End Else
        } # End Foreach
    } # End Foreach
}#End Foreach