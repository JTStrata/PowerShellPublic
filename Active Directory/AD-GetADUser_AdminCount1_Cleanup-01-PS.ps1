<#
.SYNOPSIS
This script checks for AD user accounts with the adminCount set to 1 and identifies whether 
they are directly members of an administrative group.

.DESCRIPTION
This script does the following:
- Prompts the user to enter a domain name (or use the current domain).
- Searches for AD user accounts with the adminCount attribute set to 1.
- Determines if these accounts are directly members of administrative groups.
- Outputs the results in a tabular form with color coding.
- Offers the user an option to clear the adminCount attribute from accounts not in admin groups.

.NOTES
File Name      : Check-AdminCount.ps1
Author         : Julian Thibeault
Prerequisite   : PowerShell V3
Copyright 2023 : StrataNorth.co

.LINK
[]

.EXAMPLE
./Check-AdminCount.ps1

#>

# Import required module
Import-Module ActiveDirectory

function Get-NestedGroupMembership {
    param (
        [string]$DistinguishedName
    )

    $groups = Get-ADGroup -Identity $DistinguishedName -Properties memberOf | Select-Object -ExpandProperty memberOf
    $nestedGroups = @()

    foreach ($group in $groups) {
        $nestedGroups += Get-NestedGroupMembership -DistinguishedName $group
    }

    return $groups + $nestedGroups
}

# Prompt user for domain name or use the current domain
$domainName = Read-Host "Press [Enter] to search within the current domain or enter the domain name"
if (-not $domainName) {
    $domainName = (Get-ADDomain).DNSRoot
}

Write-Host "Searching within domain: $domainName" -ForegroundColor Yellow

# List of administrative groups that would grant adminCount = 1
$adminGroups = @(
    "CN=Administrators,CN=Builtin,$((Get-ADDomain).DistinguishedName)",
    "CN=Domain Admins,CN=Users,$((Get-ADDomain).DistinguishedName)",
    "CN=Enterprise Admins,CN=Users,$((Get-ADDomain).DistinguishedName)",
    "CN=Account Operators,CN=Builtin,$((Get-ADDomain).DistinguishedName)",
    "CN=Backup Operators,CN=Builtin,$((Get-ADDomain).DistinguishedName)",
    "CN=Domain Controllers,$((Get-ADDomain).DistinguishedName)",
    "CN=Print Operators,CN=Builtin,$((Get-ADDomain).DistinguishedName)",
    "CN=Read-only Domain Controllers,$((Get-ADDomain).DistinguishedName)",
    "CN=Schema Admins,CN=Users,$((Get-ADDomain).DistinguishedName)",
    "CN=Server Operators,CN=Builtin,$((Get-ADDomain).DistinguishedName)"
)

# Check user accounts with adminCount set to 1, but exclude the krbtgt account
$usersWithAdminCount = Get-ADUser -Filter {(adminCount -eq 1) -and (SamAccountName -ne "krbtgt")} -Server $domainName -Properties adminCount, MemberOf

$results = @()

foreach ($user in $usersWithAdminCount) {
    $directGroups = $user.MemberOf

    # Identify which of the direct groups are administrative groups
    $matchingAdminGroups = $directGroups | Where-Object { $adminGroups -contains $_ }

    # If none of the direct groups are administrative groups, check if they are nested within one
    if (-not $matchingAdminGroups) {
        foreach ($group in $directGroups) {
            if (Get-NestedGroupMembership -DistinguishedName $group | Where-Object { $adminGroups -contains $_ }) {
                $matchingAdminGroups += (Get-ADGroup -Identity $group).DistinguishedName
                break
            }
        }
    }

    if ($matchingAdminGroups.Count -gt 0) {
        $isAdmin = "YES"
    } else {
        $isAdmin = "NO"
        $usersToClear += $user
    }

    $results += [PSCustomObject]@{
        'UserName'       = $user.SamAccountName
        'AdminCount'     = $user.adminCount
        'IsAdminGroup'   = $isAdmin
        'AdminGroups'    = ($matchingAdminGroups -join ', ')
    }
}

# Display the table header
Write-Host ("{0,-20} {1,-10} {2,-12} {3,-60}" -f "UserName", "AdminCount", "IsAdminGroup", "AdminGroups")

# Display results in a sorted, uniform table with color coding
$results | Sort-Object IsAdminGroup, UserName | ForEach-Object {
    if ($_.IsAdminGroup -eq "YES") {
        Write-Host ("{0,-20} {1,-10} {2,-12} {3,-60}" -f $_.UserName, $_.AdminCount, $_.IsAdminGroup, $_.AdminGroups) -ForegroundColor Green
    } else {
        Write-Host ("{0,-20} {1,-10} {2,-12} {3,-60}" -f $_.UserName, $_.AdminCount, $_.IsAdminGroup, $_.AdminGroups) -ForegroundColor Magenta
    }
}

# Prompt user to clear adminCount for users that aren't in admin groups
$response = Read-Host "Would you like to clear the admin count from the accounts which are not in admin groups? Press Y to perform the cleanup and any other key to abort"
if ($response -eq "Y" -or $response -eq "y") {
    foreach ($user in $usersToClear) {
        Set-ADUser -Identity $user.DistinguishedName -Clear adminCount
        Write-Host "Cleared adminCount for user $($user.SamAccountName)" -ForegroundColor Cyan
    }
} else {
    Write-Host "Cleanup aborted." -ForegroundColor Red
}
