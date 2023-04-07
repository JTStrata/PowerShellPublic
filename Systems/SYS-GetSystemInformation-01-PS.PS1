<#
.SYNOPSIS
  Gather system information from network computers.
.DESCRIPTION
  Gather system information from computers on the network using Active Directory.
  
  Disclaimer: This script is offered "as-is" with no warranty. 
  While the script is tested and working in my environment, it is recommended that you test the script
  in a test environment before using in your production environment.
 
.NOTES
  Version:        1.0
  Author:         Julian Thibeault
  Creation Date:  2021/04/28
  Purpose/Change: Initial
.LINK
  https://github.com/StrataNorthCo/PowershellPublic/blob/main/Systems/SYS-GetSystemInformation-01-PS.ps1
#>


<#User defined variables#>
$cred = Get-Credential
$report = @()
$foundReport = @()
$unknownReport = @()
$ExportPath = "C:\SYS-GetSystemInformation-01-CSV.csv"

<#Gather all the computers in Active Directory#>
$ADCompArray = Get-ADComputer -Filter 'Enabled -eq $true' -Properties name, dnshostname, canonicalname | Select-Object name, dnshostname, canonicalname

<#Loop through the array and create a CimSession#>
foreach ($adCompObj in $ADCompArray) {
  $adCompObj.name 
  $session = New-CimSession -ComputerName $adCompObj.name -Credential $cred -ErrorAction SilentlyContinue
  <#Gather the system information from each system#>
  IF ($session) {
    $csStats = Get-CimInstance cim_computersystem -CimSession $session | Select-Object domain, manufacturer, model, name, totalphysicalmemory
    $csSerial = Get-CimInstance cim_bioselement -CimSession $session | Select-Object serialnumber
    $csLogicalDisk = Get-CimInstance CIM_LogicalDisk -CimSession $session | Select-Object DeviceID, VolumeName, Size, FreeSpace
    $csNetworkAdapter = Get-CimInstance -Class Win32_NetworkAdapterConfiguration -CimSession $session -Filter IPEnabled=$true | Where-Object { $_.defaultipgateway -ne $null } | Select-Object DHCPEnabled, IPAddress, DefaultIPGateway, Description
    $csProcessor = Get-CimInstance CIM_Processor -CimSession $session | Select-Object name
    $csMemoryConv = [MATH]::Round($csStats.TotalPhysicalMemory / 1GB).ToString() + ' GB'
    $csDiskSizeConv = [MATH]::Round($csLogicalDisk.size[0] / 1GB)
    $csDiskFreeConv = [MATH]::Round($csLogicalDisk.freespace[0] / 1GB)
    $percentFree = ($csDiskFreeConv / $csDiskSizeConv).ToString("P")

    <#Hash table of 36 different system types#>
    $ChassisTypes = @{
      Name       = 'ChassisTypes'
      Expression = {
        # property is an array, so process all values
        $result = foreach ($value in $_.ChassisTypes) {
          switch ([int]$value) {
            1 { 'Other' }
            2 { 'Unknown' }
            3 { 'Desktop' }
            4 { 'Low Profile Desktop' }
            5 { 'Pizza Box' }
            6 { 'Mini Tower' }
            7 { 'Tower' }
            8 { 'Portable' }
            9 { 'Laptop' }
            10 { 'Notebook' }
            11 { 'Hand Held' }
            12 { 'Docking Station' }
            13 { 'All in One' }
            14 { 'Sub Notebook' }
            15 { 'Space-Saving' }
            16 { 'Lunch Box' }
            17 { 'Main System Chassis' }
            18 { 'Expansion Chassis' }
            19 { 'SubChassis' }
            20 { 'Bus Expansion Chassis' }
            21 { 'Peripheral Chassis' }
            22 { 'Storage Chassis' }
            23 { 'Rack Mount Chassis' }
            24 { 'Sealed-Case PC' }
            25 { 'Multi-system chassis' }
            26 { 'Compact PCI' }
            27 { 'Advanced TCA' }
            28 { 'Blade' }
            29 { 'Blade Enclosure' }
            30 { 'Tablet' }
            31 { 'Convertible' }
            32 { 'Detachable' }
            33 { 'ioT Gateway' }
            34 { 'Embedded PC' }
            35 { 'Mini PC' }
            36 { 'Stick PC' }
            default { "$value" }
          }
      
        }
        $result
      }  
    }
    <#endregion define calculated property#>

    <#retrieve all instances#>
    $csChassisType = Get-CimInstance -ClassName Win32_SystemEnclosure -CimSession $session | Select-Object -Property $ChassisTypes

    <#Create the report#>
    $object = New-Object -TypeName psobject
   
    $object | Add-Member -MemberType NoteProperty -Name ComputerName -Value $adCompObj.dnshostname
    $object | Add-Member -MemberType NoteProperty -Name Location -Value $adCompObj.canonicalname
    $object | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $csStats.manufacturer
    $object | Add-Member -MemberType NoteProperty -Name ServiceTag -Value $csSerial.serialnumber
    $object | Add-Member -MemberType NoteProperty -Name Model -Value $csStats.model
    $object | Add-Member -MemberType NoteProperty -Name DriveLetter -Value $csLogicalDisk.deviceid
    $object | Add-Member -MemberType NoteProperty -Name VolumeName -Value $csLogicalDisk.volumename
    $object | Add-Member -MemberType NoteProperty -Name DHCPEnabled -Value $csNetworkAdapter.DHCPEnabled
    $object | Add-Member -MemberType NoteProperty -Name IPAddress -Value $csNetworkAdapter.IPAddress
    $object | Add-Member -MemberType NoteProperty -Name DefaultIPGateway -Value $csNetworkAdapter.DefaultIPGateway
    $object | Add-Member -MemberType NoteProperty -Name Description -Value $csNetworkAdapter.Description
    $object | Add-Member -MemberType NoteProperty -Name CPUModel -Value $csProcessor.name
    $object | Add-Member -MemberType NoteProperty -Name Memory -Value $csMemoryConv
    $object | Add-Member -MemberType NoteProperty -Name 'DiskSize(GB)' -Value $csDiskSizeConv
    $object | Add-Member -MemberType NoteProperty -Name 'Disk Free Space' -Value $percentFree
    $object | Add-Member -MemberType NoteProperty -Name 'System Type' -Value $csChassisType.chassistypes
        
    <#Aggregate the report#>
    $report += $object
    Clear-Variable session
  }
  else { 
    Write-Host "$($adCompObj.name) System not found" -ForegroundColor Yellow

    $unknownObject = New-Object -TypeName psobject

    $unknownObject | Add-Member -MemberType NoteProperty -Name ComputerName -Value $adCompObj.dnshostname
    $unknownObject | Add-Member -MemberType NoteProperty -Name Location -Value $adCompObj.canonicalname
    $unknownObject | Add-Member -MemberType NoteProperty -Name Manufacturer -Value "Unknown"
    $unknownObject | Add-Member -MemberType NoteProperty -Name ServiceTag -Value "Unknown"
    $unknownObject | Add-Member -MemberType NoteProperty -Name Model -Value "Unknown"
    $unknownObject | Add-Member -MemberType NoteProperty -Name DriveLetter -Value "Unknown"
    $unknownObject | Add-Member -MemberType NoteProperty -Name VolumeName -Value "Unknown"
    $unknownObject | Add-Member -MemberType NoteProperty -Name DHCPEnabled -Value "Unknown"
    $unknownObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value "Unknown"
    $unknownObject | Add-Member -MemberType NoteProperty -Name DefaultIPGateway -Value "Unknown"
    $unknownObject | Add-Member -MemberType NoteProperty -Name Description -Value "Unknown"
    $unknownObject | Add-Member -MemberType NoteProperty -Name CPUModel -Value "Unknown"
    $unknownObject | Add-Member -MemberType NoteProperty -Name Memory -Value "Unknown"
    $unknownObject | Add-Member -MemberType NoteProperty -Name 'DiskSize(GB)' -Value "Unknown"
    $unknownObject | Add-Member -MemberType NoteProperty -Name 'Disk Free Space' -Value "Unknown"
    $unknownObject | Add-Member -MemberType NoteProperty -Name 'System Type' -Value "Unknown"
    
    $unknownReport += $unknownObject
  }
}   $FullReport += $unknownReport
$FullReport += $foundReport

$fullreport | Export-Csv -Path $ExportPath