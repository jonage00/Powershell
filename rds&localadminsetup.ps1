try{

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
    Restart-Service TermService -Force
    #This enables remote desktop and restarts the service. 
    $localAdminUserList = Import-Csv c:\temp\remoteaccessusers.csv
    $localAdminUserList | ForEach-Object {
        $user = $_.user
        Add-LocalGroupMember -Group "Remote Desktop Users" -Member $user
        Add-LocalGroupMember -Group "Administrators" -Member $user
    }
    #This adds each user in the cvs to the local Administrators and Remote Desktop Users group. 
    Write-Host "Script completed successfully." -ForegroundColor Green
    }
    
catch {
    Write-Host "An error occured: $($_.Exception.Message)" -ForegroundColor Red

    #Throws and error if it fails.
}