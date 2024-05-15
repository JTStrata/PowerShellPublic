# PowerShell Script to Backup All GPOs in the Domain

# Import the GroupPolicy module
Import-Module GroupPolicy

# Specify the backup directory
$BackupDirectory = "C:\GPOBackup"

# Create the backup directory if it doesn't exist
if (-not (Test-Path -Path $BackupDirectory)) {
    New-Item -Path $BackupDirectory -ItemType Directory
}

# Get all GPOs in the domain
$GPOs = Get-GPO -All

# Loop through each GPO and back it up
foreach ($GPO in $GPOs) {
    # Display message indicating start of backup for the GPO
    Write-Host "Backing up GPO: $($GPO.DisplayName)"

    # Creating a subfolder for each GPO backup
    $GPOBackupPath = Join-Path -Path $BackupDirectory -ChildPath $GPO.DisplayName
    New-Item -Path $GPOBackupPath -ItemType Directory -Force

    # Backing up the GPO
    Backup-GPO -Guid $GPO.Id -Path $GPOBackupPath

    # Display message after the GPO is backed up
    Write-Host "Successfully backed up GPO: $($GPO.DisplayName) to $GPOBackupPath"
}

Write-Host "Backup of all GPOs is complete."
