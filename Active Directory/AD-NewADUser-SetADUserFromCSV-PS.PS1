#$cred = Get-Credential
#$searchbase = "ou=people,dc=company,dc=com"
 
$csv = Import-Csv C:\Users\tiannillo\Downloads\UpdateUserInfo.csv

foreach ($csvObj in $csv) {

    try {

        $samaccountname = $csvObj.upn.split("@")[0]
        $user = Get-ADUser $samaccountname -Properties *

        Write-Host "$($user.displayname) found. Updating user" -ForegroundColor Green

        Set-ADUser -Identity $user.DistinguishedName -Credential $cred `
            -SamAccountName $samaccountname `
            -GivenName $csvObj.legalfirstname `
            -Surname $csvObj.legallastname `
            -Description $csvobj.jobtitle `
            -DisplayName $csvObj.displayname `
            -EmailAddress $csvObj.emailaddress1 `
            -StreetAddress $csvObj.street `
            -City $csvObj.city `
            -State $csvObj.state `
            -PostalCode $csvObj.zipcode `
            -Title $csvObj.jobtitle `
            -Department $csvObj.department `
            -Company $csvObj.company `
            -CannotChangePassword $false `
            -PasswordNeverExpires $false `
            -ChangePasswordAtLogon $false `
            -PasswordNotRequired $false `
            -Organization $csvObj.City

        IF ($csvObj.manager) { Set-ADUser -Identity $user.DistinguishedName -Credential $cred -Manager $csvObj.manager }
 
        IF ($csvObj.workphone) { Set-ADUser -Identity $user.DistinguishedName -Credential $cred -OfficePhone $csvObj.workphone }

        IF ($csvObj.mobilephone) { Set-ADUser -Identity $user.DistinguishedName -Credential $cred -MobilePhone $csvObj.mobilephone }

    }

    catch {

        Write-Host "$($csvobj.displayname) not found. User will be created" -ForegroundColor Yellow

        New-ADUser -Credential $cred -Name $csvObj.displayname -GivenName $csvObj.legalfirstname `
            -accountPassword (ConvertTo-SecureString -AsPlainText "P@ssword2" -Force) -passThru `
            -PasswordNeverExpires $false `
            -CannotChangePassword $false `
            -PasswordNotRequired $false `
            -ChangePasswordAtLogon $false `
            -Surname $csvObj.legallastname `
            -DisplayName $csvObj.displayname `
            -UserPrincipalName $csvObj.emailaddress1 `
            -EmailAddress $csvObj.emailaddress1 `
            -StreetAddress $csvObj.street `
            -City $csvObj.city `
            -State $csvObj.state `
            -PostalCode $csvObj.zipcode `
            -Title $csvObj.jobtitle `
            -Department $csvObj.department `
            -Company $csvObj.company `
            -Enabled $true `
            -Description $csvObj.jobtitle `
            -Path "ou=people,dc=company,dc=com"

        #$newuser = Get-ADUser -Filter "UserPrincipalName -eq '$($csvobj.upn)'" -Properties *

        #IF($csvObj.manager){ Set-ADUser -Identity $newuser.DistinguishedName -Credential $cred -Manager $csvObj.manager }

        #IF($csvObj.workphone){Set-ADUser -Identity $newuser.DistinguishedName -Credential $cred -OfficePhone $csvObj.workphone}

        #IF($csvObj.mobilephone){Set-ADUser -Identity $newuser.DistinguishedName -Credential $cred -MobilePhone $csvObj.mobilephone}

    }
}