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
# 06 - December - 2024

$ErrorActionPreference = "SilentlyContinue" 
$SRUMPath = "C:\temp\dump\SRUM"
$AMCachePath = "C:\temp\dump\AMCache"
$outputFile = "C:\Temp\Dump\Detections.txt"
New-Item -Path "$SRUMPath\Raw" -ItemType Directory -Force | Out-Null
New-Item -Path "$AMCachePath\Raw" -ItemType Directory -Force | Out-Null
Set-Location $SRUMPath

# Harddiskvolume-Replacement Script by phuclv on superuser.com
$signature = @'
[DllImport("kernel32.dll", SetLastError=true)]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool GetVolumePathNamesForVolumeNameW([MarshalAs(UnmanagedType.LPWStr)] string lpszVolumeName,
        [MarshalAs(UnmanagedType.LPWStr)] [Out] StringBuilder lpszVolumeNamePaths, uint cchBuferLength, 
        ref UInt32 lpcchReturnLength);

[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr FindFirstVolume([Out] StringBuilder lpszVolumeName,
   uint cchBufferLength);

[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool FindNextVolume(IntPtr hFindVolume, [Out] StringBuilder lpszVolumeName, uint cchBufferLength);

[DllImport("kernel32.dll", SetLastError = true)]
public static extern uint QueryDosDevice(string lpDeviceName, StringBuilder lpTargetPath, int ucchMax);
'@;
Add-Type -MemberDefinition $signature -Name Win32Utils -Namespace PInvoke -Using PInvoke,System.Text;

[UInt32] $lpcchReturnLength = 0;
[UInt32] $Max = 65535
$sbVolumeName = New-Object System.Text.StringBuilder($Max, $Max)
$sbPathName = New-Object System.Text.StringBuilder($Max, $Max)
$sbMountPoint = New-Object System.Text.StringBuilder($Max, $Max)
[IntPtr] $volumeHandle = [PInvoke.Win32Utils]::FindFirstVolume($sbVolumeName, $Max)

$volumeMappings = @{}

do {
    $volume = $sbVolumeName.ToString()
    $unused = [PInvoke.Win32Utils]::GetVolumePathNamesForVolumeNameW($volume, $sbMountPoint, $Max, [Ref] $lpcchReturnLength)
    $ReturnLength = [PInvoke.Win32Utils]::QueryDosDevice($volume.Substring(4, $volume.Length - 1 - 4), $sbPathName, [UInt32] $Max)

    if ($ReturnLength) {
        $DriveLetter = $sbMountPoint.ToString()
        $DevicePath = $sbPathName.ToString()
        
        $volumeMappings[$DevicePath] = $DriveLetter
    }

} while ([PInvoke.Win32Utils]::FindNextVolume([IntPtr] $volumeHandle, $sbVolumeName, $Max))

$unused | Out-Null

C:\temp\dump\SrumECmd.exe -f "C:\Windows\System32\sru\SRUDB.dat" --csv "$SRUMPath\"

Remove-Item "$SRUMPath\SrumECmd.*" -r -force
Remove-Item "$SRUMPath\*_SrumECmd_EnergyUsage_Output.csv" -force
Remove-Item "$SRUMPath\*_SrumECmd_NetworkConnections_Output.csv" -force
Remove-Item "$SRUMPath\*_SrumECmd_PushNotifications_Output.csv" -force
Remove-Item "$SRUMPath\*_SrumECmd_vfuprov_Output.csv" -force
Get-ChildItem "$SRUMPath" | 
	Rename-Item -NewName { 
		$_.Name -replace '^[\d]+_SrumECmd_', '' 
	} -Force

$SrumImp = Import-Csv -Path "$SRUMPath\*AppResourceUseInfo_Output.csv" 

$SrumImp = $SrumImp |
Where-Object { 
    $_.SidType -eq 'UnknownOrUserSid' -and 
    $_.Sid -match 'S-1-5-21' -and 
    $_.'ExeInfo' -match '\.exe$' 
} |
Group-Object -Property 'ExeInfo' |
ForEach-Object { $_.Group | Sort-Object 'Timestamp' -Descending | Select-Object -First 1 } |
Select-Object -Property 'Timestamp', 'ExeInfo', 'ForegroundBytesRead', 'ForegroundBytesWritten' |
Sort-Object 'Timestamp' -Descending

foreach ($entry in $SrumImp) {
    foreach ($devicePath in $volumeMappings.Keys) {
        if ($entry.ExeInfo -like "*$devicePath*") {
            $entry.ExeInfo = $entry.ExeInfo -replace [regex]::Escape($devicePath), $volumeMappings[$devicePath]
            $entry.ExeInfo = $entry.ExeInfo.Replace('\\', '\')
            $entry.ExeInfo = $entry.ExeInfo.Replace('/', '\') 
        }
    }
}

$SrumImp | Export-Csv -Path "$SRUMPath\SRUM.csv" -NoTypeInformation -Encoding utf8
Add-Content -Path "C:\Windows\System32\info.txt" -Value (Get-Date).ToString("dd MMMM yyyy")

$SrumImp | 
Where-Object { $_.ExeInfo -match "Zip\$|ziptemp|Rar\$|rartemp" } | 
Select-Object -Property 'Timestamp', 'ExeInfo', 'ForegroundBytesRead', 'ForegroundBytesWritten' | 
Sort-Object 'Timestamp' -Descending |
Export-Csv -Path "$SRUMPath\Compressed.csv" -NoT
ypeInformation

Get-ChildItem -Path "C:\Temp\Dump\SRUM" -Filter "*_Output*" | Move-Item -Destination "C:\Temp\Dump\SRUM\Raw"

Set-Location $AMCachePath

C:\temp\dump\AMCacheParser.exe -f "C:\Windows\AppCompat\Programs\Amcache.hve" --csv "C:\temp\dump\amcache"

Get-ChildItem "$AMCachePath" | Rename-Item -NewName { $_.Name -replace '^[\d]+_Amcache_', '' } -Force

$inputFile1 = Get-ChildItem 'C:\temp\dump\AMCache' -Filter '*UnassociatedFileEntries.csv' | Select-Object -First 1
$inputFile2 = Get-ChildItem 'C:\temp\dump\AMCache' -Filter '*DevicePnps.csv' | Select-Object -First 1

Import-Csv $inputFile1.FullName |
Where-Object {
    $_.IsOsComponent -eq 'FALSE'
} |
Select-Object @{Name='LastWriteTime'; Expression={$_.FileKeyLastWriteTimestamp}}, 
              FullPath, 
              Size, 
              FileExtension, 
              SHA1 |
Sort-Object -Property LastWriteTime -Descending |
Export-Csv 'C:\temp\dump\AMCache\AmCache.csv' -NoTypeInformation

Import-Csv $inputFile2.FullName |
Where-Object {
    (($_.Class -match '^(USB|Volume)$' -and $_.Enumerator -match '^(Storage|USB)$') -or 
    $_.Description -like '*Mass Storage*' -or 
    $_.ParentID -like '*Storage*') -and
    $_.Manufacturer -notlike '*Standard*' -and 
    $_.Manufacturer -notlike '*Microsoft*'
} |
Select-Object @{Name='LastWriteTime'; Expression={$_.KeyLastWriteTimestamp}}, 
              @{Name='USBName'; Expression={$_.KeyName}}, 
              Description, 
              Manufacturer |
Sort-Object -Property LastWriteTime -Descending |
Export-Csv 'C:\temp\dump\AMCache\USB.csv' -NoTypeInformation


Remove-Item "$AMCachePath\*.exe" -force
Remove-Item "$AMCachePath\*.zip" -force
Get-ChildItem -Path $AMCachePath -File | Where-Object { $_.Name -notmatch '^AMCache|USB' } | Move-Item -Destination 'C:\temp\dump\AMCache\Raw'

C:\temp\dump\PECmd.exe -d "C:\Windows\Prefetch" --csv "C:\temp\dump\Prefetch" --csvf "Prefetch.csv"

function Headers {
    param (
        [string]$header,
        [string[]]$data
    )
    
    if ($data.Count -gt 0) {
        Add-Content -Path $outputFile -Value "`r`n$header"
        Add-Content -Path $outputFile -Value "-------------------------------------------"
        $data | ForEach-Object { Add-Content -Path $outputFile -Value $_ }
    }
}

function ProgStats {
    param (
        [string]$serviceName,
        [string]$programName
    )
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($null -eq $service) {
        return "$programName is not installed"
    } elseif ($service.Status -eq 'Running') {
        return "$programName is running"
    } else {
        return "$programName is turned off"
    }
}

$status = ProgStats "WinDefend" "Windows Defender"
if ($status -eq "Windows Defender is not installed") {
    Add-Content -Path $outputFile -Value "`r`n$status"
} else {
    $realTimeProtection = Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring
    if ($realTimeProtection) {
        $status = "Windows Defender real-time protection is disabled"
    } else {
        $status = "Windows Defender real-time protection is enabled"
    }
    Add-Content -Path $outputFile -Value "`r`n$status"

    $threats = (Get-MpThreatDetection | Select-Object -ExpandProperty Resources) -join "`n"
    Headers "Threats" $threats

    $mpPreference = Get-MpPreference
    $exclusions = $mpPreference.ExclusionPath -join "`n"
    Headers "Exclusions in Defender" $exclusions

    $exclusionPaths = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths').PSObject.Properties | 
                        Where-Object { $_.Name -notlike "PS*" } | 
                        ForEach-Object { $_.Name }

    Headers "Windows Defender Exclusion in Backlogs" $exclusionPaths

    $allowedExtensions = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Extensions').PSObject.Properties | 
                          Where-Object { $_.Name -notlike "PS*" } | 
                          ForEach-Object { $_.Name }

    Headers "Windows Defender Allowed File Extensions" $allowedExtensions

    $allowedProcesses = Get-MpPreference | Select-Object -ExpandProperty ExclusionProcess

    Headers "Windows Defender Allowed Processes" $allowedProcesses

    $detectionHistoryLogs = Get-ChildItem "C:\ProgramData\Microsoft\Windows Defender\Scans\History\Service" | 
                            Select-Object LastWriteTime, Name | 
                            Out-String
    Headers "Detection History Logs" $detectionHistoryLogs
}

$status = ProgStats "Avira" "Avira"
if ($status -eq "Avira is not installed") {
    Add-Content -Path $outputFile -Value "`r`n$status"
} else {
    Add-Content -Path $outputFile -Value "`r`n-------------------------"
    Add-Content -Path $outputFile -Value "|    Avira Antivirus    |"
    Add-Content -Path $outputFile -Value "-------------------------"

    $aviraExclusions = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Avira\Antivirus\REALTIME\OnAccess\Settings\Exclusions' | Out-String
    Headers "Avira Exclusions" $aviraExclusions

    $aviraLogs = Get-ChildItem -Path "C:\ProgramData\Avira\Antivirus\LOGS" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
    Headers "Avira Logs" $aviraLogs

    $aviraAllowed = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Avira\Antivirus\REALTIME\OnAccess\Settings\Exclusions' | Out-String
    Headers "Avira Allowed Files" $aviraAllowed
}

$status = ProgStats "AvastSvc" "Avast"
if ($status -eq "Avast is not installed") {
    Add-Content -Path $outputFile -Value "`r`n$status"
} else {
    Add-Content -Path $outputFile -Value "`r`n-------------------------"
    Add-Content -Path $outputFile -Value "|    Avast Antivirus    |"
    Add-Content -Path $outputFile -Value "-------------------------"

    $avastExclusions = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Avast Software\Avast\Exclusions' | Out-String
    Headers "Avast Exclusions" $avastExclusions

    $avastLogs = Get-ChildItem -Path "C:\ProgramData\Avast Software\Avast\log" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
    Headers "Avast Logs" $avastLogs

    $avastAllowed = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Avast Software\Avast\Exclusions' | Out-String
    Headers "Avast Allowed Files" $avastAllowed
}

$status = ProgStats "McAfeeDLPAgentService" "McAfee"
if ($status -eq "McAfee is not installed") {
    Add-Content -Path $outputFile -Value "`r`n$status"
} else {
    Add-Content -Path $outputFile -Value "`r`n-------------------------"
    Add-Content -Path $outputFile -Value "|   McAfee Antivirus    |"
    Add-Content -Path $outputFile -Value "-------------------------"

    $mcafeeExclusions = Get-ItemProperty -Path 'HKLM:\SOFTWARE\McAfee\SystemCore\VSCore\On Access Scanner\Exclusions' | Out-String
    Headers "McAfee Exclusions" $mcafeeExclusions

    $mcafeeLogs = Get-ChildItem -Path "C:\ProgramData\McAfee\DesktopProtection" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
    Headers "McAfee Logs" $mcafeeLogs

    $mcafeeAllowed = Get-ItemProperty -Path 'HKLM:\SOFTWARE\McAfee\SystemCore\VSCore\On Access Scanner\Exclusions' | Out-String
    Headers "McAfee Allowed Files" $mcafeeAllowed
}

$status = ProgStats "NortonSecurity" "Norton"
if ($status -eq "Norton is not installed") {
    Add-Content -Path $outputFile -Value "`r`n$status"
} else {
    Add-Content -Path $outputFile -Value "`r`n-------------------------"
    Add-Content -Path $outputFile -Value "|    Norton Antivirus   |"
    Add-Content -Path $outputFile -Value "-------------------------"

    $nortonExclusions = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Norton\Exclusions' | Out-String
    Headers "Norton Exclusions" $nortonExclusions

    $nortonLogs = Get-ChildItem -Path "C:\ProgramData\Norton\Logs" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
    Headers "Norton Logs" $nortonLogs

    $nortonAllowed = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Norton\Exclusions' | Out-String
    Headers "Norton Allowed Files" $nortonAllowed
}

$status = ProgStats "MBAMService" "Malwarebytes"
if ($status -eq "Malwarebytes is not installed") {
    Add-Content -Path $outputFile -Value "`r`n$status"
} else {
    Add-Content -Path $outputFile -Value "`r`n-------------------------"
    Add-Content -Path $outputFile -Value "|     Malwarebytes      |"
    Add-Content -Path $outputFile -Value "-------------------------"

    $malwarebytesExclusions = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Malwarebytes\Malwarebytes Anti-Malware\Exclusions' | Out-String
    Headers "Malwarebytes Exclusions" $malwarebytesExclusions

    $malwarebytesLogs = Get-ChildItem -Path "C:\ProgramData\Malwarebytes\MBAMService\logs" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
    Headers "Malwarebytes Logs" $malwarebytesLogs
}

$status = ProgStats "vsserv" "BitDefender"
if ($status -eq "BitDefender is not installed") {
    Add-Content -Path $outputFile -Value "`r`n$status"
} else {
    Add-Content -Path $outputFile -Value "`r`n-------------------------"
    Add-Content -Path $outputFile -Value "|      BitDefender      |"
    Add-Content -Path $outputFile -Value "-------------------------"

    $bitdefenderExclusions = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Bitdefender\Bitdefender\Exclusions' | Out-String
    Headers "BitDefender Exclusions" $bitdefenderExclusions

    $bitdefenderLogs = Get-ChildItem -Path "C:\ProgramData\Bitdefender\Bitdefender Security\Logs" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
    Headers "BitDefender Logs" $bitdefenderLogs
}

$firefoxProfileRoot = "$env:APPDATA\Mozilla\Firefox\Profiles"
$chromeProfileRoot = "$env:LOCALAPPDATA\Google\Chrome\User Data"
$edgeProfileRoot = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
$operaProfileRoot = "$env:APPDATA\Opera Software\Opera Stable"
$operaGXProfileRoot = "$env:APPDATA\Opera Software\Opera GX Stable"
$braveProfileRoot = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"

$firefoxPath = "C:\temp\dump\SQLECMD\Firefox"
$chromePath = "C:\temp\dump\SQLECMD\Chrome"
$edgePath = "C:\temp\dump\SQLECMD\Edge"
$operaPath = "C:\temp\dump\SQLECMD\Opera"
$operaGXPath = "C:\temp\dump\SQLECMD\OperaGX"
$bravePath = "C:\temp\dump\SQLECMD\Brave"
$browserPaths = @($firefoxPath, $chromePath, $edgePath, $operaPath, $operaGXPath, $bravePath)

function ChromiumBrowsers {
    param (
        [string]$profileRoot,
        [string]$browserPath
    )

    if (Test-Path $profileRoot) {
        $files = Get-ChildItem -Path $profileRoot -Recurse -Include "Favicons", "History" -File
        if ($files) {
            New-Item -ItemType Directory -Path $browserPath -Force | Out-Null

            foreach ($file in $files) {
                Copy-Item $file.FullName -Destination $browserPath -Force
            }
        }
    }
}

if (Test-Path $firefoxProfileRoot) {
    New-Item -ItemType Directory -Path $firefoxPath -Force | Out-Null
    $fflatestProfile = Get-ChildItem -Path $firefoxProfileRoot | Where-Object { $_.PSIsContainer } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    Copy-Item "$($firefoxProfileRoot)\$($fflatestProfile.Name)\places.sqlite" -Destination $firefoxPath -Force
    Copy-Item "$($firefoxProfileRoot)\$($fflatestProfile.Name)\favicons.sqlite" -Destination $firefoxPath -Force
}

ChromiumBrowsers -profileRoot $chromeProfileRoot -browserPath $chromePath
ChromiumBrowsers -profileRoot $edgeProfileRoot -browserPath $edgePath
ChromiumBrowsers -profileRoot $operaProfileRoot -browserPath $operaPath
ChromiumBrowsers -profileRoot $operaGXProfileRoot -browserPath $operaGXPath
ChromiumBrowsers -profileRoot $braveProfileRoot -browserPath $bravePath

C:\temp\dump\SQLECmd\SQLECmd.exe --sync
C:\temp\dump\SQLECmd\SQLECmd.exe -d "$firefoxPath" --maps C:\Temp\Dump\SQLECmd\Maps --csv "C:\temp\dump\SQLECMD\Firefox"
C:\temp\dump\SQLECmd\SQLECmd.exe -d "$chromePath" --maps C:\Temp\Dump\SQLECmd\Maps --csv "C:\temp\dump\SQLECMD\Chrome"
C:\temp\dump\SQLECmd\SQLECmd.exe -d "$edgePath" --maps C:\Temp\Dump\SQLECmd\Maps --csv "C:\temp\dump\SQLECMD\Edge"
C:\temp\dump\SQLECmd\SQLECmd.exe -d "$operaPath" --maps C:\Temp\Dump\SQLECmd\Maps --csv "C:\temp\dump\SQLECMD\Opera"
C:\temp\dump\SQLECmd\SQLECmd.exe -d "$operaGXPath" --maps C:\Temp\Dump\SQLECmd\Maps --csv "C:\temp\dump\SQLECMD\OperaGX"
C:\temp\dump\SQLECmd\SQLECmd.exe -d "$bravePath" --maps C:\Temp\Dump\SQLECmd\Maps --csv "C:\temp\dump\SQLECMD\Brave"

foreach ($path in $browserPaths) {
    Get-ChildItem -Path $path -File | Where-Object { [System.IO.Path]::GetExtension($_.Name) -ne '.csv' } | Remove-Item -Force
}

$basePath = "C:\temp\dump\sqlecmd"
$folders = Get-ChildItem -Path $basePath -Directory

foreach ($folder in $folders) {
    $browserName = $folder.Name
    $files = Get-ChildItem -Path $folder.FullName -Filter "*.csv"

    foreach ($file in $files) {
        $parts = $file.BaseName -split "_"
        if ($parts.Length -gt 3) {
            $evidencePart = $parts[2]
            $newFileName = "${browserName}_${evidencePart}.csv"
            Rename-Item -Path $file.FullName -NewName $newFileName
        }
    }
}

$basePath = "C:\temp\dump\sqlecmd"
$folders = Get-ChildItem -Path $basePath -Directory

foreach ($folder in $folders) {
    $browserName = $folder.Name
    $files = Get-ChildItem -Path $folder.FullName -Filter "*.csv"

    foreach ($file in $files) {
        $parts = $file.BaseName -split "_"
        if ($parts.Length -gt 3) {
            $evidencePart = $parts[2]
            $newFileName = "${browserName}_${evidencePart}.csv"
            Rename-Item -Path $file.FullName -NewName $newFileName
        }
    }
}

$keywords = "Favicon", "Downloads", "History"
$excludeKeywords = "navigation", "Form"
$allFiles = Get-ChildItem -Path $basePath -Recurse -Filter "*.csv"

foreach ($file in $allFiles) {
    $keepFile = $false

    foreach ($keyword in $keywords) {
        if ($file.Name -like "*$keyword*") {
            $keepFile = $true
            break
        }
    }

    foreach ($excludeKeyword in $excludeKeywords) {
        if ($file.Name -like "*$excludeKeyword*") {
            $keepFile = $false
            break
        }
    }

    if (-not $keepFile) {
        Remove-Item -Path $file.FullName -Force
    }
}

$browsingPath = "C:\temp\dump\SQLECMD"
$browserKeywords = "Astra", "Hydrogen", "Leet-Cheat", "Cheat", "ro9an", "Skript", "0xCheat", "reselling", "UsbDeview", "para-store", "para.ac", "mysellauth", "astrostore.cc", "shax", "vanish*cheat", "vanish*cleaner", "vanish-cheat", "Para Selling", "rose-shop", "leet.su", "aimbot", "wallhack", "triggerbot", "Healkey", "cdn.discord*.exe", "HWID", "Spoofer"
$outputCsvFilePath = "$browsingPath\Browserhistory.csv"
$browserHistoryResults = @()

Get-ChildItem -Path $browsingPath -Recurse -Filter "*History*.csv" | ForEach-Object {
    $historyCsvData = Import-Csv -Path $_.FullName
    foreach ($historyRow in $historyCsvData) {
        if ($browserKeywords | Where-Object { $historyRow.URL -like "*$_*" }) {
            $browserVisitTime = if ($historyRow.PSObject.Properties["LastVisitDate"]) {
                $historyRow.LastVisitDate
            } elseif ($historyRow.PSObject.Properties["VisitTime(Local)"]) {
                $historyRow."VisitTime(Local)"
            } elseif ($historyRow.PSObject.Properties["LastVisitedTime(Local)"]) {
                $historyRow."LastVisitedTime(Local)"
            } else {
                $historyRow.PSObject.Properties | Where-Object { $_.Name -like "VisitTime*" } | ForEach-Object { $_.Value } | Select-Object -First 1
            }
            
            $pageTitle = $historyRow.PSObject.Properties | Where-Object { $_.Name -like "*Title*" } | ForEach-Object { $_.Value } | Select-Object -First 1
            
            if ($browserVisitTime) {
                $browserHistoryResults += [PSCustomObject]@{
                    Time   = $browserVisitTime
                    Count  = $historyRow.VisitCount
                    URL    = $historyRow.URL
                    Title  = $pageTitle
                    Source = $_.FullName
                }
            }
        }
    }
}

$browserHistoryResults | Select-Object Time, Count, URL, Title, Source | Export-Csv -Path $outputCsvFilePath -NoTypeInformation

$faviconResults = @()

Get-ChildItem -Path $browsingPath -Recurse -Filter "*Favicon*.csv" | ForEach-Object {
    $faviconCsvData = Import-Csv -Path $_.FullName
    foreach ($faviconRow in $faviconCsvData) {
        if ($browserKeywords | Where-Object { $faviconRow.PageURL -like "*$_*" }) {
            $faviconTime = if ($faviconRow.PSObject.Properties["Expiration"]) {
                $faviconRow.Expiration
            } elseif ($faviconRow.PSObject.Properties["LastUpdated"]) {
                $faviconRow.LastUpdated
            } else {
                $null
            }
            
            if ($faviconTime) {
                $faviconResults += [PSCustomObject]@{
                    Time   = $faviconTime
                    URL    = $faviconRow.PageURL
                    Source = $_.FullName
                }
            }
        }
    }
}

$outputFaviconCsvPath = "$browsingPath\Favicons.csv"
$faviconResults | Select-Object Time, URL, Source | Export-Csv -Path $outputFaviconCsvPath -NoTypeInformation

$downloadResults = @()

Get-ChildItem -Path $browsingPath -Recurse -Filter "*Download*.csv" | ForEach-Object {
    $downloadCsvData = Import-Csv -Path $_.FullName
    foreach ($downloadRow in $downloadCsvData) {
        if ($browserKeywords | Where-Object { $downloadRow.DownloadURL -like "*$_*" }) {
            $downloadTime = if ($downloadRow.PSObject.Properties["StartTime"]) {
                $downloadRow.StartTime
            } else {
                $null
            }

            if ($downloadTime) {
                $downloadResults += [PSCustomObject]@{
                    Time         = $downloadTime
                    DownloadURL  = $downloadRow.DownloadURL
                    TargetPath   = $downloadRow.TargetPath
                    Source       = $_.FullName
                }
            }
        }
    }
}

$outputDownloadCsvPath = "$browsingPath\Downloads.csv"
$downloadResults | Select-Object Time, DownloadURL, TargetPath, Source | Export-Csv -Path $outputDownloadCsvPath -NoTypeInformation


Remove-Item -Path "C:\temp\Dump\SQLECMD\Maps" -Recurse -Force
Remove-Item -Path "C:\temp\Dump\SQLECMD\SQLECMD.exe" -Force
Get-ChildItem -Path "C:\temp\Dump\SQLECMD" -Directory | Remove-Item -Recurse -Force
Rename-Item -Path "C:\temp\dump\SQLECMD" -NewName "C:\temp\dump\BrowserHistory"

C:\temp\dump\hayabusa-2.17.0-win-x64.exe csv-timeline --live-analysis --no-wizard --clobber --output C:\temp\dump\Events\Events.csv
