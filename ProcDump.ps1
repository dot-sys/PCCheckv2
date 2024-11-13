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
# Version 2.1
# 13 - November - 2024

$ErrorActionPreference = "SilentlyContinue" 
$dmppath = "C:\Temp\Dump"
$procpath = "C:\Temp\Dump\Processes"
$procpathraw = "C:\Temp\Dump\Processes\Raw"
$procpathfilt = "C:\Temp\Dump\Processes\Filtered"

function Get-ProcessID {
    param(
        [string]$ServiceName
    )
    $processID = (Get-CimInstance -Query "SELECT ProcessId FROM Win32_Service WHERE Name='$ServiceName'").ProcessId
    return $processID
}
$processList1 = @{
    "DPS"       = Get-ProcessID -ServiceName "DPS"
    "DiagTrack" = Get-ProcessID -ServiceName "DiagTrack"
    "PcaSvc"   = Get-ProcessID -ServiceName "PcaSvc"
    "explorer" = (Get-Process explorer).Id
}
$processList2 = @{
    "dusmsvc"  = Get-ProcessID -ServiceName "Dnscache"
    "eventlog" = Get-ProcessID -ServiceName "Eventlog"
    "WSearch"   = Get-ProcessID -ServiceName "WSearch"
    "dwm"      = (Get-Process dwm).Id
    "sysmain"  = Get-ProcessID -ServiceName "Sysmain"
    "dnscache" = Get-ProcessID -ServiceName "Dnscache"
    "lsass"    = (Get-Process lsass).Id
    "AggregatorHost"    = (Get-Process AggregatorHost).Id
}
$processList = $processList1 + $processList2

$uptime = foreach ($entry in $processList.GetEnumerator()) {
    $service = $entry.Key
    $pidVal = $entry.Value

    if ($pidVal -eq 0) {
        [PSCustomObject]@{ Service = $service; Uptime = 'Stopped' }
    }
    elseif ($null -ne $pidVal) {
        $process = Get-Process -Id $pidVal -ErrorAction SilentlyContinue
        if ($process) {
            $uptime = (Get-Date) - $process.StartTime
            $uptimeFormatted = '{0} days, {1:D2}:{2:D2}:{3:D2}' -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds
            [PSCustomObject]@{ Service = $service; Uptime = $uptimeFormatted }
        }
        else {
            [PSCustomObject]@{ Service = $service; Uptime = 'Stopped' }
        }
    }
    else {
        [PSCustomObject]@{ Service = $service; Uptime = 'Stopped' }
    }
}

$sUptime = $uptime | Sort-Object Service | Format-Table -AutoSize -HideTableHeaders | Out-String

foreach ($entry in $processList1.GetEnumerator()) {
    $service = $entry.Key
    $pidVal = $entry.Value
    if ($null -ne $pidVal) {
        & "$dmppath\strings2.exe" -a -l 5 -pid $pidVal | Select-String -Pattern "\.exe|\.bat|\.ps1|\.rar|\.zip|\.7z|\.dll" | Set-Content -Path "$procpathraw\$service.txt" -Encoding UTF8
    }
}

Set-Location "$procpathraw"
$dll = Get-Content explorer.txt | Where-Object { $_ -match "^[A-Za-z]:\\.*\.dll$" }
$dll | Sort-Object -Unique -Descending | Out-File "$procpath\DLL.txt"

$DPSString = "$Astra|$Hydro|$Leet|$Skript"
$dps1 = (Get-Content dps.txt | Where-Object { $_ -match '\.exe' -and $_ -match '!0!' } | Sort-Object) -join "`n"
$predps2 = Get-Content dps.txt | Where-Object { $_ -match '!!.*2024' } | Sort-Object
$dps2grouped = ($predps2 | ForEach-Object { $_ -replace '!!(.+?)!.*', '$1' } | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Group } | Select-Object -Unique)
$dps2 = $predps2 | Where-Object { $_ -match ('!!' + ($dps2grouped -join '|') + '!') }
$dps2 = $dps2 -join "`n"
$dps3 = (Get-Content dps.txt | Where-Object { $_ -match '!!.*2024' } | Sort-Object) -join "`n"
$dps4 = (Get-Content dps.txt | Where-Object { $_ -match '!!' -and $_ -match 'exe' } | Sort-Object -Unique) -join "`n"
$dps4 | Where-Object { $_ -match $DPSString } | Add-Content -Path "DPS_Cheat.txt"
$dps = "DPS Null`n$dps1`n`nDPS Doubles`n$dps2`n`nDPS Dates`n$dps3`n`nDPS Executables`n$dps4"
$dps | Out-File "$procpath\DPS_Filtered.txt"

