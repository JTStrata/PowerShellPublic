
<#Collect the workstation OUs#>
$WSOUs = Get-ADOrganizationalUnit -Filter "(name -like '*workstation*' -or 
name -like '*teams-room*') -and (name -notlike '*admin*')" -Properties * | Select-Object canonicalname, distinguishedname, name  | sort distinguishedname

<#Collect the server OUs#>
$SRVOUs = Get-ADOrganizationalUnit -Filter "(name -like '*server*') -and (name -notlike '*admin*')" -Properties * | Select-Object canonicalname, distinguishedname, name  | sort distinguishedname

<# Combine the OUS #>
$allOUS += $WSOUs + $SRVOUs

<# Variables #>
$prefix = "DG-ADD-CO-"
$suffix = "-ReadLAPS"

<# Loop through the OUS and create the names of the new groups
    Create the new groups 
    Assign the delegations to the OUs with the new groups #>
foreach ($allOU in $allous) {
    $newname = $allou.canonicalname -replace '^(\[^/]*)/' -split '/' -join '_' -replace 'zollmed.com_'
    $dggroup = $prefix + $newname + $suffix
    Clear-Variable existinggroup
    write-host "Creating group $($dggroup)" -ForegroundColor Green
    $existinggroup = get-adgroup $dggroup
    write-host $($existinggroup)
    if (!$existinggroup) {
        New-ADGroup -DisplayName "$($dggroup)" -Description "AD Delegation - $($allou.canonicalname) - Read Laps Passwords" -GroupScope DomainLocal -GroupCategory Security -Name "$($dggroup)" -Path "OU=Resource Groups,OU=Groups,OU=Administration,DC=Zollmed,DC=com" -SamAccountName "$($dggroup)"
    }
    else { write-host "group $($dggroup) already exists " -ForegroundColor Yellow }
    
    Write-Host "Creating self permission" -ForegroundColor Cyan
    Set-AdmPwdComputerSelfPermission -Identity $allou.distinguishedname
    $newdg = Get-ADGroup $dggroup | Select-Object name
    Write-Host "Setting allowed principals on $($allou.distinguishedname) for $($dggroup) " -ForegroundColor Magenta
    Set-AdmPwdReadPasswordPermission -Identity $allou.distinguishedname -AllowedPrincipals "$($newdg.name)"
    
  
}

<# Get the newly created server groups #>
$servergroups = get-adgroup -filter 'displayname -like "*readlaps*" -and displayname -like "*server*"' | select-object distinguishedname

<# Get the newly created workstation groups #>
$workstationgroups = get-adgroup -filter 'displayname -like "*readlaps*" -and displayname -like "*workstation*"' | select-object distinguishedname

<# Loop through the server groups and add those to the server groups to read LAPS passwords #>
foreach ($servergroup in $servergroups) {

    Add-ADGroupMember -Identity $servergroup -Members "Server Team"

}

<# Loop through the workstation groups and add those to the server groups to read LAPS passwords #>
foreach ($workstationgroup in $workstationgroups) {

    Add-ADGroupMember -Identity $workstationgroup -Members "Workstation Team"

}