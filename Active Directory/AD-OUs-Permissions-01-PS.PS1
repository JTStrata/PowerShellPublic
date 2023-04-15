Import-Module ActiveDirectory
Add-Type -AssemblyName System.Windows.Forms
[System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.AccountManagement") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.ActiveDirectory") | Out-Null




$dialogResult = [System.Windows.Forms.MessageBox]::Show("Click Yes to Export Permissions. Click No to Import Permissions", "Are you Exporting OU Permissions? ", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question, [System.Windows.Forms.MessageBoxDefaultButton]::Button1, [System.Windows.Forms.MessageBoxOptions]::DefaultDesktopOnly)

if ($dialogResult -eq [System.Windows.Forms.DialogResult]::Yes) {
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "CSV files (*.csv)|*.csv"
    $saveFileDialog.Title = "Export OU Security Permissions as CSV"
    $saveFileDialog.ShowDialog()

    if ($saveFileDialog.FileName -ne "") {
        $ous = Get-ADOrganizationalUnit -Filter * -Properties CanonicalName | Select-Object Name, CanonicalName, DistinguishedName | Sort-Object CanonicalName

        $results = foreach ($ou in $ous) {
            write-host "Security for OU $($ou.distinguishedname):" -ForegroundColor White -BackgroundColor Black
        
            $acl = get-acl -Path "AD:\$($ou.distinguishedname)"
            $acl.access | Where-Object { ($_.isinherited -eq $false) -and 
                ($_.identityreference -notlike "*s-1*") -and 
                ($_.identityreference -notlike "NT Authority\*") -and 
                ($_.identityreference -notlike "Builtin\*") -and 
                ($_.identityreference -ne "everyone") -and 
                ($_.identityreference -notlike "*domain admins*") -and 
                ($_.identityreference -notlike "*enterprise admins*") -and 
                ($_.identityreference -notlike "*administrators*") -and 
                ($_.identityreference -notlike "*print operators*") -and 
                ($_.identityreference -notlike "*account operators*") -and 
                ($_.identityreference -notlike "*creator owner*") -and
                ($_.identityreference -notlike "Msol_*") -and 
                ($_.identityreference -notlike "RTCU*") } | Select-Object @{Name = "OU"; Expression = { $ou.canonicalname } }, IdentityReference, ActiveDirectoryRights, AccessControlType, ObjectType, InheritanceType, InheritedObjectType
        }

        $results | Export-Csv -Path $saveFileDialog.FileName -NoTypeInformation -Encoding UTF8 -Delimiter ","
        Write-Host "CSV file saved successfully." -BackgroundColor Black -ForegroundColor Green
    }
}
elseif ($dialogResult -eq [System.Windows.Forms.DialogResult]::No) {
    $importFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $importFileDialog.Filter = "CSV files (*.csv)|*.csv"
    $importFileDialog.Title = "Import OU Security Permissions from CSV"
    $importFileDialog.ShowDialog()

    if ($importFileDialog.FileName -ne "") {
        $permissions = Import-Csv -Path $importFileDialog.FileName

        $ous = Get-ADOrganizationalUnit -Filter * -Properties CanonicalName | Select-Object Name, CanonicalName, DistinguishedName | Sort-Object CanonicalName
        $permissionCount = $permissions.Count
        $permissionIndex = 0

        foreach ($permission in $permissions) {
            $permissionIndex++
            $ouCanonicalName = $permission.OU
            $idr = $permission.IdentityReference.Split("\")[1]
            write-host "Principal is $($idr)" -BackgroundColor Black -ForegroundColor Gray
            $Principal = Get-ADObject -filter 'samaccountname -like $idr' -Properties objectsid | Select-Object objectsid
            if ($Principal) {

                $SID = New-Object System.Security.Principal.SecurityIdentifier $Principal.ObjectSID
                $ObjectGUID = New-Object Guid  $permission.ObjectType
                $ActiveDirectoryRights = $permission.ActiveDirectoryRights
                $AccessControlType = $permission.AccessControlType
                $InheritedObjectType = $permission.InheritedObjectType 
                $inheritedObjectGUID = New-Object Guid $InheritedObjectType
                $InheritanceType = $permission.InheritanceType   
            

                Write-Host "Checking $($ouCanonicalName)"

                $ouDistinguishedName = ($ous | Where-Object { $_.CanonicalName -eq $ouCanonicalName }).DistinguishedName

                if ($ouDistinguishedName -ne $null) {
                    $existingPermissions = Get-Acl -Path "AD:\$ouDistinguishedName" | Select-Object -ExpandProperty Access

                    if ($existingPermissions -notcontains $permission) {
                        Write-Host "Setting permissions on $($permission.ou)"

                        $acl = Get-Acl -Path "AD:\$ouDistinguishedName"
                        $accessRule = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid, $ActiveDirectoryRights, $AccessControlType, $ObjectGUID, $InheritanceType, $inheritedObjectGUID
                        $acl.AddAccessRule($accessRule)
                        Set-Acl -Path "AD:\$ouDistinguishedName" -AclObject $acl

                        $percentComplete = [Math]::Round(($permissionIndex / $permissionCount) * 100)
                        Write-Host "Completed $($percentComplete)% of permissions." -BackgroundColor Black -ForegroundColor Gray
                    }
                    else {
                        Write-Host "Skipping $($permission.IdentityReference) $($permission.AccessControlType) $($permission.ActiveDirectoryRights)" -BackgroundColor Black -ForegroundColor White

                    }
                }
            }
            else { Write-Host "Could not find $($idr), skipping" -ForegroundColor White -BackgroundColor Red }
        
        }
    }
}
