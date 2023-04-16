# Import ActiveDirectory module if not loaded
if (-not (Get-Module -Name ActiveDirectory)) {
    Import-Module ActiveDirectory
}

# Function to check if a user is a member of a specific group
function IsMemberOfGroup ($User, $Group) {
    $Groups = Get-ADPrincipalGroupMembership -Identity $User | Select-Object -ExpandProperty Name
    return $Groups -contains $Group
}

# Function to export data to a CSV file
function ExportToCSV ($Data, $ReportName) {
    $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveFileDialog.Filter = "CSV files (*.csv)|*.csv"
    $SaveFileDialog.Title = "Save $ReportName report as"
    $SaveFileDialog.FileName = "$ReportName.csv"
    $Result = $SaveFileDialog.ShowDialog()
    if ($Result -eq "OK") {
        $Data | Export-Csv -Path $SaveFileDialog.FileName -NoTypeInformation -Encoding UTF8
        Write-Host "Report saved to $($SaveFileDialog.FileName)" -ForegroundColor Green
    }
}

function PullUsersReport {
    # Pull users report
    $UserReport = Get-ADUser -Filter * -Properties Name, Description, CanonicalName, Enabled, LastLogonDate | 
    Select-Object Name, Description, CanonicalName, Enabled, LastLogonDate,
    @{Name = "Stale User"; Expression = { ($_.Enabled -eq $true) -and ($_.LastLogonDate -lt (Get-Date).AddDays(-90)) } } |
    Sort-Object -Property CanonicalName
    ExportToCSV -Data $UserReport -ReportName "UsersReport"
}

function PullComputersReport {
    # Computers Report
    $ComputerReport = Get-ADComputer -Filter * -Properties Name, Description, CanonicalName, OperatingSystem, Enabled, LastLogonDate |
    Select-Object Name, Description, CanonicalName, OperatingSystem, Enabled, LastLogonDate,
    @{Name = "Stale Computer"; Expression = { ($_.Enabled -eq $true) -and ($_.LastLogonDate -lt (Get-Date).AddDays(-90)) } } |
    Sort-Object -Property CanonicalName
    ExportToCSV -Data $ComputerReport -ReportName "ComputersReport"
}

function PullGroupsReport {
    # Groups Report
    $GroupReport = Get-ADGroup -Filter * -Properties Name, Description, CanonicalName, Members |
    Select-Object Name, Description, CanonicalName,
    @{Name = "Stale Group"; Expression = { ($_.Members.Count -eq 0) -and (-not $_.Name.StartsWith("BUILTIN")) } } |
    Sort-Object -Property CanonicalName
    ExportToCSV -Data $GroupReport -ReportName "GroupsReport"
}

function PullOUReport {
    # OU Report
    $OUs = Get-ADOrganizationalUnit -Filter * -Properties Name, Description, CanonicalName, DistinguishedName, ProtectedFromAccidentalDeletion | Select-Object Name, Description, CanonicalName, DistinguishedName, ProtectedFromAccidentalDeletion | Sort-Object -Property CanonicalName 
    $OUReport = Foreach ($OU in $OUs) {
        $ObjectCount = (Get-ADObject -Filter "memberOf -eq '$($OU.DistinguishedName)'" -SearchBase $ou.DistinguishedName -SearchScope OneLevel).Count 

        [PSCustomObject]@{
            Name                            = $OU.name
            Description                     = $OU.Description
            CanonicalName                   = $OU.CanonicalName         
            DistinguishedName               = $OU.DistinguishedName
            ObjectCount                     = $ObjectCount
            ProtectedFromAccidentalDeletion = $ou.ProtectedFromAccidentalDeletion
        }
    }

    ExportToCSV -Data $OUReport -ReportName "OUReport"
}

function PullAdministrativeAccountsReport {
    # Administrative Accounts Report
    $AdminReport = Get-ADUser -Filter 'adminCount -eq 1' -Properties Name, Description, CanonicalName, Enabled, LastLogonDate, MemberOf |
    Select-Object Name, Description, CanonicalName, Enabled, LastLogonDate,
    @{Name = "Domain Admins"; Expression = { ($_.memberOf -match "Domain Admins") } },
    @{Name = "Schema Admins"; Expression = { ($_.memberOf -match "Schema Admins") } },
    @{Name = "Administrators"; Expression = { ($_.memberOf -match "Administrators") } },
    @{Name = "Enterprise Admins"; Expression = { ($_.memberOf -match "Enterprise Admins") } } |
    Sort-Object -Property CanonicalName
    ExportToCSV -Data $AdminReport -ReportName "AdministrativeAccountsReport"
}

