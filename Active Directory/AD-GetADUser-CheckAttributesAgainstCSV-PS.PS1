#$cred = Get-Credential
#$searchbase = "ou=people,dc=company,dc=com"
 
$csv = Import-Csv C:\Users\tiannillo\Downloads\UpdateUserInfo.csv

foreach ($csvObj in $csv) {

    try {

        $samaccountname = $csvObj.upn.split("@")[0]
        $user = Get-ADUser $samaccountname -Properties *


        Write-Host "$($user.displayname) found. Matching user" -ForegroundColor Green

        IF ($csvObj.legalfirstname -eq $user.GivenName) { write-host " Firstname $($csvObj.legalfirstname) $($user.GivenName) match" -ForegroundColor Green }
        else { write-host "Firstname $($csvObj.legalfirstname) $($user.GivenName) mismatch" -ForegroundColor Yellow }

        IF ($csvObj.legallastname -eq $user.Surname) { write-host "Lastname $($csvObj.legallastname) $($user.Surname) match" -ForegroundColor Green }
        else { write-host "Lastname $($csvObj.legallastname) $($user.Surname) mismatch" -ForegroundColor Yellow }

        IF ($csvObj.jobtitle -eq $user.Description) { write-host " Title $($csvObj.jobtitle) $($user.Description) match" -ForegroundColor Green }
        else { write-host " Title $($csvObj.jobtitle) $($user.Description) mismatch" -ForegroundColor Yellow }

        IF ($csvObj.displayname -eq $user.DisplayName) { write-host "Displayname $($csvObj.DisplayName) $($user.DisplayName) match" -ForegroundColor Green }
        else { write-host "Displayname $($csvObj.DisplayName) $($user.DisplayName) mismatch" -ForegroundColor Yellow }

        IF ($csvObj.emailaddress1 -eq $user.EmailAddress) { write-host "Email $($csvObj.emailaddress1) $($user.EmailAddress) match" -ForegroundColor Green }
        else { write-host "Email $($csvObj.emailaddress1) $($user.EmailAddress) mismatch" -ForegroundColor Yellow }

        IF ($csvObj.Street -eq $user.StreetAddress) { write-host "Street $($csvObj.Street) $($user.StreetAddress) match" -ForegroundColor Green }
        else { write-host "Street $($csvObj.Street) $($user.StreetAddress) mismatch" -ForegroundColor Yellow }

        IF ($csvObj.City -eq $user.City) { write-host "City $($csvObj.City) $($user.City) match" -ForegroundColor Green }
        else { write-host "City $($csvObj.City) $($user.City) mismatch" -ForegroundColor Yellow }

        IF ($csvObj.State -eq $user.State) { write-host "State $($csvObj.State) $($user.State) match" -ForegroundColor Green }
        else { write-host "State $($csvObj.State) $($user.State) mismatch" -ForegroundColor Yellow }

        IF ($csvObj.zipcode -eq $user.PostalCode) { write-host "Zip $($csvObj.zipcode) $($user.PostalCode) match" -ForegroundColor Green }
        else { write-host "Zip $($csvObj.zipcode) $($user.PostalCode) mismatch" -ForegroundColor Yellow }

        IF ($csvObj.jobtitle -eq $user.Title) { write-host "Title $($csvObj.jobtitle) $($user.Title) match" -ForegroundColor Green }
        else { write-host "Title $($csvObj.jobtitle) $($user.Title) mismatch" -ForegroundColor Yellow }

        IF ($csvObj.Department -eq $user.Department) { write-host "Dept $($csvObj.Department) $($user.Department) match" -ForegroundColor Green }
        else { write-host "Dept $($csvObj.Department) $($user.Department) mismatch" -ForegroundColor Yellow }

        IF ($csvObj.Company -eq $user.Company) { write-host "Company $($csvObj.Company) $($user.Company) match" -ForegroundColor Green }
        else { write-host "Company $($csvObj.Company) $($user.Company) mismatch" -ForegroundColor Yellow }

        IF ($csvObj.City -eq $user.Organization) { write-host "Org $($csvObj.City) $($user.Organization) match" -ForegroundColor Green }
        else { write-host "Org $($csvObj.City) $($user.Organization) mismatch" -ForegroundColor Yellow }

        IF ($csvObj.Manager) {
            $csvManager = Get-ADUser $csvObj.manager | Select-Object distinguishedname, name
            IF ($csvManager.distinguishedname -eq $user.Manager) { write-host "Manager $($csvObj.Manager) $($user.Manager) match for $($user.displayname)" -ForegroundColor Green }
            else { write-host "Manager $($csvManager.name) $($user.Manager) mismatch for $($user.displayname)" -ForegroundColor Yellow }
        }

        IF ($csvObj.workphone) {
            IF ($csvObj.workphone -eq $user.OfficePhone) { write-host "Office Phone $($csvObj.workphone) $($user.OfficePhone) match" -ForegroundColor Green }
            else { write-host "Office Phone $($csvObj.workphone) $($user.OfficePhone) mismatch" -ForegroundColor Yellow }
        }

        IF ($csvObj.mobilephone) {
            IF ($csvObj.mobilephone -eq $user.MobilePhone) { write-host "Mobile $($csvObj.mobilephone) $($user.MobilePhone) match" -ForegroundColor Green }
            else { write-host "Mobile $($csvObj.mobilephone) $($user.MobilePhone) mismatch" -ForegroundColor Yellow }
        }

    }
    catch { write-host "can' find the $($user.displayname)" }

}

