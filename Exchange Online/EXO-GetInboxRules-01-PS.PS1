$report = @()
$rules = @()

$mbs = Get-Mailbox -Filter 'ismailboxenabled -eq $true' -ResultSize unlimited | Select-Object name, userprincipalname, alias

foreach ($mb in $mbs) {
    Clear-Variable RulesCount
    Clear-Variable Rules

    $mb.UserPrincipalName
    $rules = Get-InboxRule -Mailbox $mb.userprincipalname | Select-Object enabled, name, description, deletemessage, forwardto, markasread, movetofolder, redirectto, forwardasattachment
    $rulescount = $rules.count
    
    IF ($rules.count -lt 1) {

        $rulescount = "No Rules Found"
        write-host "no rules found for $($mb.UserPrincipalName)" -ForegroundColor Yellow

        $object = New-Object -type PSOBject
        $object | Add-Member -MemberType NoteProperty -Name "Mailbox" -Value $mb.UserPrincipalName -Force
        $object | Add-Member -MemberType NoteProperty -Name "Rulescount" -Value $rulescount -Force
        $object | Add-Member -MemberType NoteProperty -Name "State" -Value " " -Force
        $object | Add-Member -MemberType NoteProperty -Name "Name" -Value " " -Force
        $object | Add-Member -MemberType NoteProperty -Name "Description" -Value " " -Force 
        $object | Add-Member -MemberType NoteProperty -Name "Delete" -Value " " -Force
        $object | Add-Member -MemberType NoteProperty -Name "Forward" -Value " " -Force
        $object | Add-Member -MemberType NoteProperty -Name "MarkRead" -Value " " -Force
        $object | Add-Member -MemberType NoteProperty -Name "Redirect To" -Value $r.redirectto -Force
        $object | Add-Member -MemberType NoteProperty -Name "Forward As Attachment" -Value $r.forwardasattachment -Force
        $object | Add-Member -MemberType NoteProperty -Name "Move" -Value " " -Force
        
        $report += $object
        
    }
    else { $rulescount = $rules.count }
    
    IF ($rules.count -ge 1) {
        
        foreach ($r in $rules) {

            $object = New-Object -type PSOBject
            $object | Add-Member -MemberType NoteProperty -Name "Mailbox" -Value $mb.UserPrincipalName -force
            $object | Add-Member -MemberType NoteProperty -Name "Rules Count" -Value $rulescount -Force
            $object | Add-Member -MemberType NoteProperty -Name "State" -Value $r.enabled -Force
            $object | Add-Member -MemberType NoteProperty -Name "Name" -Value $r.name -Force
            $object | Add-Member -MemberType NoteProperty -Name "Description" -Value $r.description -Force 
            $object | Add-Member -MemberType NoteProperty -Name "Delete" -Value $r.deletemessage -Force
            $object | Add-Member -MemberType NoteProperty -Name "Forward" -Value $r.forwardto -Force
            $object | Add-Member -MemberType NoteProperty -Name "MarkRead" -Value $r.MarkAsRead -Force
            $object | Add-Member -MemberType NoteProperty -Name "Redirect To" -Value $r.redirectto -Force
            $object | Add-Member -MemberType NoteProperty -Name "Forward As Attachment" -Value $r.forwardasattachment -Force
            $object | Add-Member -MemberType NoteProperty -Name "Move" -Value $r.MoveToFolder -Force

            $report += $object
        }
    

    }


}

$report | Format-Table