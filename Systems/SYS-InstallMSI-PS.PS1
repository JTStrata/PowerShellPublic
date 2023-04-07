$sb = "OU=ford,OU=Windows-workstations,OU=Devices,DC=dealerships,DC=local"

$comp = Get-ADComputer -Filter * -SearchBase $sb -Properties *

foreach($c in $comp){

$tnc = Test-NetConnection -ComputerName $c.name

IF($tnc.pingsucceeded -eq $true){
    Write-Host "Installing on $($c.name)" -ForegroundColor Gray
   
    $srcpath = "\\dealerships.local\SYSVOL\dealerships.local\scripts\ArundelFord_DPMA_ITSPlatform_TKN4943ca1a-2b1c-4dd1-ab8f-7c2c04ed8d85.msi"
    $fullpath = "\\$($c.name)\C$\temp\install"
    New-Item -ItemType directory -Path "$($fullpath)"
    Copy-Item "$($srcpath)" "$($fullpath)"
    Invoke-Command -ComputerName $c.Name -ScriptBlock { &cmd.exe /c MSIEXEC /I "c:\temp\install\ArundelFord_DPMA_ITSPlatform_TKN4943ca1a-2b1c-4dd1-ab8f-7c2c04ed8d85.msi" /qn }

}else{ Write-Host "$($C.name) was not reachable" -ForegroundColor Yellow }


}









