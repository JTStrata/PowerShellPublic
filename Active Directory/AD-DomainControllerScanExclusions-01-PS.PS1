$obj1 = @()
$obj2 = @()
$regHashOutput1 = @()
$regHashOutput2 = @()

$regHash = @(
    @{RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters\"; Name = "DSA Database File"; Function = "DSADB" },
    @{RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters\"; Name = "Database Log Files Path"; Function = "DSALog" },
    @{RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters\"; Name = "DSA Working Directory"; Function = "DSAWork" },
    @{RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NtFrs\Parameters\"; Name = "Working Directory"; Function = "FRS" },
    @{RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NtFrs\Parameters\"; Name = "DB Log File Directory"; Function = "FRSLog" },
    @{RegPath = "HKLM:\SYSTEM\ControlSet001\Services\Netlogon\Parameters"; Name = "SysVol"; Function = "SYSVOL" },
    @{RegPath = "HKLM:\System\CurrentControlSet\Services\DHCPServer\Parameters"; Name = "DatabasePath"; Function = "DHCP" })


foreach ($reg in $regHash) {

    $Value = $reg.name
    $regValue = Get-Itemproperty -Path $reg.regpath -Name $reg.name -ErrorAction SilentlyContinue
    if ($regvalue) {

        $obj1 = New-Object -typename PSObject
        $obj1 | Add-Member -membertype noteproperty -name 'RegPath' -value $reg.RegPath
        $obj1 | Add-Member -membertype noteproperty -name 'FolderPath' -value $regvalue.$value
        $obj1 | Add-Member -membertype noteproperty -name 'Function' -value $reg.function
        $regHashOutput1 += $obj1

    }
    Clear-Variable regvalue
}

$regHash2 = @(
    @{RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NtFrs\Parameters\Replica Sets\"; Name = ""; Function = "NTFRS Staging" },
    @{RegPath = "HKLM:\SYSTEM\Currentcontrolset\Services\DFSR\Parameters\Replication Groups\"; Name = ""; Function = "DFSR database" })

foreach ($reg2 in $reghash2) {

    $regpathRepSet2 = (Get-childitem -Path $reg2.regpath -ErrorAction SilentlyContinue).name 
    if ($regpathrepset2) {
        $regpathrepsetlast2 = $regpathRepSet2 -replace '\w+_\w+'
        $newRegPathRepSet2 = "HKLM:" + $regpathrepsetlast2

        if ($newregpathrepset2 -like "*Replication Groups*") { 
            $XMLFilePath2 = (Get-ItemProperty -Path $newRegPathRepSet2 -name "Replica Set Configuration File").'Replica Set Configuration File'
            $xmlpath2 = $XMLFilePath2 -replace '\\\\\?\\' 
            [xml]$xmldata2 = Get-Content $xmlpath2
            $DSV2 = $xmldata2.DfsrReplicationGroupConfig.DfsrReplicationGroup.ReplicationGroupName
            if ($DSV2 -eq "Domain System Volume") {
                $FolderPath2 = 'C:\System Volume Information\DFSR'
            }
        }
        if ($newregpathrepset2 -like "*Replica Set*") { 
            $FolderPath2 = (Get-ItemProperty -Path $newRegPathRepSet2 -name "Replica Set Stage").'Replica Set Stage'
    
        }

  

        $obj2 = New-Object -typename PSObject
        $obj2 | Add-Member -membertype noteproperty -name 'RegPath' -value $reg2.RegPath
        $obj2 | Add-Member -membertype noteproperty -name 'FolderPath' -value $folderpath2
        $obj2 | Add-Member -membertype noteproperty -name 'Function' -value $reg2.function
        $regHashOutput2 += $obj2

    }

}


$Reghasoutput3 += $regHashOutput1 + $regHashOutput2
foreach ($rho3 in $Reghasoutput3) {

    if ($rho3.function -eq "DSADB") {
        if ($rho3.FolderPath -notlike "*.*") {
            $excludedFile = (Get-childItem $rho3.folderpath -include ntds.*).name
            $excludedpath = $rho3.folderpath + '\' + $excludedfile
        }
        else { $excludedpath = $rho3.folderpath }
    }
}$excludedpath

