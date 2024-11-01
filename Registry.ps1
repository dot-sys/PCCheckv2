# Checking Script
# For safe and local quick-dumping of System logs and files
#
# Author:
# Created by dot-sys under GPL-3.0 license
# This script is not related to any external Project.
#
# Usage:
# Use with Powershell 5.1 and NET 4.0 or higher.
# Running PC Checking Programs, including this script, outside of PC Checks may have impact on the outcome.
# It is advised not to use this on your own.
#
# Version 2.0
# 01 - Novermber - 2024

$ErrorActionPreference = "SilentlyContinue" 
$dmppath = "C:\Temp\Dump"
$registryPath = "$dmppath\Registry"
$rawFolder = "$registryPath\Raw"
$shimcachepath = "C:\Temp\Dump\Shimcache"

C:\Temp\Dump\RECmd\RECmd.exe -d "C:\windows\system32\config\" --csv C:\temp\dump\registry --details TRUE --bn C:\Temp\Dump\RECmd\batchexamples\kroll_batch.reb

if (-not (Test-Path -Path $rawFolder)) {
    New-Item -ItemType Directory -Path $rawFolder
}

Get-ChildItem -Path $registryPath -Filter "*.csv" | Move-Item -Destination $rawFolder

$directories = Get-ChildItem -Path $registryPath -Directory | Where-Object { $_.Name -ne "Raw" }

foreach ($directory in $directories) {
    Get-ChildItem -Path $directory.FullName | Move-Item -Destination $registryPath
}

foreach ($directory in $directories) {
    Remove-Item -Path $directory.FullName -Recurse
}

$regRenames = Get-ChildItem -Path "$dmppath\Registry" -Filter "*.csv" -Recurse
foreach ($file in $regRenames) {
    $newName = $file.Name -replace '^\d+_', ''
    if ($file.Name -ne $newName) {
        Rename-Item -Path $file.FullName -NewName $newName
    }
}

$keywords = @('AppPaths', 'DeviceClasses', 'KnownNetworks', 'NetworkAdapters', 'NetworkSetup', 'Products', 'Profilelist', 'SAMBuiltin', 'SCSI', 'UserAccounts')
Get-ChildItem -Path $registryPath -File | Where-Object { 
    $fileName = $_.Name
    $keywords | ForEach-Object { 
        if ($fileName -like "*$_*") { return $true }
    }
} | Remove-Item

Import-Csv "$registryPath\Uninstall_SOFTWARE.csv" | 
    Select-Object Timestamp, KeyName, DisplayName, Publisher, InstallDate, InstallSource, InstallLocation | 
    Export-Csv "$registryPath\Uninstall.csv" -NoTypeInformation

Import-Csv "$registryPath\USB_System.csv" | 
    Select-Object Timestamp, DeviceName, SerialNumber, KeyName, Service | 
    Export-Csv "$registryPath\USB_System.csv" -NoTypeInformation

Import-Csv "$registryPath\BamDam_System.csv" | 
    Select-Object ExecutionTime, Program | 
    Export-Csv "$registryPath\BamDam.csv" -NoTypeInformation

Import-Csv "$registryPath\RADAR_SOFTWARE.csv" | 
    Select-Object LastDetectionTime, Filename | 
    Export-Csv "$registryPath\RADAR.csv" -NoTypeInformation

Import-Csv "$registryPath\MountedDevices_System.csv" | 
    Select-Object DeviceName, DeviceData | 
    Export-Csv "$registryPath\MountedDevices.csv" -NoTypeInformation

Import-Csv "$registryPath\FirewallRules_SYSTEM.csv" | 
    Select-Object App, Dir, Active, Action | 
    Export-Csv "$registryPath\FirewallRules.csv" -NoTypeInformation

Import-Csv "$registryPath\ETW_SYSTEM.csv" | 
    Select-Object LastWriteTimestamp, Provider, GUID | 
    Export-Csv "$registryPath\ETW.csv" -NoTypeInformation

C:\temp\dump\AppCompatCacheParser.exe -t --csv C:\temp\dump\shimcache --csvf Shimcache.csv
$shimtemp = "$shimcachepath\Shimcache_temp.csv"
Import-Csv "$shimcachepath\Shimcache.csv" | Where-Object { -not ($_.Path -match '^[0-9]') } | Select-Object LastModifiedTimeUTC, Path, Executed | Sort-Object LastModifiedTimeUTC -Descending -Unique | Export-Csv $shimtemp -NoTypeInformation
Move-Item -Path $shimtemp -Destination "$shimcachepath\Shimcache.csv" -Force

C:\Temp\Dump\SBECmd.exe -d "$env:LocalAppData\Microsoft\Windows" --csv C:\temp\dump\Shellbags | Out-Null
$userclasstemp = Get-Item "C:\temp\dump\shellbags\*usrclass.csv"
$shellbagsRaw = Import-Csv $userclasstemp.FullName
$shellbagsDrive = ($shellbagsRaw | Where-Object { $_.ShellType -like "*Drive*" } | Select-Object -Unique ShellType, Value | ForEach-Object { "$($_.ShellType): $($_.Value)" }) -join "`r`n"
$shellbagsDir = ($shellbagsRaw | Where-Object { $_.ShellType -eq "Directory" } | Select-Object -Unique AbsolutePath | ForEach-Object { "$($_.AbsolutePath)" }) -join "`r`n"
$driveResults = "Drives found in Shellbags`n-------------------------`n$shellbagsDrive"
$dirResults = "Directories found in Shellbags`n------------------------------`n$shellbagsDir"
$driveResults + "`r`n`r`n" + $dirResults | Out-File "C:\temp\dump\shellbags\Shellbags_Result.txt"
$userclasstemp = Get-Item "C:\temp\dump\shellbags\*usrclass.csv"
$shellbagImport = Import-Csv $userclasstemp.FullName
$shellbagImport | Select-Object LastWriteTime, AbsolutePath, CreatedOn, ModifiedOn, AccessedOn | Sort-Object LastWriteTime -Descending | Export-Csv "C:\temp\dump\shellbags\Shellbags.csv" -NoTypeInformation
Remove-Item "C:\temp\dump\shellbags\*usrclass.csv" -Force
Get-ChildItem "C:\temp\dump\Shellbags\*SBECmd*" | Remove-Item
Get-ChildItem "C:\Temp\Dump\Registry" | Where-Object { $_.Name -like "*_*" } | Remove-Item -Force

$bamimp = Import-Csv -Path "C:\temp\dump\Registry\BamDam.csv"
$bamfiltered = $bamimp | Where-Object { $_.Program -like '*\Device\HarddiskVolume*' }
$bamfiltered | ForEach-Object { 
    $_.ExecutionTime = $_.ExecutionTime.Substring(0, [math]::Min(19, $_.ExecutionTime.Length))
    $_ 
} | Sort-Object -Property ExecutionTime -Descending | Export-Csv -Path "C:\temp\dump\Registry\Bam_Overview.csv" -NoTypeInformation

Rename-Item "C:\temp\dump\Registry\BamDam.csv" "C:\temp\dump\Registry\Bam.csv"
