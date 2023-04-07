<#
.SYNOPSIS
  Gather IP Addresses of computers within active directory OUs
.DESCRIPTION
  Gather IP address information from computers on the network using Active Directory.
  
  Disclaimer: This script is offered "as-is" with no warranty. 
  While the script is tested and working in my environment, it is recommended that you test the script
  in a test environment before using in your production environment.
 
.NOTES
  Version:        1.0
  Author:         Julian Thibeault
  Creation Date:  2021/07/13
  Purpose/Change: Initial
.LINK
  https://github.com/StrataNorthCo/PowershellPublic/blob/main/Systems/AD-GetADComputer-TestNetConnect-PS.ps1
#>

<#User defined variables#>
$report = @()
$searchbase = "OU=NEW,OU=Devices,DC=company,DC=com"

<#Get computers from AD OUs#>
$computers = Get-ADComputer -SearchBase $searchbase -filter * -Properties * 

foreach ( $c in $computers ) {
    $test = Test-NetConnection -ComputerName $c.name | Select-Object pingsucceeded, remoteaddress, computername
    IF ( $test.pingsucceeded -eq "True" ) {
        $report += $test
    }

}