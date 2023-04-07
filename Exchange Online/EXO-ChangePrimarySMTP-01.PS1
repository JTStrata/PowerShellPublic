<#
.SYNOPSIS
  This script will change the primary SMTP address of exchange online mailboxes
.DESCRIPTION
  This script will gather the smtp address of all user mailboxes and check to see if the deisred target
  email address is present. If not, it will add it and then set it to be the primary smtp address.
  
  Disclaimer: This script is offered "as-is" with no warranty. 
  While the script is tested and working in my environment, it is recommended that you test the script
  in a test environment before using in your production environment.
 
.NOTES

  Title:            EXO-ChangePrimarySMTP-01
  Version:          1.0
  Author:           Julian Thibeault
  Creation Date:    2021/05/05
  Purpose/Change:   Initial
  Website:          https://StrataNorth.co
  GitHub:           https://github.com/StrataNorthCo/PowershellPublic
.LINK
  https://github.com/StrataNorthCo/PowershellPublic/blob/main/Active%20Directory/EXO-ChangePrimarySMTP-01.ps1
#>

<#User defined variables#>
$domain = "@domain.com"
$mb = Get-Mailbox -RecipientTypeDetails "usermailbox" | Select-Object name, alias, primarysmtpaddress, emailaddresses, windowsemailaddress

foreach ($m in $mb) {
  <#Setup the target primary smtp addresses#>
  $winemail = $m.name + $domain
  $addsmtp = "smtp:" + $m.name + $domain

  IF ($m.EmailAddresses -notcontains $addsmtp) {
    Write-Host "$($m.name) does not contain the target mailbox address" -ForegroundColor Yellow
    Set-Mailbox $m.PrimarySmtpAddress -EmailAddresses @{add = "$addsmtp" } -WindowsEmailAddress $winemail
  }

  IF ($m.EmailAddresses -contains $addsmtp -and $m.PrimarySmtpAddress -ne $m.windowsemailaddress) {

    Write-Host "$($m.name) contains the target mailbox address" -ForegroundColor Magenta
    Set-Mailbox $m.PrimarySmtpAddress -WindowsEmailAddress $winemail
  }

  IF ($m.EmailAddresses -contains $addsmtp -and $m.PrimarySmtpAddress -eq $m.windowsemailaddress) {

    Write-Host "$($m.name) is already all set" -ForegroundColor Green
  }

  <#run a check to see if the mailboxes were successfully changed#>
  $check = Get-Mailbox $m.PrimarySmtpAddress | Select-Object primarysmtpaddress
  IF ($check.primarysmtpaddress -eq $m.PrimarySmtpAddress) {
    Write-Host "$($m.name) primarysmtpaddress check passed" -ForegroundColor green

  }
  Else { Write-Host "$($m.name) primarysmtpaddress needs attention" -ForegroundColor yellow }

}


