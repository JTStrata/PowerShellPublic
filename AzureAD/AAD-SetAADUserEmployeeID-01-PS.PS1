$users = Get-AzureADUser -All $true | Where-Object { -not $_.ExtensionProperty.employeeId -and $_.department -ne $null } | Select-Object DisplayName, UserPrincipalName, ObjectId

foreach ($user in $users) {
    # Create a dictionary for the extension property
    $employeeId = New-Object 'System.Collections.Generic.Dictionary[String,String]'
    $employeeId.Add("employeeId", "XXXX") # Replace "XXXX" with the actual value you want to set

    # Set the employeeId extension property for the user
    Set-AzureADUser -ObjectId $user.ObjectId -ExtensionProperty $employeeId
    Write-Host "Set EmployeeID for user: $($user.DisplayName)"
}


# Get all users and select the EmployeeId along with other common properties
Get-AzureADUser -All $true | Select-Object UserPrincipalName, ObjectId, @{Name="EmployeeId";Expression={$_.ExtensionProperty.employeeId}}
