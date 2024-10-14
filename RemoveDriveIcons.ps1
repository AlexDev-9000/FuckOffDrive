#first execution flag
$firstExec = $true


#checking if this specific reg has been altered by the gdrive process to act as a flag on wether or not we should edit the registry/restart gdrive
function checkRegistry {
    param ()
    $value = Get-ItemPropertyValue -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers\GoogleDriveCloudOverlayIconHandler' -Name '(Default)'
    return $value
}

function editRegistry {
    param ()

    Set-Itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers\GoogleDriveCloudOverlayIconHandler' -Name '(Default)' -value ''
    Set-Itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers\GoogleDriveMirrorBlacklistedOverlayIconHandler' -Name '(Default)' -value ''
    Set-Itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers\GoogleDrivePinnedOverlayIconHandler' -Name '(Default)' -value ''
    Set-Itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers\GoogleDriveProgressOverlayIconHandler' -Name '(Default)' -value ''
    Set-Itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers\    GoogleDriveCloudOverlayIconHandler' -Name '(Default)' -value ''
    Set-Itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers\    GoogleDriveMirrorBlacklistedOverlayIconHandler' -Name '(Default)' -value ''
    Set-Itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers\    GoogleDrivePinnedOverlayIconHandler' -Name '(Default)' -value ''
    Set-Itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers\    GoogleDriveProgressOverlayIconHandler' -Name '(Default)' -value ''
}

function restartDrive {
    param ($driveExec)

    #flag for the process that detects if gdrive has changed it's exec location mid execution
    $driveUpdated = $false
    $newDrivePath = ""

    #drive startup can be really slow, causing an exception when trying to close it
    try {
        Stop-Process -Name "GoogleDriveFS" -Force | Wait-Process -Name "GoogleDriveFS"

        #we only need to restart explorer on first execution for the desktop icons, the rest of the icons are drawn on folder opening
        if ($firstExec) {
            Stop-Process -Name "Explorer" -Force | Wait-Process -Name "Explorer"
            $firstExec = $false
        }
    }

    catch {
        Start-Sleep 1
        restartDrive
    }

    #error handling in case the location of the exec changes mid execution which happens if gdrive updates
    #flagging the error so as to perform a file search for the new path only once
    if ($driveUpdated -eq $false) {

        try {
            Start-Process -FilePath $driveExec[0].FullName
        }
        catch {
            $newDrivePath = getDriveExec
            Start-Process -FilePath $newDrivePath[0].FullName
            $driveUpdated = $true
        }

    } else {

        Start-Process -FilePath $newDrivePath[0].FullName
    }

    Start-Process -FilePath "C:\Windows\explorer.exe"
}

function getDriveExec {
    param ()
    #google changes the location of their exe periodically because they are schizos, searching it
    $driveExec = Get-ChildItem -Path C:\'Program Files'\Google\'Drive File Stream' -Include GoogleDriveFS.exe -Recurse;
    return $driveExec
}


function main {
    param ()

    $driveExec = getDriveExec

    while ($true) {
        #checking if registry hasn't been edited by the drive process so we don't needlessly restart it
        $regFlagValue = checkRegistry

        if ($regFlagValue -eq "") {
            Start-Sleep 60
            return

        } else {
            editRegistry
            restartDrive($driveExec)
            Start-Sleep 60
            return
        }

    }
}

main
#stop-process -Id $PID