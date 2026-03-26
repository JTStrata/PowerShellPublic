# Requires Microsoft Graph PowerShell
# Install once if needed:
# Install-Module Microsoft.Graph -Scope CurrentUser

$csvPath   = "/Users/julian.thibeault/Downloads/Users (1).csv"
$groupName = "ea-egnyte-standardusers"

# Connect to Microsoft Graph
#Connect-MgGraph -Scopes "Group.Read.All","User.Read.All" -NoWelcome

# Import CSV
$csvUsers = Import-Csv -Path $csvPath

if (-not $csvUsers) {
    Write-Host "CSV file is empty or could not be read: $csvPath" -ForegroundColor Red
    return
}

if (-not ($csvUsers[0].PSObject.Properties.Name -contains "IdpUserID")) {
    Write-Host "CSV does not contain a column named 'IdpUserID'." -ForegroundColor Red
    return
}

# Get target group
$group = Get-MgGroup -Filter "displayName eq '$groupName'"

if (-not $group) {
    Write-Host "Group not found: $groupName" -ForegroundColor Red
    return
}

# Get all group members, then resolve to users so we can read UPN
$groupMemberRefs = Get-MgGroupMember -GroupId $group.Id -All
$groupUsers = foreach ($member in $groupMemberRefs) {
    if ($member.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.user') {
        Get-MgUser -UserId $member.Id -Property Id,DisplayName,UserPrincipalName
    }
}

# Normalize lookup sets
$csvIdpUserIds = $csvUsers |
    Where-Object { $_.IdpUserID -and $_.IdpUserID.Trim() -ne "" } |
    ForEach-Object { $_.IdpUserID.Trim().ToLower() } |
    Sort-Object -Unique

$groupUpns = $groupUsers |
    Where-Object { $_.UserPrincipalName } |
    ForEach-Object { $_.UserPrincipalName.Trim().ToLower() } |
    Sort-Object -Unique

# Build comparison results
$results = foreach ($user in $groupUsers) {
    $upn = $user.UserPrincipalName.Trim().ToLower()

    [PSCustomObject]@{
        DisplayName      = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        InCsv            = $csvIdpUserIds -contains $upn
        Status           = if ($csvIdpUserIds -contains $upn) { "MATCH" } else { "MISSING_IN_CSV" }
    }
}

# Find CSV users missing from the Entra group
$csvOnlyResults = foreach ($idp in $csvIdpUserIds) {
    if ($groupUpns -notcontains $idp) {
        [PSCustomObject]@{
            DisplayName       = ""
            UserPrincipalName = $idp
            InCsv             = $true
            Status            = "MISSING_IN_GROUP"
        }
    }
}

$allResults = $results + $csvOnlyResults

# Summary
Write-Host ""
Write-Host "Comparison complete" -ForegroundColor Cyan
Write-Host "CSV records with IdpUserID: $($csvIdpUserIds.Count)"
Write-Host "Group user members:         $($groupUpns.Count)"
Write-Host "Matches:                    $(($allResults | Where-Object { $_.Status -eq 'MATCH' }).Count)" -ForegroundColor Green
Write-Host "Missing in CSV:             $(($allResults | Where-Object { $_.Status -eq 'MISSING_IN_CSV' }).Count)" -ForegroundColor Yellow
Write-Host "Missing in Group:           $(($allResults | Where-Object { $_.Status -eq 'MISSING_IN_GROUP' }).Count)" -ForegroundColor Yellow
Write-Host ""

# Console visual output
$allResults |
    Sort-Object Status, UserPrincipalName |
    Format-Table DisplayName, UserPrincipalName, InCsv, Status -AutoSize

# Optional popup grid view if running on Windows PowerShell / desktop session
# Uncomment if you want a clickable visual window
# $allResults | Sort-Object Status, UserPrincipalName | Out-GridView -Title "CSV vs Entra Group Comparison"