<#===Azure AD===#>
#Connect-AzureAD
$azureadusers = Get-AzureADUser -All:$true | Select-Object displayname,objectid,objecttype,userprincipalname
Write-Host "Number of Azure AD Users $($azureadusers.count)"

<#===Exchnage Online===#>
#Connect-ExchangeOnline

# Get all mailboxes with their statistics
$mailboxes = Get-Mailbox -ResultSize Unlimited

# Filter out different types of mailboxes into separate variables
$userMailboxes = $mailboxes | Where-Object { $_.RecipientTypeDetails -eq "UserMailbox" }
$sharedMailboxes = $mailboxes | Where-Object { $_.RecipientTypeDetails -eq "SharedMailbox" }
$roomMailboxes = $mailboxes | Where-Object { $_.RecipientTypeDetails -eq "RoomMailbox" }
$equipmentMailboxes = $mailboxes | Where-Object { $_.RecipientTypeDetails -eq "EquipmentMailbox" }
$schedulingMailboxes = $mailboxes | Where-Object { $_.RecipientTypeDetails -eq "SchedulingMailbox" }
$discoveryMailboxes = $mailboxes | Where-Object { $_.RecipientTypeDetails -eq "DiscoveryMailbox" }


# Get statistics for each type
$userMailboxStats = $userMailboxes | Get-MailboxStatistics
$sharedMailboxStats = $sharedMailboxes | Get-MailboxStatistics
$roomMailboxStats = $roomMailboxes | Get-MailboxStatistics
$equipmentMailboxStats = $equipmentMailboxes | Get-MailboxStatistics
$schedulingMailboxStats = $schedulingMailboxes | Get-MailboxStatistics
$discoveryMailboxStats = $discoveryMailboxes | Get-MailboxStatistics

# Filter mailboxes that have an archive enabled
$archivedMailboxes = $mailboxes | Where-Object { $_.ArchiveStatus -eq "Active" }

# Get statistics for only these archived mailboxes
$archiveMailboxStatistics = $archivedMailboxes | Get-MailboxStatistics -Archive


# Summarize statistics and create a custom table for each mailbox type
$Mailboxresults = @()

# Function to calculate total storage and count
function CalculateStats($mailboxStats) {
    $totalSize = 0
    $count = 0

    foreach ($stat in $mailboxStats) {
        # Extract the byte count from the TotalItemSize string, assuming format like '23.88 GB (25,638,432,942 bytes)'
        $byteString = $stat.TotalItemSize.ToString().Split('(')[1].Trim(' bytes)')
        $bytes = [int64]::Parse($byteString.Replace(',', ''))

        $totalSize += $bytes
    }
    $count = $mailboxStats.Count
    $totalSizeGB = [math]::Round($totalSize / 1GB, 2)
    
    return @($count, $totalSizeGB)
}


# Calculate stats for each type of mailbox
$userStats = CalculateStats $userMailboxStats
$sharedStats = CalculateStats $sharedMailboxStats
$roomStats = CalculateStats $roomMailboxStats
$equipmentStats = CalculateStats $equipmentMailboxStats
$schedulingStats = CalculateStats $schedulingMailboxStats
$discoveryStats = CalculateStats $discoveryMailboxStats
$archiveStats = CalculateStats $archiveMailboxStatistics

# Add results to the array
$Mailboxresults += [PSCustomObject]@{
    MailboxType  = "User Mailboxes"
    TotalNumber  = $userStats[0]
    TotalStorage = "$($userStats[1]) GB"
}
$Mailboxresults += [PSCustomObject]@{
    MailboxType  = "Shared Mailboxes"
    TotalNumber  = $sharedStats[0]
    TotalStorage = "$($sharedStats[1]) GB"
}
$Mailboxresults += [PSCustomObject]@{
    MailboxType  = "Room Mailboxes"
    TotalNumber  = $roomStats[0]
    TotalStorage = "$($roomStats[1]) GB"
}
$Mailboxresults += [PSCustomObject]@{
    MailboxType  = "Equipment Mailboxes"
    TotalNumber  = $equipmentStats[0]
    TotalStorage = "$($equipmentStats[1]) GB"
}
$Mailboxresults += [PSCustomObject]@{
    MailboxType  = "Scheduling Mailboxes"
    TotalNumber  = $schedulingStats[0]
    TotalStorage = "$($schedulingStats[1]) GB"
}
$Mailboxresults += [PSCustomObject]@{
    MailboxType  = "Discovery Mailboxes"
    TotalNumber  = $discoveryStats[0]
    TotalStorage = "$($discoveryStats[1]) GB"
}
$Mailboxresults += [PSCustomObject]@{
    MailboxType  = "Archive Mailboxes"
    TotalNumber  = $archiveStats[0]
    TotalStorage = "$($archiveStats[1]) GB"
}

