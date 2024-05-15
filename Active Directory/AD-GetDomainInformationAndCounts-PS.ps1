$path = Set-Location -Path ([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop))
 

<# 1. Gather domain controller information #>
$domainControllers = Get-ADDomainController -Filter * | Select-Object Name, Domain, Forest, Site, OperatingSystem

#export the report
$domainControllers | Export-Csv -Path ".\DomainControllersReport.csv" -NoTypeInformation

<# 2. Gather computer object information #>
$allComputers = Get-ADComputer -Filter * -Properties *
$allEnabledComputers = $allComputers | Where-Object {$_.Enabled -eq $true}
$computerCount = $allComputers.Count

<# 3. Gather enabled inactive computer information #>

$inactiveEnabledComputers = $allComputers | Where-Object { 
    $_.Enabled -eq $true -and (
        ($_.LastLogonDate -and $_.LastLogonDate -lt (Get-Date).AddDays(-90) -or 
        ($null -eq $_.LastLogonDate -and $_.PaswordLastSet -lt (Get-Date).AddDays(-90))
        )
    )
}
$inactiveEnabledComputerCount = $inactiveEnabledComputers.Count
$inactiveEnabledComputerPercentage = [Math]::Round(($inactiveEnabledComputerCount / $computerCount) * 100)

<# 4. Gather disabled computer information #>

$disabledComputers = $allComputers | Where-Object { $_.Enabled -eq $false }
$disabledComputerCount = $disabledComputers.Count
$disabledComputerPercentage =  [Math]::Round(($disabledComputerCount / $computerCount) * 100)

#export the report for computers
$ComputersReport = [PSCustomObject]@{

    "Computer Count" = $computerCount
    "Inactive Enabled Computer Count" = $inactiveEnabledComputerCount
    "Total % of Computers Inactive > (90) Days" = $inactiveEnabledComputerPercentage
    "Disabled Computer Count" = $disabledComputerCount
    "Total % of Computers Disabled" = $disabledComputerPercentage

}

$ComputersReport | Export-Csv -Path ".\ComputersReport.csv" -NoTypeInformation

<# 5. Gather enabled computer operating system information #>
$osCount = $allEnabledComputers | Group-Object OperatingSystem | Select-Object Name, Count, @{Name="Percentage (Rounded)"; Expression={[Math]::Round(($_.Count / $computerCount) * 100)}} | Sort-Object Count -Descending

$OSCount | Export-Csv -Path ".\OSReport.csv" -NoTypeInformation


<# 6. Gather user object information #>
$allUsers = Get-ADUser -Filter * -Properties * 
$userCount = $allUsers.Count

<# 7. Gather enabled inactive user object information #>
$inactiveEnabledUsers = $allUsers | Where-Object { 
    $_.Enabled -eq $true -and (
        ($_.LastLogonDate -and $_.LastLogonDate -lt (Get-Date).AddDays(-90)) -or 
        ($null -eq $_.LastLogonDate -and $_.PasswordLastSet -lt (Get-Date).AddDays(-90))
    )
}
$inactiveEnabledUserCount = $inactiveEnabledUsers.Count
$inactiveEnabledUserPercentage = [Math]::Round(($inactiveEnabledUserCount / $userCount) * 100)

<# 8. Gather disabled user object information #>
$disabledUsers = $allUsers | Where-Object { $_.Enabled -eq $false }
$disabledUserCount = $disabledUsers.Count
$disabledUserPercentage = [Math]::Round(($disabledUserCount / $userCount) * 100)

<# 9. Gather domain admins group member information #>
$domainAdmins = Get-ADGroupMember -Identity "Domain Admins"
$domainAdminCount = $domainAdmins.Count
$domainAdminPercentage = [Math]::Round(($domainAdminCount / $userCount) * 100)

<# 10. Gather administrators group member information #>
$administrators = Get-ADGroupMember -Identity "Administrators"
$administratorCount = $administrators.Count
$administratorPercentage = [Math]::Round(($administratorCount / $userCount) * 100)

<# 11. Gather enterprise admins group member information #>
$enterpriseAdmins = Get-ADGroupMember -Identity "Enterprise Admins"
$enterpriseAdminCount = $enterpriseAdmins.Count
$enterpriseAdminPercentage = [Math]::Round(($enterpriseAdminCount / $userCount) * 100)

<# 12. Gather enterprise admins group member information #>
$schemaAdmins = Get-ADGroupMember -Identity "Schema Admins"
$schemaAdminCount = $schemaAdmins.Count
$schemaAdminPercentage = [Math]::Round(($schemaAdminCount / $userCount) * 100)

#export the report for users and memberships
$UsersAndMembershipsReport = [PSCustomObject]@{

    "User Count" = $userCount
    "Inactive Enabled User Count" = $inactiveEnabledUserCount
    "Total % of Users Inactive > (90 Days)" = $inactiveEnabledUserPercentage
    "Disabled user Count" = $disabledUserCount
    "Total % of Users Disabled" = $disabledUserPercentage
    "Domain Admin Count" = $domainAdminCount
    "Total % of Users with Domain Admin" = $domainAdminPercentage
    "Administrators Count" = $administratorCount
    "Total % of Users with Adminstrators" = $administratorPercentage
    "Enterprise Admin Count" = $enterpriseAdminCount
    "Total % of Users with Enterprise Admin" = $enterpriseAdminPercentage
    "Schema Admin Count" = $schemaAdminCount
    "Total % of Users with Schema Admin" = $schemaAdminPercentage
}

$UsersAndMembershipsReport | Export-Csv -Path ".\UsersAndMembershipsReport.csv" -NoTypeInformation


