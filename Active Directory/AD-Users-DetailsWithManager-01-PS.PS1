<#
.SYNOPSIS
Exports AD user data from a selected OU to a CSV file.

.DESCRIPTION
This script prompts the user to select an OU in Active Directory and then exports user data from that OU to a CSV file. The user is presented with a file selection dialog box to choose the location to save the CSV file.

.PARAMETER None

.EXAMPLE
PS C:\> .\AD-Users-DetailsWithManager-01-PS.ps1
This example exports user data from a selected OU in Active Directory to a CSV file.

.NOTES
This script requires the ActiveDirectory module. The user running the script must have permissions to read AD objects in the selected OU and write to the selected file location.
#>

# Import the ActiveDirectory module
Import-Module ActiveDirectory

# Import the Windows Forms namespace
Add-Type -AssemblyName System.Windows.Forms

# Prompt the user to select a location to save the exported CSV file
$saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog -Property @{
    Title = "Save results to CSV"
    Filter = "CSV files (*.csv)|*.csv"
}

if ($saveFileDialog.ShowDialog() -eq 'OK') {
    $csvPath = $saveFileDialog.FileName

    # Prompt the user to select an OU using Out-GridView
    $ou = Get-ADOrganizationalUnit -Filter * | Out-GridView -Title "Select an OU to search in" -OutputMode Single

    # Check if an OU was selected, and if so, run the Get-ADUser command and export to CSV
    if ($ou) {
        Get-ADUser -SearchBase $ou.DistinguishedName -Properties * -Filter * |
        Select-Object Name, Title, @{Name="Manager";Expression={(Get-ADUser $_.Manager -Properties Name).Name}} |
        Export-Csv -Path $csvPath -NoTypeInformation
        Write-Host "Results saved to $csvPath."
    }
    else {
        Write-Host "No OU selected."
    }
}
else {
    Write-Host "No file selected."
}
