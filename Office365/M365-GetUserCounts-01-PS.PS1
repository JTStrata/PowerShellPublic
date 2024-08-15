# Import necessary modules
Import-Module AzureADPreview
Import-Module Microsoft.Graph

# Connect to Azure AD
Connect-AzureAD

# Connect to Microsoft Graph
Connect-MgGraph

# Get all users
$users = Get-AzureADUser -All $true

# Create an array to store user details
$userDetails = @()

foreach ($user in $users) {
    $userId = $user.ObjectId

    # Get user licenses
    $licenses = Get-AzureADUserLicenseDetail -ObjectId $userId | Select-Object -ExpandProperty SkuPartNumber -Join ","

    # Check if the user is enabled
    $enabled = if ($user.AccountEnabled) { "Enabled" } else { "Disabled" }

    # Get the last sign-in activity
    $signInActivity = Get-MgUserSignInActivity -UserId $userId
    $lastSignIn = if ($signInActivity) { $signInActivity.LastSignInDateTime } else { "Never Signed In" }

    # Check if the user is cloud-only or synchronized
    $userType = if ($user.DirSyncEnabled) { "Synced" } else { "Cloud Only" }

    # Add user details to the array
    $userDetails += [PSCustomObject]@{
        UserPrincipalName = $user.UserPrincipalName
        DisplayName       = $user.DisplayName
        Licenses          = $licenses
        Status            = $enabled
        LastSignIn        = $lastSignIn
        UserType          = $userType
    }
}

# Export the user details to a CSV file
$userDetails | Export-Csv -Path "C:\Path\To\Save\UserDetails.csv" -NoTypeInformation

Write-Host "User details exported to C:\Path\To\Save\UserDetails.csv"