$fileSlash = Get-Content explorer.txt | Where-Object { $_ -match "file:///" } | ForEach-Object { $_ -replace "file:///", "" }
$fileSlash | Out-File "$procpath\Files_Visited.txt"

$hdv = Get-Content explorer.txt, diagtrack.txt | Where-Object { $_ -match "HarddiskVolume" } | ForEach-Object { if ($_ -match "HarddiskVolume(\d+)") { [PSCustomObject]@{ Line = $_; Number = $matches[1] } } } | Group-Object Number | Sort-Object Count | ForEach-Object { $_.Group.Line } | Select-Object -Unique
$hdv | Out-File "$procpath\Harddiskvolumes.txt"

$invis = Get-Content explorer.txt | Where-Object { $_ -match "[A-Z]:\\.*[^\x00-\x7F].*\.exe" }
$invis | Out-File "$procpath\Invisible_Chars.txt"

$modext1 = Get-Content dps.txt | Where-Object { $_ -match "^!![A-Z]((?!Exe).)*$" }
$modext2 = Get-Content diagtrack.txt | Where-Object { $_ -match "^\\device\\harddiskvolume((?!Exe|dll).)*$" }
$modext = "Possible Modification of Extensions in DPS$l4$modext1 `nPossible Modification of Extensions in Diagtrack$l4$modext2"
$modext | Out-File "$procpath\Modified_Extensions.txt"

$pca1 = Get-Content explorer.txt | Where-Object { $_ -match "pcaclient" } | ForEach-Object { if ($_ -match "[A-Z]:\\.*?\.exe") { $matches[0] } }
$pca1 | Sort-Object -Unique -Descending | Out-File "$procpath\PcaClient.txt"

$pca2 = Get-Content pcasvc.txt | Where-Object { $_ -match "TRACE," }
$pca2 | Sort-Object -Unique -Descending | Out-File "$procpathraw\Pca_Extended_Raw.txt"
$pca3 = $pca2 | ForEach-Object { if ($_ -match "[A-Z]:\\.*?\.exe") { $matches[0] } }
$pca3 | Sort-Object -Unique -Descending | Out-File "$procpath\Pca_Extended.txt"

$proccomp2 = Get-Content explorer.txt, pcasvc.txt, diagtrack.txt | Where-Object { $_ -match "^[a-zA-Z0-9_-]+\.(rar|zip|7z)$" }
$proccomp2 | Out-File "$procpath\Compressed_Processes.txt"

$procexes = Get-Content explorer.txt | Where-Object { $_ -match "^\b(?!C:)[A-Z]:\\.*" }
$procexes | Sort-Object -Unique -Descending | Out-File "$procpath\Drive_Executables.txt"

$procscripts = Get-Content explorer.txt | Where-Object { $_ -match "^[a-zA-Z0-9_-]+\.(bat|ps1)$" }
$procscripts | Sort-Object -Unique -Descending | Out-File "$procpath\Scripts.txt"

$tempComp = Get-Content explorer.txt | Where-Object { $_ -match "Local\\Temp.*\.exe" }
$tempComp | Sort-Object -Unique -Descending | Out-File "$procpath\Compressed_Temp.txt"

if (Test-Path "C:\windows\appcompat\pca\PcaAppLaunchDic.txt") { Copy-Item "C:\windows\appcompat\pca\PcaAppLaunchDic.txt" -Destination "C:\temp\dump\processes\raw" }
$pca4 = (Get-Content "C:\temp\dump\processes\raw\PcaAppLaunchDic.txt" | ForEach-Object { ($_ -replace '\|.*') } | Where-Object { $_ -match '^[A-Za-z]:\\' })
$pca4 | Out-File "$procpath\Pca_AppLauncher.txt"

$sUptime | Out-File C:\temp\dump\processes\Uptime.txt

Move-Item -Path "$procpath\*.txt" -Destination "$procpathfilt"

C:\temp\dump\hollows_hunter.exe /pname "Explorer.exe;GTA5.exe;AMDRSServ.exe;nvcontainer.exe;obs64.exe;Medal.exe;MedalEncoder.exe" /hooks /quiet /json /jlvl 2 | out-file c:\temp\dump\processes\hooks.json
Get-Content "c:\temp\dump\processes\hooks.json" | Out-File "c:\temp\dump\processes\Hooks.txt"
Remove-Item "c:\temp\dump\processes\hooks.json"
Remove-Item "c:\temp\dump\processes\raw\hollows_hunter.dumps" -Recurse
