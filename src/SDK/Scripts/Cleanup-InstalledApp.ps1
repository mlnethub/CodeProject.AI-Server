# This script is intended to clean up the Installed app to bring it back to a clean state
# that can be properly uninstalled, repaired or upgraded. Older versions of the Windows 
# Installer do not properly shut down the backend modules and a few other issues that can
# leave things in a mess.
#  - shutdown the CodeProject.AI Server
#  - kill any dangling module processes that may be hanging around
#  - remove modules that have been previously installed and are no longer part of the installer
#  - remove persisted module config data (modulesettings.json) in ProgramData/CodeProject/AI

# TODO: Rename to Cleanup-InstalledApp.ps1. It's more than just a hard stop, and is only for Windows

[cmdletbinding()]
param(
    [Switch]$RemoveDownloads,
    [Switch]$RemoveModules,
    [Switch]$RemoveConfigData,
    [Switch]$RemoveAll,
    [Switch]$KillModuleProcesses,
    [Switch]$Restart
)

# $cwd = Get-Location
# This script is now in /src/SDK/Scripts
$rootDir = Join-Path -Path $pwd -ChildPath "..\..\.."

if ($Debug)
{
    Write-Host "Stopping any dangling CodeProject.AI Server Modules..." -ForegroundColor DarkGreen
    Write-Host "This may take some time..." -ForegroundColor DarkGreen
    get-process | where {$_.CommandLine -Like "$rootDir\src\modules\*"} | kill
}
else
{
    Write-Host "Stopping the CodeProject.AI Server Windows Service..." -ForegroundColor DarkGreen
    stop-service "CodeProject.AI Server"
    Write-Host "Service Stopped" -ForegroundColor DarkGreen -BackgroundColor White

    if ($KillModuleProcesses -or $RemoveAll)
    {
        Write-Host "Stopping any dangling CodeProject.AI Server Modules..." -ForegroundColor DarkGreen
        Write-Host "This may take some time..." -ForegroundColor DarkGreen

        # Could add a -Force to the Kill, but I like having control.
        get-process | where {$_.CommandLine -Like "$rootDir\AI\modules\*"} | kill
    }

    if ($RemoveDownloads -or $RemoveAll)
    {
        Write-Host "Deleting CodeProject.AI Server downloads from $rootDir\AI\modules..." -ForegroundColor DarkGreen
        Remove-Item "$rootDir\AI\downloads\*" -Recurse
    }

    # REVIEWED: This is truly dangerous. This will remove modules that were downloaded from the
    # CodeProject.AI module registry, as well as any module a user uploaded themselves. I can't
    # see a use case for this, but I can see a disaster if this is called outside of a debug
    # scenario. There needs to be a "Are you sure?" safety catch in place
    # REVIEW: This script is not intended to by used lightly, only when it is necessary to clean-up
    # the installed app if it has gotten into an undesirable state. It is not run automatically during
    # the Install process.
    if ($RemoveModules -or $RemoveAll)
    {
        Write-Host "Deleting CodeProject.AI Server Modules from $rootDir\AI\modules..." -ForegroundColor DarkGreen
        Remove-Item "$rootDir\AI\modules\*" -Recurse
    }

    if ($removeconfigdata -or $removeall)
    {
        write-host "deleting codeproject.ai server config data..." -foregroundcolor darkgreen
        remove-item "c:\programdata\codeproject\ai\modulesettings.json"
    }

    if ($Restart)
    {
        Write-Host "Starting the CodeProject.AI Server Windows Service..." -ForegroundColor DarkGreen
        start-service "CodeProject.AI Server"
        Write-Host "Service Started" -ForegroundColor DarkGreen -BackgroundColor White
    }
}

