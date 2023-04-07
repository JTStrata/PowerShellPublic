$users = get-msoluser | select userprincipalname, licenses
$displan = (Get-MsolUser -UserPrincipalName rmartin@weirsbuickgmc.com | select licenseassignmentdetails, userprincipalname).licenseassignmentdetails.assignments.disabledserviceplans

$dplan = @("POWER_VIRTUAL_AGENTS_O365_P2", "CDS_O365_P2", "PROJECT_O365_P2", "DYN365_CDS_O365_P2", "WHITEBOARD_PLAN1", "MYANALYTICS_P2", "DYN365BC_MS_INVOICING", "KAIZALA_O365_P2", "STREAM_O365_SMB", "Deskless", "BPOS_S_TODO_1", "MICROSOFTBOOKINGS", "FORMS_PLAN_E1", "FLOW_O365_P1", "POWERAPPS_O365_P1", "O365_SB_Relationship_Management", "PROJECTWORKMANAGEMENT", "SWAY", "YAMMER_ENTERPRISE", "COSTANDARD")

$new = $displan.split(" ")

foreach ($dis in $displan) {

    $blah += $dis | convert-fromstring
}

foreach ($user in $users) {

    $splans = (Get-MsolUser -UserPrincipalName sfarley@weirsbuickgmc.com | select licenseassignmentdetails, userprincipalname).licenseassignmentdetails.assignments.disabledserviceplans

    IF ($splans -notcontains "TEAMS1") { write-host "$user nah kid" }

}

$LO = New-MsolLicenseOptions -AccountSkuId "weirsMotorSales:O365_BUSINESS_PREMIUM" -DisabledPlans $dplan

Set-MsolUserLicense -UserPrincipalName sfarley@weirsbuickgmc.com -LicenseOptions $lo

$lu | Export-Csv c:\temp\lic.csv
$balls = Import-Csv C:\temp\lic.csv
