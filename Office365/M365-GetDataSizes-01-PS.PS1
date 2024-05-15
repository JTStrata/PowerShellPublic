# Function to check and install a module
function CheckAndInstallModule {
    param (
        [string]$ModuleName,
        [string]$Scope = "CurrentUser"
    )
    $module = Get-Module -ListAvailable -Name $ModuleName
    if ($null -eq $module) {
        Write-Host "$ModuleName module is not installed. FAIL" -ForegroundColor Red
        $userChoice = Read-Host "Do you want to install the $ModuleName module? (Y/N)"
        if ($userChoice -eq "Y") {
            # Check execution policy
            $executionPolicy = Get-ExecutionPolicy
            if ($executionPolicy -ne 'Bypass') {
                $userChoicePolicy = Read-Host "Current execution policy is $executionPolicy. Do you want to set it to Bypass? (Y/N)"
                if ($userChoicePolicy -eq "Y") {
                    Set-ExecutionPolicy Bypass -Scope Process -Force
                    Write-Output "Execution policy set to Bypass."
                }
            }
            # Install and import the module
            Install-Module -Name $ModuleName -Scope $Scope -AllowClobber -Force
            Import-Module $ModuleName -Force
            Write-Host "$ModuleName module installed and imported successfully." -ForegroundColor Green
        } else {
            Write-Host "Skipping $ModuleName module installation." -ForegroundColor Yellow
        }
    } else {
        Write-Host "$ModuleName module is already installed. PASS" -ForegroundColor Green
        
    }
}

# Check for Microsoft.Graph and ExchangeOnlineManagement modules
CheckAndInstallModule -ModuleName "Microsoft.Online.SharePoint.Powershell" 
CheckAndInstallModule -ModuleName "ExchangeOnlineManagement"

# Continue with the script only if the necessary modules are installed
if ((Get-Module -ListAvailable -Name "Microsoft.Online.SharePoint.Powershell") -and (Get-Module -ListAvailable -Name "ExchangeOnlineManagement")) {
    # Your script logic here
    Write-Host "Modules loaded, continuing with the script" -ForegroundColor Green
} else {
    Write-Host "Required modules are not installed. Exiting script." -ForegroundColor Red
    exit
}


# Connect to SharePoint Online
$adminUrl = "https://spragueresources-admin.sharepoint.com"
Connect-SPOService -Url $adminUrl 

#Connect to ExchangeOnline
Connect-ExchangeOnline 

# Get all site collections
$sites = Get-SPOSite -Limit All
# Display site collection details

# Calculate total and average storage used
$numberOfSharePointSites = $sites.Count
$totalSharePointDataGB = ($sites | Measure-Object -Property StorageUsageCurrent -Sum).Sum / 1024 # Converts to GB
$averageSharePointDataGB = $totalSharePointDataGB / $sites.Count


Write-Host "Getting OneDrive sites..."
$OneDrives = Get-SPOSite -IncludePersonalSite $True -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'"

# Calculate total and average storage used
$totalStorageUsed = 0
foreach ($site in $OneDrives) {
    $totalOneDriveStorageUsed += $site.StorageUsageCurrent
}

$numberOfOneDrives = $OneDrives.Count
$totalOneDriveDataGB = $totalOneDriveStorageUsed / 1024 # Converts to GB
$averageOneDriveDataGB = $totalOneDriveDataGB / $numberOfOneDrives


# Retrieve all user mailboxes
$userMailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited

# Initialize variables for total calculations
$totalUserMailboxDataGB = 0
$totalUserMailboxArchiveDataGB = 0

# Loop through each mailbox to calculate sizes
foreach ($userMailbox in $userMailboxes) {
    # Primary Mailbox Size
    $userMailboxStats = Get-MailboxStatistics $userMailbox.UserPrincipalName
    $primaryUserMailboxSizeGB = [math]::Round(($userMailboxStats.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",", "") / 1GB), 2)
    $totalUserMailboxDataGB += $primaryUserMailboxSizeGB

    # Check and calculate Archive Mailbox Size if it exists
    if ($userMailbox.ArchiveGuid -ne [System.Guid]::Empty) {
        $UserMailboxArchiveStats = Get-MailboxStatistics $userMailbox.UserPrincipalName -Archive
        $UserMailboxArchiveSizeGB = [math]::Round(($UserMailboxArchiveStats.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",", "") / 1GB), 2)
        $totalUserMailboxArchiveDataGB += $UserMailboxArchiveSizeGB
    }
}

