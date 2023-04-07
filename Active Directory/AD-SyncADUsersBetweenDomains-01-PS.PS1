$sourceserver = "sourceDC.sourcedomain.com"
$SourceSearchBase = "OU=Users,DC=sourcedomain,DC=com"
$sourceUsers = Get-ADUser -Server $sourceserver -SearchBase $SourceSearchBase -filter 'Description -like "*"' -Properties *
$targetServer = "targetDC.targetdomain.com" 

foreach ($sourceUser in $sourceUsers) {
    Write-Host "Trying to locate $($sourceuser.displayname) with SamaccountName of $($sourceUser.samaccountname)"

    $samMatch = Get-ADUser $sourceUser.SamAccountName -Server $targetServer -Properties *

    if ($samMatch) {
        write-host "$($sourceUser.samaccountname) was found" -ForegroundColor Green
    
        $managerCN = $sourceUser.manager -replace '^CN=|,.*$'

        $nameMatchHash = @{'Identity' = $samMatch.distinguishedname; 'Description' = $sourceUser.description; 'Office' = $sourceUser.City; 'GivenName' = $sourceUser.GivenName; 'Surname' = $sourceUser.Surname; 'DisplayName' = $sourceUser.DisplayName; 'StreetAddress' = $sourceUser.StreetAddress; 'City' = $sourceUser.City; 'State' = $sourceUser.State; 'PostalCode' = $sourceUser.PostalCode;
            'Country' = $sourceUser.Country; 'OfficePhone' = $sourceUser.OfficePhone; 'Replace' = @{'Mobile' = $sourceUser.Mobile }; 'Fax' = $sourceUser.Fax; 'Title' = $sourceUser.Title; 'Department' = $sourceUser.Department; 'Company' = $sourceUser.Company; 'Manager' = (Get-ADUser -Filter "displayname -eq '$($managerCN)'").distinguishedname
        }
        Set-ADUser @nameMatchHash
    }
    else { write-host "$($sourceUser.samaccountname) was not found" -ForegroundColor Red }
}
