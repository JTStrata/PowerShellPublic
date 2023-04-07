<#
.SYNOPSIS
  Retrieve ACLS on shared folder and subfolders
.DESCRIPTION
  Retrieve ACLS on shared folder and subfolders
  
  Disclaimer: This script is offered "as-is" with no warranty. 
  While the script is tested and working in my environment, it is recommended that you test the script
  in a test environment before using in your production environment.
 
.NOTES
  Version:        1.0
  Author:         Julian Thibeault
  Creation Date:  2022/03/22
  Purpose/Change: Initial
.LINK
  
#>
$acls = @()

<#User defined variables#>
$path = "\\WEIRS-FILESERVE\Shared"
$folders = Get-ChildItem -Path $path -Directory

foreach ($f in $folders) {
    Write-Host "Getting ACLs for Folder $($path)\$f" -ForegroundColor Green
    $acls += Get-ACL -Path "$($path)\$f"
}

$acls | Out-GridView