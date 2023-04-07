$sess = New-PSSession -ComputerName arundel-cdk1

Enter-PSSession -Session $sess

#variables
$ipaddress='192.224.32.90'
$index = get-netipaddress | where-object {$_.IPAddress -eq $ipaddress} | Select-Object -ExpandProperty InterfaceIndex
$gateway = get-netroute -DestinationPrefix '0.0.0.0/0' | Select-Object -ExpandProperty NextHop
$oldroute = '192.224.32.2'
$newroute = '192.224.32.5'
$destination = '0.0.0.0/0'

#Start Changing the Gateway if needed

Function New-Gateway() {

Remove-netroute -interfaceindex $index -NextHop $oldroute -confirm:$false
new-netroute -interfaceindex $index -NextHop $newroute -destinationprefix $destination -confirm:$false
sleep 3

}

if ($gateway -eq $oldroute) {
Write-Warning -Message "Gateway is set to $gateway and will be changed to $newroute"
New-Gateway #| Out-file $Log -Append

}
elseif ($gateway -eq $newroute) {
Write-Warning -Message "Gateway is already set to $newroute and needs no change"

}