function PullDomainsReport {
    # OPTION 7
    # Domains report
    # TODO: Implement the functionality to retrieve the DFSR migration state, the date the KRBTGT account password was set
    $Domains = Get-ADDomain | Select-Object Name, netbiosname, parentdomain, childdomain, computerscontainer, userscontainer, systemscontainer, alloweddnssuffixes, DomainMode, PDCEmulator, RIDMaster, InfrastructureMaster
    $Forest = Get-ADForest
    $ForestMode = $Forest.ForestMode
    $Trusts = Get-ADTrust -filter * | Select-Object Name, Direction, forestTransitive
    
    $DomainReport = $Domains | ForEach-Object {
        $DomainName = $_.Name
        if ($_.childdomain.count -lt 1) { $ChildDomains = "No Child Domains Found" }
        if ($_.parentdomain.count -lt 1) { $ParentDomain = "No Parent Domains Found" }


        [PSCustomObject]@{
            Name                 = $DomainName
            DomainMode           = $_.DomainMode
            ForestMode           = $ForestMode         
            NetBIOSName          = $_.netbiosname
            ParentDomain         = $parentdomain
            ChildDomain          = $childdomains
            UsersCN              = $_.userscontainer
            SystemCN             = $_.systemscontainer
            ComputersCN          = $_.computerscontainer
            AllowedDNS           = $_.allowedDNSSuffixes
            InboundTrustsOnly    = ($trusts | Where-Object { $_.direction -eq "inbound" } | Select-Object name).name
            OutboundTrustsOnly   = ($trusts | Where-Object { $_.direction -eq "outbound" } | Select-Object name).name
            BiDirectionalTrusts  = ($trusts | Where-Object { $_.direction -eq "bidirectional" } | Select-Object name).name
            PDCEmulator          = $_.PDCEmulator
            RIDMaster            = $_.RIDMaster
            InfrastructureMaster = $_.InfrastructureMaster
            SchemaMaster         = $forest.SchemaMaster
            DomainNamingMaster   = $forest.DomainNamingMaster

        }
    } | Sort-Object -Property Name

    ExportToCSV -Data $DomainReport -ReportName "DomainsReport"
}

function PullDomainControllersReport {
    # OPTION 8 
    # Domain controllers report
    # TODO: Implement the functionality to retrieve the last date DSRM password was set
    $DCs = Get-ADDomainController -filter * | Select-Object Hostname, ComputerObjectDN, IPV4Address, IPV6Address, IsGlobalCatalog, IsReadOnly, OperatingSystem, Site, sslport
    function Test-TcpConnection {
        param (
            [string]$ComputerName,
            [int]$Port,
            [int]$TimeoutMilliseconds
        )
    
        $client = New-Object System.Net.Sockets.TcpClient
        $cancellationTokenSource = New-Object System.Threading.CancellationTokenSource
        $cancellationToken = $cancellationTokenSource.Token
        $cancellationTokenSource.CancelAfter($TimeoutMilliseconds)
    
        try {
            $connectTask = $client.ConnectAsync($ComputerName, $Port)
            $connectTask.Wait($TimeoutMilliseconds, $cancellationToken)
            #return $connectTask.IsCompleted
        }
        catch {
            return $false
        }
        finally {
            $client.Close()
            $cancellationTokenSource.Dispose()
        }
    }
    
    $TimeoutMilliseconds = 2000
    
    $DCReport = foreach ($dc in $dcs) { 
        $Avail = Test-TcpConnection -ComputerName $dc.hostname -Port 389 -TimeoutMilliseconds $TimeoutMilliseconds
        if ($avail -eq $true) {
            $DCHostname = $DC.hostname
            $InstalledRoles = Get-WindowsFeature -computername $dc.hostname | Where-Object { ($_.installstate -eq 'installed') -and ($_.name -notlike "*RSAT*") -and ($_.name -notlike "*powershell*") -and ($_.name -notlike "*NET*") -and ($_.name -notlike "*XPS*") -and ($_.name -notlike "*wow*") -and ($_.name -notlike "*defender*") -and ($_.name -notlike "*bitlocker*") -and ($_.name -notlike "*dataarchiver*") }
            $InstalledRolesString = ($InstalledRoles.Name -join ', ')
        }
        else {
            $DCHostname = "$($DC.hostname) was not found to be active."
            Write-Host "DC $($DC.hostname)" is not reachable -ForegroundColor Red -BackgroundColor Black 
        }
        [PSCustomObject]@{
            DCName          = $DCHostname
            Location        = $DC.ComputerObjectDN
            IPV4Address     = $DC.IPV4Address
            IPV6Address     = $DC.IPV6Address         
            GlobalCatalog   = $DC.IsGlobalCatalog
            ReadOnly        = $DC.IsReadOnly
            OperatingSystem = $DC.OperatingSystem
            ADSite          = $DC.Site
            SSLPort         = $DC.sslport
            InstalledRoles  = $InstalledRolesString
        }
    
    }
 ExportToCSV -Data $DCReport -ReportName "DomainControllersReport"
}
function ShowMenu {
    Clear-Host
    Write-Host "Active Directory Reports"
    Write-Host "========================="
    Write-Host "1. Pull all reports"
    Write-Host "2. Pull users report"
    Write-Host "3. Computers report"
    Write-Host "4. Groups report"
    Write-Host "5. OU report"
    Write-Host "6. Administrative accounts report"
    Write-Host "7. Domains report"
    Write-Host "8. Domain controllers report"
    Write-Host "`nPress 'q' to quit."

    $input = Read-Host "Please choose an option (1-8)"
    return $input
}

while ($true) {
    $choice = ShowMenu

    if ($choice -eq "q") {
        break
    }
    switch ($choice) {
        "1" {
            PullUsersReport
            PullComputersReport
            PullGroupsReport
            PullOUReport
            PullAdministrativeAccountsReport
            PullDomainsReport
            PullDomainControllersReport
            break
        }
        "2" { PullUsersReport }
        "3" { PullComputersReport }
        "4" { PullGroupsReport }
        "5" { PullOUReport }
        "6" { PullAdministrativeAccountsReport }
        "7" { PullDomainsReport }
        "8" { PullDomainControllersReport }
        default {
            Write-Host "Invalid option. Please choose a valid number (1-8) or 'q' to quit." -ForegroundColor Red
        }
        
    }
}