# Calculate totals and averages
$numberOfUserMailboxes = $userMailboxes.Count
$totalUserMailboxDataGB = $totalUserMailboxDataGB + $totalUserMailboxArchiveDataGB
$averageUserMailboxDataGB = $totalUserMailboxDataGB / $numberOfUserMailboxes


# Retrieve all shared mailboxes
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited

# Initialize variables for total calculations
$totalSharedMailboxDataGB = 0

# Loop through each mailbox to calculate sizes
foreach ($sharedMailbox in $sharedMailboxes) {
    # Primary Mailbox Size
    $sharedMailboxStats = Get-MailboxStatistics $sharedMailbox.UserPrincipalName
    $primarySharedMailboxSizeGB = [math]::Round(($sharedMailboxStats.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",", "") / 1GB), 2)
    $totalSharedMailboxDataGB += $primarySharedMailboxSizeGB
}

# Calculate totals and averages
$numberOfSharedMailboxes = $sharedMailboxes.Count
$averageSharedMailboxDataGB = if ($numberOfSharedMailboxes -eq 0) { 0 } else { $totalSharedMailboxDataGB / $numberOfSharedMailboxes }



# Public Folders

# Check for Public Folders
$PublicFoldersExist = 1
try {
    $publicFolders = Get-PublicFolder -Recurse -ResultSize Unlimited 
    if ($publicFolders.Count -eq 0) {
    $PublicFoldersExist = 0
        Write-Host "There are no public folders." -ForegroundColor Green

    }
} catch {
    $PublicFoldersExist = 0
    Write-Host "There are no public folders or unable to retrieve public folders." -ForegroundColor Green

}

# Your script continues here if public folders exist...

if($PublicFoldersExist = 1){
$totalPublicFolderDataGB = @()
$i = 0
foreach ($publicfolder in $publicFolders){
$i++
write-host "$i of $($publicfolders.count) - $($publicfolder.name)"
$totalPublicFolderDataKB = [math]::Round(($publicFolder.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",", "") / 1KB), 2)
$totalPublicFolderDataMB = [math]::Round($totalPublicFolderDataKB /1KB, 2)
$totalPublicFolderDataGB = $totalPublicFolderDataMB /1024
$totalPublicFolderDataGB += $primaryPublicFolderSizeGB
}

# Calculate totals and averages
$numberOfPublicFolders = $publicFolders.Count
$averagePublicFolderDataGB = $totalPublicFolderDataGB / $numberOfPublicFolders
}



# Output Results
Write-Host "SharePoint Results" -ForegroundColor Magenta
Write-Output "SharePoint Sites Number: $numberOfSharePointSites"
Write-Output "Total SharePoint Data: $totalSharePointDataGB GB"
Write-Output "Average Data Per SharePoint Site: $averageSharePointDataGB GB"

Write-Host "OneDrive Results" -ForegroundColor Magenta
Write-Output "OneDrives Number: $numberOfOneDrives"
Write-Output "Total OneDrive Data: $totalOneDriveDataGB GB"
Write-Output "Average Data Per OneDrive: $averageOneDriveDataGB GB"

Write-Host "User Mailbox Results" -ForegroundColor Magenta
Write-Output "User Mailboxes Number: $numberOfUserMailboxes"
Write-Output "Total User Mailboxes Data: $totalUserMailboxDataGB GB"
Write-Output "Average Data Per User Mailbox: $averageUserMailboxDataGB GB"

Write-Host "Shared Mailboxes Results" -ForegroundColor Magenta
Write-Host "Number of Shared Mailboxes: $numberOfSharedMailboxes"
Write-Host "Total Shared Mailbox Data: $totalSharedMailboxDataGB GB"
Write-Host "Average Shared Mailbox Data per Mailbox: $averageSharedMailboxDataGB GB"

if($PublicFoldersExist = 1){
Write-Host "Public Folder Results" -ForegroundColor Magenta
Write-Output "Public Folders Number: $numberOfPublicFolders"
Write-Output "Total Public Folder Data: $totalPublicFolderDataGB GB"
Write-Output "Average Data Per Public Folder: $averagePublicFolderDataGB GB"
}