# Display results
$Mailboxresults | Format-Table -AutoSize

# Retrieve all public folders
$publicFolders = Get-PublicFolder -Recurse -ResultSize Unlimited

# Initialize variables
$batchSize = 100
$totalFolders = $publicFolders.Count
$allFolderStats = @()
$totalStorage = 0

# Process each batch
for ($i = 0; $i -lt $totalFolders; $i += $batchSize) {
    # Select a subset of public folders based on current index and batch size
    $currentBatch = $publicFolders | Select-Object -Skip $i -First $batchSize
    $b = 0 #for items in batch
    Write-Host "Batch $i" -ForegroundColor Gray -BackgroundColor black
    foreach ($folder in $currentBatch) {
    $b ++
    Write-Host "$b/$($publicFolders.count)" -ForegroundColor Gray -BackgroundColor black
        try {
            # Fetch statistics for each folder in the current batch
            $stats = Get-PublicFolderStatistics -Identity $folder.Identity
            # Add the stats to the allFolderStats array
            $allFolderStats += $stats
        } catch {
            Write-Error "Failed to fetch stats for folder $($folder.Identity): $_"
        }
    }
}

# Calculate total size
foreach ($stat in $allFolderStats) {
    if ($stat.TotalItemSize -and $stat.TotalItemSize.ToString().Contains("(")) {
        $byteString = $stat.TotalItemSize.ToString().Split("(")[1].Trim(" bytes)")
        $bytes = [int64]::Parse($byteString.Replace(',', ''))
        $totalStorage += $bytes
    }
}

# Convert total bytes to GB
$totalStorageGB = [math]::Round($totalStorage / 1GB, 2)

# Output the total size
Write-Output "Total storage used by all public folders: $totalStorageGB GB"

# Disconnect from Exchange Online
Disconnect-ExchangeOnline


# Count how many public folders are mail-enabled
$mailEnabledCount = ($publicFolders | Where-Object { $_.MailEnabled -eq $true }).Count

# Total number of public folders
$totalPublicFolders = $publicFolders.Count

# Create a custom object to hold the results
$publicFolderResults = [PSCustomObject]@{
    TotalPublicFolders = $totalPublicFolders
    MailEnabledFolders = $mailEnabledCount
    TotalStorageGB = $totalSizeGB
}

# Display the results
$publicFolderResults



<#===SharePoint=== #>
#Connect-SPOService https://spragueresources-admin.sharepoint.com
$siteCollections = Get-SPOSite -Limit All -Detailed
Write-Host "Number of SharePoint Site Collections $($siteCollections.count)"

# Initialize total size variable
$totalSize = 0

# Loop through each site to get the size and accumulate the total size
foreach ($site in $siteCollections) {
    $siteSize = $site.StorageUsageCurrent
    $totalSize += $siteSize
    Write-Output "Site URL: $($site.Url) - Size: $($siteSize) MB"
}

# Convert total size to GB for easier reading
$totalSizeGB = [math]::Round($totalSize / 1024, 2)


<#===OneDrive=== #>
# Get a list of all OneDrive sites
$oneDriveSites = Get-SPOSite -IncludePersonalSite $true -Limit All | Where-Object { $_.Url -like "*-my.sharepoint.com/personal/*" }

# Retrieve storage information
$totalStorageUsed = 0
$userStorageDetails = @()

foreach ($site in $oneDriveSites) {
    $storageUsed = $site.StorageUsageCurrent
    $totalStorageUsed += $storageUsed
    $userStorageDetails += [PSCustomObject]@{
        User = $site.Owner
        StorageUsedMB = $storageUsed
    }
}

# Display per user storage
$UsersWithData = $userStorageDetails | Where-Object {$_.StorageUsedMB -ne "0"} | Format-Table User, StorageUsedMB

# Display total storage used in GB
$totalStorageInGB = [math]::Round($totalStorageUsed / 1024, 2)
Write-Host "Total users with OneDrive Storage Used: $($UsersWithData.count)" -ForegroundColor Green -BackgroundColor Black
Write-Host "Total OneDrive Storage Used: $totalStorageInGB GB"  -ForegroundColor Green -BackgroundColor Black