<# 13. Placeholder for Built-In Privileged group member information #>


<# 14. Gather group information #>
$allGroups = Get-ADGroup -Filter *
$groupsCount = $allgroups.count

<# 15. Gather empty group information #>
$emptyGroups = @()

# Iterate through each group and check the members count
foreach ($group in $allGroups) {
    $memberCount = (Get-ADGroup $group -Properties members).members.count
    if ($memberCount -eq 0) {
        $emptyGroups += $group
    }
}

$emptygroupscount = $emptygroups.count
$emptygroupsPercentage = [Math]::Round(($emptygroupscount / $groupsCount) * 100)

#export the report for groups
$GroupsReport = [PSCustomObject]@{

    "Group Count" = $groupsCount
    "Empty Groups Count" = $emptygroupscount
    "Total % of Empty Groups" = $emptygroupsPercentage
}

$GroupsReport | Export-Csv -Path ".\GroupsReport.csv" -NoTypeInformation


<# 16. Gather OU information #>
$ouCount = (Get-ADOrganizationalUnit -Filter *).Count

<# 17. Gather empty OU information #>
$emptyOUs = Get-ADOrganizationalUnit -Filter * | Where-Object { (Get-ADObject -Filter {ObjectClass -eq 'computer' -or ObjectClass -eq 'user'} -SearchBase $_.DistinguishedName).Count -eq 0 }
$emptyOUCount = $emptyOUs.Count
$emptyOUPercentage = [Math]::Round(($emptyOUCount / $ouCount) * 100)

#export the report for OUs
$OUsReport = [PSCustomObject]@{

    "OU Count" = $ouCount
    "Empty OU Count" = $emptyOUCount
    "Total % of Empty OUs" = $emptyOUPercentage
}

$OUsReport | Export-Csv -Path ".\OUsReport.csv" -NoTypeInformation

<# 18. Gather GPO information #>
$allGPOs = Get-GPO -All
$gpoCount = $allGPOs.Count

<# 19. Gather disabled GPO information #>
$disabledGPOs = $allGPOs | Where-Object { $_.GpoStatus -eq 'AllSettingsDisabled' }
$disabledGPOCount = $disabledGPOs.Count
$disabledGOPPercentage = [Math]::Round(($disabledGPOCount / $gpoCount) * 100)

<# 20. Gather unlinked GPO information #>
$unlinkedGPOs = @()

foreach ($gpo in $allGPOs) {
    # Get the GPO report in XML format
    $gpoReportXml = Get-GPOReport -Guid $gpo.Id -ReportType Xml

    # Convert XML to object
    $gpoXml = [xml]$gpoReportXml

    # Check if the GPO is linked
    $links = $gpoXml.GPO.LinksTo
    if (-not $links) {
        $unlinkedGPOs += $gpo
    }
}
$unlinkedGPOCount = $unlinkedGPOs.Count
$unlinkedGPOPercentage = [Math]::Round(($unlinkedGPOCount / $gpoCount) * 100)

#export the report for GPOs
$GPOsReport = [PSCustomObject]@{

    "GPO Count" = $gpoCount
    "Disabled GPO Count" = $disabledGPOCount
    "Total % of Disabled GPOs" = $disabledGOPPercentage
    "Unlinked GPO Count" = $unlinkedGPOCount
    "Total % of Unlinked GPOs" = $unlinkedGPOPercentage
}

$GPOsReport | Export-Csv -Path ".\GPOsReport.csv" -NoTypeInformation

<# 21. Gather AD Sites information #>
$adSites = Get-ADReplicationSite -Filter *
$adSiteCount = $adSites.Count


# Initialize a list to hold AD sites without a Domain Controller
$adSitesWithoutDC = @()

foreach ($site in $adSites) {
    # Get all Domain Controllers in the current site
    $dcsInSite = Get-ADDomainController -Filter {Site -eq $site.Name}

    # Check if the current site has no Domain Controllers
    if (-not $dcsInSite) {
        $adSitesWithoutDC += $site
    }
}

# Count of AD Sites without a Domain Controller
$adSitesWithoutDCCount = $adSitesWithoutDC.Count
if($adSitesWithoutDCCount -ne 0){
$adSitesWithoutDCPercentage = [Math]::Round(($adSitesWithoutDCCount / $adSiteCount) * 100)
}else {$adSitesWithoutDCPercentage = 0}


$adSubnets = Get-ADReplicationSubnet -Filter *
$adSubnetCount = $adSubnets.Count

$adSubnetsWithoutSite = $adSubnets | Where-Object { $_.Site -eq $null }
if(!$adSubnetsWithoutSite) {
$adSubnetsWithoutSitecount = 0}else {$adSubnetsWithoutSiteCount = $adSubnetsWithoutSite.Count}

if($adSubnetsWithoutSiteCount -ne 0){
$adSubnetsWithoutSitePercentage = [Math]::Round(($adSubnetsWithoutSiteCount / $adSubnetCount) * 100)
}else {$adSubnetsWithoutSitePercentage = 0}

#export the report for AD Sites and Subnets
$ADSSReport = [PSCustomObject]@{

    "AD Sites Count" = $adSiteCount
    "AD Sites Without a DC" = $adSitesWithoutDCCount
    "Total % of Unassigned Sites" = $adSitesWithoutDCPercentage
    "AD Subnets Count" = $adSubnetCount
    "AD Subnets without a Site" = $adSubnetsWithoutSiteCount
    "Total % of Unassigned Subnets" = $adSubnetsWithoutSitePercentage
}

$ADSSReport | Export-Csv -Path ".\ADSSReport.csv" -NoTypeInformation

