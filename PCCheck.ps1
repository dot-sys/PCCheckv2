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
# 27 - November - 2024

$ErrorActionPreference = "SilentlyContinue" 
$configJson = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/dot-sys/cfg/master/cfg.json" 
$Astra = $configJson.Astra
$FilesizeH = $configJson.FilesizeH
$FilesizeL = $configJson.FilesizeL
$Hydro = $configJson.Hydro
$Leet = $configJson.Leet
$Skript = $configJson.Skript
$fsSkript = $configJson.fsSkript
$fsLeet = $configJson.fsLeet
$fsAstra = $configJson.fsAstra
$fsHydro = $configJson.fsHydro
$fsRo9an = $configJson.fsRo9an
$fsHitbox = $configJson.fsHitbox
$fsAbby = $configJson.fsAbby
$shaHashs = $configJson.shaHashs
$hashWordMap = $configJson.hashWordMap
$dmppath = "C:\Temp\Dump"
$scripttime = "Script-Run-Time: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"

Set-Location "$dmppath"
$l1 = & { "`n-------------------"; }
$l2 = & { "-------------------`n"; }
$l3 = & { "-------------------" }
# $l4 = & { "`n-------------------`n" }
$h1 = & { $l1; "|      System     |"; $l2; }
$h2 = & { $l1; "|    Tampering    |"; $l2; }
$h3 = & { $l1; "|     Threats     |"; $l2; }
$h4 = & { $l1; "|      Events     |"; $l2; }
$h5 = & { $l1; "|   Executables   |"; $l2; }
$h6 = & { $l1; "|       USB       |"; $l2; }
$h7 = & { $l1; "|    Detection    |"; $l2; }
$t1 = "`nSuspicious Files on System `r$l3"
$t2 = "`nSuspicious Files in Instance `r$l3"
$t3 = "`nProcess Uptime `r$l3"
$t4 = "`nDeleted Files `r$l3"

$dmppath = "C:\Temp\Dump"
$directories = @('AMCache\Raw', 'Events\Raw', 'Events\Haya', 'Journal\Raw', 'MFT\Filtered', 'MFT\Raw', 'Prefetch', 'Processes\Filtered', 'Processes\Raw', 'Registry\Raw', 'Shellbags', 'Shimcache', 'SRUM\RAW')
foreach ($dir in $directories) {
    New-Item -Path "$dmppath\$dir" -ItemType Directory -Force | Out-Null
}

$culture = (Get-Culture).Name
if ($culture -like 'de*') {
    $lang = "Dieses Program benoetigt 1GB freien Speicherplatz auf deiner System-Festplatte.`n`n`nDie folgenden Programme werden gedownloaded: `n`n- Hayabusa von Yamato Security `n- Hollows Hunter von hasherezade.net `n- Strings2 von Geoff McDonald (mehr Infos auf split-code.com) `n- MFTECmd, PECmd, SBECmd, RECmd, ACCParser, AmCacheParser, SRUMECmd, SQLECmd von Eric Zimmermans Tools (mehr Infos auf ericzimmerman.github.io).`n`nDer Check ist völlig Lokal, keine Daten werden gesammelt.`nFalls Spuren von Cheats gefunden werden, wird dazu geraten den PC zurueckzusetzen, ansonsten könnten Konsequenzen auf anderen Servern folgen.`nPC Check Programme auszufuehren - dazu gehoert auch dieses Script - kann außerhalb von PC Checks zu einem verfaelschten Ergebnis fuehren und ist verboten.`nStimmst du einem PC Check zu und moechtest du die oben genannten Tools Downloaden? (Y/N)"
}
elseif ($culture -like 'tr*') {
    $lang = "Bu programı için Sistem Diskinizde 1GB boş disk gerekir.`n`n`nŞu programları indireceğiz`n`n- Yamato Security den Hayabusa`n- Hasherezade.net sitesinden 'Hollows Hunter'`n- Geoff McDonald'den Strings2`n(detayli bilgi için split-code.com)`n- MFTECmd, PECmd, SBECmd, RECmd, ACCParser, AmCacheParser, SRUMECmd, SQLECmd from Eric Zimmermans Tools (detayli bilgi için  ericzimmerman.github.io).`n`nBu tamamen yerel olacak, hiçbir veri toplanmayacak.`nEğer hile izleri bulunursa, bilgisayarınızı sıfırlamanız şiddetle tavsiye edilir, aksi takdirde diğer sunucularda da aynı durumla karşılaşabilirsiniz.`nBu script de dahil olmak üzere PC Kontrol Programlarını PC Kontrolleri haricinde çalıştırmak sonuca etki edebilir.`nPC Kontrolünü kabul ediyor musunuz ve söz konusu araçları programları indirmeyi kabul ediyor musunuz? (Y/N)"
}
else {
    $lang = "This program requires 1GB of free disk space on your System Disk.`n`n`nWe will be downloading the programs: `n`n- Hayabusa by Yamato Security `n- Hollows Hunter by hasherezade.net `n- Strings2 by Geoff McDonald (more infos at split-code.com) `n- MFTECmd, PECmd, SBECmd, RECmd, ACCParser, AmCacheParser, SRUMECmd, SQLECmd from Eric Zimmermans Tools (more infos at ericzimmerman.github.io).`n`nThis will be fully local, no data will be collected.`nIf Traces of Cheats are found, you are highly advised to reset your PC or you could face repercussions on other Servers.`nRunning PC Checking Programs, including this script, outside of PC Checks may have impact on the outcome.`nDo you agree to a PC Check and do you agree to download said tools? (Y/N)"
}

Clear-Host
if ((Read-Host "`n`n`n"$lang) -eq "Y") {
    Clear-Host
    Write-Host "`n`n`n-------------------------"-ForegroundColor yellow
    Write-Host "|    Download Assets    |" -ForegroundColor yellow
    Write-Host "|      Please Wait      |" -ForegroundColor yellow
    Write-Host "-------------------------`n"-ForegroundColor yellow
    Add-Type -AssemblyName 'System.IO.Compression.FileSystem'

    function ExtractZipFile {
        param (
            [string]$ZipFilePath,
            [string]$DestinationPath
        )
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath, $DestinationPath)
    }
    $files = @(
        @{url = "https://github.com/glmcdona/strings2/releases/download/v2.0.0/strings2.exe"; path = "C:\temp\dump\strings2.exe" }
        @{url = "https://download.ericzimmermanstools.com/MFTECmd.zip"; path = "C:\temp\dump\MFTECmd.zip" }
        @{url = "https://download.mikestammer.com/PECmd.zip"; path = "C:\temp\dump\PECmd.zip" }
        @{url = "https://download.mikestammer.com/SBECmd.zip"; path = "C:\temp\dump\SBECmd.zip" }
        @{url = "https://download.mikestammer.com/RECmd.zip"; path = "C:\temp\dump\RECmd.zip" }
        @{url = "https://download.mikestammer.com/AppCompatCacheParser.zip"; path = "C:\temp\dump\AppCompatCacheParser.zip" }
        @{url = "https://download.mikestammer.com/AmcacheParser.zip"; path = "C:\temp\dump\AmcacheParser.zip" }
        @{url = "https://download.mikestammer.com/SrumECmd.zip"; path = "C:\temp\dump\SrumECmd.zip" }
        @{url = "https://github.com/Yamato-Security/hayabusa/releases/download/v2.17.0/hayabusa-2.17.0-win-x64.zip"; path = "C:\temp\dump\hayabusa.zip" }
        @{url = "https://github.com/hasherezade/hollows_hunter/releases/download/v0.3.9/hollows_hunter64.zip"; path = "C:\temp\dump\hollow_hunter.zip" }
        @{url = "https://download.ericzimmermanstools.com/SQLECmd.zip"; path = "C:\temp\dump\SQLECmd.zip" }
    )

    $webClients = @()
    foreach ($file in $files) {
        $wc = New-Object System.Net.WebClient
        $asyncResult = $wc.DownloadFileTaskAsync($file.url, $file.path)
        $webClients += [PSCustomObject]@{ WebClient = $wc; AsyncResult = $asyncResult; Path = $file.path }
    }

    $webClients | ForEach-Object {
        try {
            $_.AsyncResult.Wait()
            if ($_.WebClient.IsBusy) {
                $_.WebClient.CancelAsync()
                Write-Output "Failed to download $($_.Path)"
            }
        }
        catch {
            Write-Output "Error downloading $($_.Path): $_"
        }
    }

    foreach ($filePath in Get-ChildItem 'C:\temp\dump' -Recurse -Filter '*.zip') {
        $destination = [System.IO.Path]::GetDirectoryName($filePath.FullName)
        ExtractZipFile -ZipFilePath $filePath.FullName -DestinationPath $destination
    }
}
else {
    Clear-Host
    Write-Host "`n`n`nPC Check aborted by Player.`nThis may lead to consequences up to your servers Administration.`n`n`n" -Foregroundcolor red
    Write-Host "`n`n`tReturning to Menu in " -NoNewline 
    Write-Host "5 " -NoNewLine -ForegroundColor Magenta
    Write-Host "Seconds`n`n`n" -NoNewline
    Start-Sleep 5
    & C:\temp\scripts\Menu.ps1
    return
}

Clear-Host
Write-Host "`n`n`n-------------------------"-ForegroundColor yellow
Write-Host "|   Script is Running   |" -ForegroundColor yellow
Write-Host "|      Please Wait      |" -ForegroundColor yellow
Write-Host "-------------------------`n"-ForegroundColor yellow
Write-Host " This takes 5-20 Minutes`n`n`n"-ForegroundColor yellow

Write-Host "   Dumping System Logs"-ForegroundColor yellow
$quickMFTPath = "C:\temp\scripts\QuickMFT.ps1"
$useQuickMFT = Test-Path $quickMFTPath

$scriptPaths = @(
    if ($useQuickMFT) { "C:\temp\scripts\QuickMFT.ps1" } else { "C:\temp\scripts\MFT.ps1" },
    "C:\temp\scripts\ProcDump.ps1",
    "C:\temp\scripts\Registry.ps1",
    "C:\temp\scripts\SystemLogs.ps1"
)

$jobs = @()

foreach ($scriptPath in $scriptPaths) {
    $job = Start-Job -ScriptBlock {
        param($path)
        $startTime = Get-Date
        & powershell.exe -File $path
        $endTime = Get-Date
        $timeTaken = $endTime - $startTime
        $minutes = [math]::Floor($timeTaken.TotalMinutes)
        $seconds = $timeTaken.Seconds
        $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($path)
        return [PSCustomObject]@{
            Name    = $scriptName
            Minutes = $minutes
            Seconds = $seconds
        }
    } -ArgumentList $scriptPath

    $jobs += $job
}

while ($jobs) {
    foreach ($job in $jobs) {
        if ($job.State -eq 'Completed') {
            $result = Receive-Job -Job $job
            Write-Host "`t$($result.Name)" -ForegroundColor Cyan -NoNewline
            Write-Host " finished after" -NoNewline
            Write-Host " $($result.Minutes)" -ForegroundColor Magenta -NoNewline
            Write-Host " Minutes" -NoNewline
            Write-Host " $($result.Seconds)" -ForegroundColor Magenta -NoNewline
            Write-Host " Seconds"
            Remove-Job -Job $job
            $jobs = $jobs | Where-Object { $_ -ne $job }
        }
    }
    Start-Sleep -Seconds 1
}

$processes = @()
$processStartTimes = @()

foreach ($scriptPath in $scriptPaths) {
    $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-File '$scriptPath'" -PassThru -WindowStyle Hidden
    $processes += $process
    $processStartTimes += Get-Date
}

$filesToCheck = @(
    "C:\Temp\Dump\Events\Events.csv",
    "C:\Temp\Dump\Journal\Raw\Journal.csv",
    "C:\Temp\Dump\MFT\MFT.csv"
    #"C:\Temp\Dump\Processes\Raw\Explorer.txt"
)

while ($true) {
    $missingFiles = $filesToCheck | Where-Object { -not (Test-Path $_) }
    if (-not $missingFiles) { break }
    Start-Sleep -Seconds 5
}

Write-Host "   Importing Dumps"-ForegroundColor yellow
$AmCacheImp = Import-Csv C:\Temp\Dump\AMCache\AmCache.csv
$AmCacheUSBImp = Import-Csv C:\Temp\Dump\AMCache\USB.csv
$BrowserhistoryImp = Import-Csv C:\Temp\Dump\BrowserHistory\Browserhistory.csv
$DownloadsImp = Import-Csv C:\Temp\Dump\BrowserHistory\Downloads.csv
$FaviconsImp = Import-Csv C:\Temp\Dump\BrowserHistory\Favicons.csv
$EventsImp = Import-Csv C:\Temp\Dump\Events\Events.csv
$JournalImp = Import-Csv C:\Temp\Dump\Journal\Raw\Journal.csv
$MFTImp = Import-Csv C:\Temp\Dump\MFT\MFT.csv
$BamImp = Import-Csv C:\Temp\Dump\Registry\Bam.csv
$PrefetchImp = Import-Csv C:\Temp\Dump\Prefetch\Prefetch.csv
$ShellbagsImp = Import-Csv C:\Temp\Dump\Shellbags\Shellbags.csv
$ShimcacheImp = Import-Csv C:\Temp\Dump\Shimcache\Shimcache.csv
$SRUMImp = Import-Csv C:\Temp\Dump\SRUM\SRUM.csv
$Threats = Get-Content C:\Temp\Dump\Detections.txt

$eventResults = $EventsImp | Where-Object { $_.RuleTitle -like "*Defender*" -or $_.Level -eq "crit" -or $_.Level -eq "high" } | 
Select-Object @{Name = 'Timestamp'; Expression = { ($_.Timestamp -as [datetime]).ToString("dd/MM/yyyy HH:mm:ss") } }, RuleTitle |
ForEach-Object { "$($_.Timestamp) $($_.RuleTitle)" }
$eventResults2 = $EventsImp | Where-Object { $_.RuleTitle -eq "Credential Manager" -and $_.Details -match "Skript|Astra|Hydro|Leet-Cheats" } | 
Select-Object @{Name = 'Timestamp'; Expression = { ($_.Timestamp -as [datetime]).ToString("dd/MM/yyyy HH:mm:ss") } }, RuleTitle |
ForEach-Object { "$($_.Timestamp) $($_.RuleTitle)" }

$EventsImp | Where-Object { 
    $_.RuleTitle -notmatch "Credential Manager Enumerated|Powershell|pwsh|MSI Install|CodeIntegrity|Bits Job Created|RDS Sess" 
} | Sort-Object -Property @{Expression={
    switch ($_.Level) {
        "crit" {1}
        "high" {2}
        "med" {3}
        "low" {4}
        "info" {5}
    }
}} | Select-Object @{Name='Timestamp'; Expression={($_.Timestamp -as [datetime]).ToString('yyyy-MM-dd HH:mm:ss')}}, RuleTitle, Details, Level | Export-Csv -Path C:\temp\dump\Events\Events_Overview.csv -NoTypeInformation

$PrefetchImp | 
Select-Object LastRun, SourceFilename, RunCount, Volume1Serial | 
Export-Csv "C:\temp\dump\prefetch\Prefetch_Overview.csv" -NoTypeInformation
$AmCacheImp | 
Where-Object { $_.Size -gt 2100000 } | 
Select-Object LastWriteTime, FullPath, Size, FileExtension | 
Export-Csv "C:\temp\dump\AmCache\AmCache_Overview.csv" -NoTypeInformation
$twoMonth = (Get-Date).AddMonths(-2)
$filtOverview = $MFTImp | Where-Object {
    [datetime]$_.CreatedTimestamp -ge $twoMonth -and 
    [int64]$_.FileSize -gt 2100000 -and 
    $_.Extension -ne ".dll"
} | Select-Object CreatedTimestamp, FilePath, FileSize, Extension -Unique
$filtOverview | Export-Csv -Path "C:\temp\dump\MFT\MFT_Overview.csv" -NoTypeInformation


$hashFilePaths = @()
foreach ($hash in $shaHashs) {
    $trimmedHash = $hash.Trim()
    if ($hashWordMap.PSObject.Properties[$trimmedHash]) {
        $hashWord = $hashWordMap.$trimmedHash
    } else {
        $hashWord = "Unknown" 
    }
    $hashmatches = $AMCacheImp | Where-Object { $_.sha1.Trim() -ieq $trimmedHash }
    foreach ($match in $hashmatches) {
        $hashFilePaths += "`t$hashWord in $($match.fullpath)"
    }
}
if ($hashFilePaths.Count -gt 0) {
    $HashMatchings = "Found Hash matching during Importing:`n" 
    $HashMatchings += ($hashFilePaths -join "`n")  
}
$HashMatchings

$Threats = Get-Content C:\Temp\Dump\Detections.txt
$sUptime = Get-Content C:\Temp\Dump\Processes\Filtered\Uptime.txt

if ($MFTImp.Count -eq 0) {
    Start-Sleep -Seconds 5
}

$importings = @('AmCacheImp', 'AmCacheUSBImp', 'BrowserhistoryImp', 'DownloadsImp', 'FaviconsImp', 'EventsImp', 'JournalImp', 'MFTImp', 'BamImp', 'ShimcacheImp', 'SRUMImp', 'Threats')

foreach ($impnames in $importings) {
    $lineCount = (Get-Variable -Name $impnames -ValueOnly).Count
    if ($lineCount -eq 0) {
        Write-Output "`t$impnames not imported"
    }
}

Write-Host "   Analyzing System Information"-ForegroundColor yellow
$o1 = & {
    $scripttime
    "Connected Drives: $(Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3 -or $_.DriveType -eq 2} | ForEach-Object { "$($_.DeviceID)\" })" -join ', '
    $fatDrives = (Get-WmiObject Win32_LogicalDisk | Where-Object { ($_.FileSystem -eq 'FAT32' -or $_.FileSystem -eq 'exFAT') -and ($_.DriveType -eq 3 -or $_.DriveType -eq 2) } | ForEach-Object { "$($_.DeviceID)\" }) -join ', '
    if ($fatDrives) { "FAT Drive detected: $fatDrives" }
    "Volumes in Registry: $(if ($regvolumes = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows Search\VolumeInfoCache' | ForEach-Object { $_ -replace '^.*\\([^\\]+)$', '$1' }) { $regvolumes -join ', ' } else { 'Registry Volume Cache Manipulated' })"
    "Windows Version: $((Get-WmiObject -Class Win32_OperatingSystem).Caption), Build: $((Get-WmiObject -Class Win32_OperatingSystem).BuildNumber)"
    $windowsInstallDate = [Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject Win32_OperatingSystem).InstallDate).ToString('dd/MM/yyyy')
    "Windows Installation: $windowsInstallDate"
    $sruDBCreationDate = (Get-Item "C:\Windows\System32\sru\SRUDB.dat").CreationTime.ToString('dd/MM/yyyy')
    $AMCacheCreationDate = (Get-Item "C:\Windows\AppCompat\Programs\Amcache.hve").CreationTime.ToString('dd/MM/yyyy')
    $EventlogCreationDate = (Get-Item "C:\Windows\System32\winevt\Logs\Microsoft-Windows-Windows Defender%4Operational.evtx").CreationTime.ToString('dd/MM/yyyy')
    $infoText2 = "SRUM was created at $sruDBCreationDate`n"
    $infoText3 = "AMCache was created at $AMCacheCreationDate`n"
    $infoText4 = "Event Log was created at $EventlogCreationDate"
    $CreationDates = $infoText1 + $infoText2 + $infoText3 + $infoText4
    $CreationDates
    $lastClear = Get-PSDrive -PSProvider FileSystem | ForEach-Object { Get-ChildItem -Path (Join-Path -Path $_.Root -ChildPath '$Recycle.Bin') -Force -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { [PSCustomObject]@{ LastWriteTime = $_.LastWriteTime; PSDrive = $_.PSDrive.Name } } } | Sort-Object LastWriteTime -Descending | Select-Object -First 1; "Last Recycle Bin Clear: $($lastClear.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss')) on $($lastClear.PSDrive):\" 
    if ((Get-Item "C:\Windows\Prefetch\taskkill.exe*").LastWriteTime ) { "Last Taskkill: $((Get-Item "C:\Windows\Prefetch\taskkill.exe*").LastWriteTime)" }
    if ((Get-WinEvent -LogName Security -FilterXPath "*[System[(EventID=1102) and TimeCreated[timediff(@SystemTime) <= 604800000]]]")) { "Possible Event Log Clearing:"; Get-WinEvent -LogName Security -FilterXPath "*[System[(EventID=1102) and TimeCreated[timediff(@SystemTime) <= 604800000]]]" | Select-Object TimeCreated, Message }
    if (Get-ChildItem -Path 'C:\$Recycle.Bin' -Recurse -Force -Filter *.exe | Where-Object { $_.Length -ge $FilesizeL -and $_.Length -le $FilesizeH }) { "Potential Suspicious File found in Recycle Bin - Size Match" }
}

$bootDescriptions = @{
    '0x0' = 'restart'
    '0x1' = 'hybrid boot'
    '0x2' = 'resumed from hibernation'
    'lowPowerState' = 'hybrid boot or sleep'
}

$bootEvents = Get-WinEvent -ProviderName Microsoft-Windows-Kernel-Boot |
    Where-Object { $_.Message -match "boot type|boot options" } |
    Select-Object TimeCreated, Id, Message |
    Sort-Object TimeCreated -Descending

$lowPowerEvents = Get-WinEvent -LogName System -FilterXPath "*[System[EventID=1]]" |
    Where-Object { $_.Message -match "returned from a low power state" } |
    Select-Object TimeCreated, Id, Message |
    Sort-Object TimeCreated -Descending

$lastColdBoot = ($bootEvents | Where-Object { $_.Message -match 'boot type.*0x0' } | Select-Object -First 1 | ForEach-Object { 
    $uptime = New-TimeSpan -Start $_.TimeCreated -End (Get-Date)
    "Time since last Cold Boot: $($uptime.Days) Days, {0:D2}:{1:D2}:{2:D2}" -f $uptime.Hours, $uptime.Minutes, $uptime.Seconds 
})

$lastRestartEvent = ($bootEvents + $lowPowerEvents | Sort-Object TimeCreated -Descending | Select-Object -First 1)

$lastRestart = if ($lastRestartEvent) {
    $eventType = if ($lastRestartEvent.Id -eq 1 -and $lastRestartEvent.Message -match "returned from a low power state") {
        $bootDescriptions['lowPowerState']
    }
    elseif ($lastRestartEvent.Message -match '0x(0|1|2)') {
        $bootDescriptions[$matches[0]]
    }
    $uptime = New-TimeSpan -Start $lastRestartEvent.TimeCreated -End (Get-Date)
    "Time since last Restart ($eventType): $($uptime.Days) Days, {0:D2}:{1:D2}:{2:D2}" -f $uptime.Hours, $uptime.Minutes, $uptime.Seconds
} else {
    "No recent restart events found."
}

$LastBoot = "Last Boot up Time: $((Get-CimInstance Win32_OperatingSystem).LastBootUpTime | Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" 

$usbPNPDevices = Get-PnpDevice | Where-Object { $_.InstanceId.StartsWith('USBSTOR') }
$usbPropertiesList = @()

foreach ($device in $usbPNPDevices) {
    $properties = Get-PnpDeviceProperty -InstanceID $device.InstanceId
    $propertyData = @{
        USBName          = $null
        Connected        = $null
        Type             = $null
        FirstConnected   = $null
        LastConnected    = $null
        LastDisconnected = $null
    }
    
    foreach ($property in $properties) {
        switch ($property.KeyName) {
            'DEVPKEY_Device_FriendlyName' {
                $propertyData.USBName = $property.Data
            }
            'DEVPKEY_Device_FirstInstallDate' {
                $propertyData.FirstConnected = Get-Date $property.Data -Format 'dd/MM/yyyy HH:mm'
            }
            'DEVPKEY_Device_LastArrivalDate' {
                $propertyData.LastConnected = Get-Date $property.Data -Format 'dd/MM/yyyy HH:mm'
            }
            'DEVPKEY_Device_LastRemovalDate' {
                $propertyData.LastDisconnected = Get-Date $property.Data -Format 'dd/MM/yyyy HH:mm'
            }
            'DEVPKEY_Device_IsPresent' {
                $propertyData.Connected = $property.Data
                if ($propertyData.Connected -eq $true) {
                    $deviceVolumes = Get-Volume | Where-Object { $_.DriveType -eq 'Removable' }
                    foreach ($volume in $deviceVolumes) {
                        if ($volume.FileSystem) {
                            $propertyData.Type = $volume.FileSystem
                        }
                    }
                }
            }
        }
    }
    
    $usbPropertiesList += [PSCustomObject]$propertyData
}

if ($usbPropertiesList) {
    $usbOutput = "`nUSB Connection Information`n--------------------`n"
    $usbOutput += $usbPropertiesList | Format-Table USBName, Connected, Type, FirstConnected, LastConnected, LastDisconnected -AutoSize | Out-String
    Add-Content -Path $usbOutputFile -Value $usbOutput
}

$drives = Get-Volume | Where-Object {
    $_.DriveLetter -and $_.FileSystemType -ne 'NTFS' -and $_.Size -lt 256GB
} | Select-Object DriveLetter, FriendlyName, FileSystemType, DriveType, Size

foreach ($drive in $drives) {
    $path = $drive.DriveLetter + ":\"

    function Format-Date {
        param ($date)
        return $date.ToString("dd/MM/yyyy HH:mm")
    }

    $newFiles = Get-ChildItem -Path $path -Recurse -Force | Where-Object {
        $_.LastWriteTime -ge (Get-Date).AddDays(-7) -or $_.CreationTime -ge (Get-Date).AddDays(-7)
    } | Select-Object Name, @{Name = 'LastWriteTime'; Expression = { Format-Date $_.LastWriteTime } }, @{Name = 'CreationTime'; Expression = { Format-Date $_.CreationTime } }, @{Name = 'LastAccessTime'; Expression = { Format-Date $_.LastAccessTime } }, @{Name = 'FileSize in MB'; Expression = { [math]::Round(($_.Length / 1MB), 2) } }

    if ($newFiles) {
        $newFilesOutput = "New files found on drive $($drive.DriveLetter)`n--------------------------`n"
        $newFilesOutput += $newFiles | Format-Table -AutoSize | Out-String
        Add-Content -Path $usbOutputFile -Value $newFilesOutput
    }
}

foreach ($drive in $drives) {
    $path = $drive.DriveLetter + ":\"

    $usbHiddenFiles = Get-ChildItem -Path $path -Force | Where-Object { 
        ($_.Attributes -band [IO.FileAttributes]::Hidden) -and 
        -not ($_.Attributes -band [IO.FileAttributes]::System) 
    } | Select-Object Name, @{Name = 'LastWriteTime'; Expression = { Format-Date $_.LastWriteTime } }, @{Name = 'CreationTime'; Expression = { Format-Date $_.CreationTime } }, @{Name = 'LastAccessTime'; Expression = { Format-Date $_.LastAccessTime } }, @{Name = 'FileSize in MB'; Expression = { [math]::Round(($_.Length / 1MB), 2) } }

    if ($usbHiddenFiles) {
        $hiddenFilesOutput = "Hidden Files found on Drive $($drive.DriveLetter)`n--------------------------`n"
        $hiddenFilesOutput += $usbHiddenFiles | Format-Table -AutoSize | Out-String
        Add-Content -Path $usbOutputFile -Value $hiddenFilesOutput
    }
}

$usbFileList = foreach ($drive in $drives) {
    Get-ChildItem -Path "$($drive.DriveLetter):\" -Recurse -File | Select-Object FullName, Length
}

if ($AMCacheUSBImp) {
    $hiddenFilesOutput = "USBs found in Registry`n"
    $hiddenFilesOutput += "--------------------------`n"
    $hiddenFilesOutput += "LastWriteTime           Description                  Manufacturer`n"

    $AMCacheUSBImp | ForEach-Object {
        $lastWriteTime = "{0,-23}" -f $_.LastWriteTime
        $description = "{0,-30}" -f $_.Description
        $manufacturer = "{0,-30}" -f $_.Manufacturer
        $hiddenFilesOutput += "$lastWriteTime $description $manufacturer`n"
    }

    Add-Content -Path $usbOutputFile -Value $hiddenFilesOutput
}

$ShimcacheMatches = $ShimcacheImp | Where-Object { $_.Path -match "sign\.media" }

if ($ShimcacheMatches) {
    $usbExecutions = "`nPossible Files executed from a USB:`n"
    $usbExecutions += ($ShimcacheMatches | ForEach-Object { $_.Path }) -join "`n"
}

Write-Host "   Sorting and Filtering Evidences"-ForegroundColor yellow
$procPaths = Get-Content "C:\Temp\Dump\Processes\Raw\explorer.txt", "C:\Temp\Dump\Processes\Raw\pcasvc.txt" | Where-Object { $_ -match "^[A-Za-z]:\\.+\.exe$" }
$shimPaths = $ShimcacheImp | Where-Object { $_.Path -match '^[A-Za-z]:\\.*\.exe$' -and $_.FileSize -ge $FileSizeL -and $_.FileSize -le $FileSizeH } | Select-Object Path
$amcachePaths = $AmCacheImp | Where-Object { $_.FullPath -like '*:\*' } | Select-Object -ExpandProperty FullPath
$srumPaths = $SRUMImp | Where-Object { $_.ExeInfo -like '*:\*' } | Select-Object -ExpandProperty ExeInfo 
$mftPaths = $MFTImp | Where-Object { $_.FileSize -ge $FileSizeL -and $_.FileSize -le $FileSizeH -and $_.FilePath -like '*:\*' } | Select-Object -ExpandProperty FilePath | Sort-Object -Unique 
$journalPaths = $JournalImp | Where-Object { $_.FilePath -like '*:\*' } | Select-Object -ExpandProperty FilePath
$bamPaths = $BamImp | Where-Object { $_.Program -like '*:\*' } | Select-Object -ExpandProperty Program
$pcaPaths = Get-Content -Path "C:\Temp\Dump\Processes\Filtered\Pca_AppLauncher.txt", `
    "C:\Temp\Dump\Processes\Filtered\Pca_Extended.txt", `
    "C:\Temp\Dump\Processes\Filtered\PcaClient.txt"
$o2 = $journalPaths | Where-Object { $_ -match "1337|skript|usbdeview|loader_64|abby|ro9an|hitbox|w32|vds|systeminformer|hacker|aimbot|triggerbot|clumsy" } | Sort-Object -Unique
$o2 | Set-Content "C:\temp\dump\journal\Keywordsearch.txt"
$susJournal = if ($o2) { "Suspicious Files found in Journal" }

@($procPaths; $shimPaths; $amcachePaths; $srumPaths; $mftPaths; $bamPaths; $pcaPaths) | Sort-Object -Unique | Add-Content -Path "C:\Temp\Dump\Processes\Paths.txt" -Encoding UTF8
$paths = Get-Content "C:\Temp\Dump\Processes\Paths.txt" | Where-Object { $_ -match '\.exe$' -and $_ -notmatch '@{' }

$filesizeFound = @()
$noFilesFound = @()
$paths | ForEach-Object {
    $fPa = $_
    if (Test-Path $fPa) {
        $fSi = (Get-Item $fPa).Length
        if ($fSi -ge ($filesizeL) -and $fSi -le ($filesizeH)) {
            $filesizeFound += $fPa
        }
    }
    else {
        $noFilesFound += "File Deleted: $fPa"
    }
}
$filesizeFound | Out-File "C:\Temp\Dump\Processes\Filesize.txt"
$noFilesFound | Out-File "C:\Temp\Dump\Processes\Deletedfile.txt"

$filesizeFound | ForEach-Object { 
    if (Test-Path $_) { 
        $signature = Get-AuthenticodeSignature -FilePath $_
        if ($signature.Status -ne 'Valid') { 
            $_ 
        } 
    } 
} | Out-File "C:\Temp\Dump\Processes\Unsigned.txt"

Get-Content "C:\Temp\Dump\Processes\Unsigned.txt" | ForEach-Object { 
    if ($_ -in (Get-Content "C:\Temp\Dump\Processes\Filesize.txt")) {
        $_ 
    } 
} | Set-Content "C:\Temp\Dump\Processes\Combined.txt"

$combine = Get-Content "C:\Temp\Dump\Processes\Combined.txt"

Write-Host "   Checking for Manipulation"-ForegroundColor yellow
$documentspath = [System.Environment]::GetFolderPath('MyDocuments')
$settingsFilePath = "$documentspath\Rockstar Games\GTA V\settings.xml"
$settingsxml = Get-Content $settingsFilePath
$linesToCheck = $settingsxml[1..($settingsxml.Length - 1)]
$minusLines = $linesToCheck | Where-Object { $_ -match "-" }
$lodScaleLines = $linesToCheck | Where-Object { $_ -match '<LodScale' -and ([float]($_ -replace '.*value="([0-9.]+)".*', '$1')) -lt 1.0 }
$minusResults = ($minusLines + $lodScaleLines) -join "`n"
$settingslastModified = "Settings.xml last modified: $((Get-Item $settingsFilePath).LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss'))"

$minusSettings = if ($minusResults) {
    "Minus-Settings found in settings.xml:"
    $minusResults
}

$usnTampering = if ($JournalImp.Length -lt 1000) { "`nPotential Manipulation in USNJournal Detected - Filesize: $($JournalImp.Length)" }

$evtTampering = ("`nEventvwr Registration: $((Get-Item ""$env:APPDATA\Microsoft\MMC\eventvwr"").LastWriteTime)")
$evtTampering2 = ("`nEventvwr Settings: $((Get-Item ""$env:LOCALAPPDATA\Microsoft\Event Viewer\Settings.Xml"").LastWriteTime)")
$evtlogFolderPath = "C:\Windows\System32\winevt\Logs"
$evtlogFiles = @("Microsoft-Windows-Windows Defender%4Operational.evtx", "Application.evtx", "Security.evtx", "System.evtx", "Windows PowerShell.evtx", "Microsoft-Windows-Kernel-PnP%4Configuration.evtx", "Microsoft-Windows-PowerShell%4Operational.evtx")
$evtTampering3 = $evtlogFiles | ForEach-Object {
    $path = Join-Path $evtlogFolderPath $_
    if (Test-Path $path) {
        $info = Get-Item $path
        if ($info.LastAccessTime -gt $info.LastWriteTime) {
            "`n$($info.Name -replace '\.evtx$') potentially manipulated"
        }
    }
}

$prefhideTampering = (Get-ChildItem -Force "C:\Windows\Prefetch" | ForEach-Object {
        $attributes = $_.Attributes
        if ($attributes -band [System.IO.FileAttributes]::Hidden -or $attributes -band [System.IO.FileAttributes]::ReadOnly) {
            "`nPotential File Manipulation Detected (Hidden or Read-Only): $_"
        }
    }) -join "`n"

$volTampering = (Get-ChildItem -Path "C:\Windows\Prefetch" -Filter "vds*.exe*.pf" | ForEach-Object { "Potential Virtual Disk Manipulation - $($_.LastWriteTime)" }) -join "`n"
$volTampering2 = if (-not (Test-Path "C:\windows\inf\setupapi.dev.log") -or ((Get-Item "C:\windows\inf\setupapi.dev.log").LastWriteTime -lt (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime)) { 
    "`nPotential Volume Manipulation - SetupAPI Manipulated" 
}
elseif (Get-Content "C:\windows\inf\setupapi.dev.log" -Force | Select-String "vds.exe") { 
    "Potential Volume Manipulation found in Setupapi" 
}

$timeTampering = if (Get-WinEvent -FilterHashtable @{LogName = 'System'; ProviderName = 'Microsoft-Windows-Time-Service'; Level = 3 } -MaxEvents 1) { "Possible Time Tampering found in Eventlogs" }

$hideTampering = ($combine | Where-Object { $_ -and (Test-Path $_) } | ForEach-Object { if ((Get-ChildItem -Force $_).Attributes -match "Hidden") { "Potential Hidden File Manipulation Detected: $_" } }) -join "`n"

$wmicTampering = if (Select-String -Path "C:\Temp\Dump\Processes\Raw\explorer.txt" -Pattern "Process call|call create") { "Potential WMIC bypassing found in Explorer" }

$browserSuspicion = if ($BrowserhistoryImp -or $DownloadsImp -or $FaviconsImp) { "Possible suspicious Activity in Browsers Detected" }

$Tamperings = @(
    $usnTampering
    $evtTampering
    $evtTampering2
    $evtTampering3
    $prefhideTampering
    $volTampering
    $volTampering2
    $hideTampering
    $wmicTampering
    $timeTampering 
    $RTProtectingTampering
)

Write-Host "   Analyze Filematching on System"-ForegroundColor yellow
$recentMatches = $mftImp | Where-Object { $_.CreatedTimestamp -ge (Get-Date).AddDays(-7) }

$MFTdllMatch = $recentMatches | Group-Object { 
    [System.IO.Path]::GetFileNameWithoutExtension($_.FilePath) 
} | Where-Object {
    $exe = $_.Group | Where-Object { [System.IO.Path]::GetExtension($_.FilePath) -eq ".exe" }
    $dll = $_.Group | Where-Object { [System.IO.Path]::GetExtension($_.FilePath) -eq ".dll" }
    
    $noWindowsAppsPath = $_.Group.FilePath -notmatch "WindowsApps" -and $_.Group.FilePath -notmatch "Microsoft"
    
    $exe -and $dll -and ($dll.FileSize -gt $exe.FileSize) -and 
    $_.Count -le 2 -and 
    $noWindowsAppsPath
}

$MFTdllMatchOutput = foreach ($group in $MFTdllMatch) {
    $folder = [System.IO.Path]::GetDirectoryName($group.Group[0].FilePath)
    $filename = $group.Name
    "Found DLL Matching of $filename in $folder"
}

if ($MFTdllMatchOutput.Count -gt 0) {
    $mftdllmatchings = "`t`tFound " + $($MFTdllMatchOutput.Count) + " Matches of DLL and EXE on Filesystem"
    Write-Host "`t`tFound " -NoNewLine
    Write-Host "$($MFTdllMatchOutput.Count) " -NoNewLine -ForegroundColor Magenta
    Write-Host "Matches of DLL and EXE on Filesystem"
}

$MFTdllMatchOutput | Out-File -FilePath "C:\temp\dump\mft\MFT_DLL_Matches.txt" -Encoding UTF8

Write-Host "   Invoking Direct Detection - Finishing"-ForegroundColor yellow
$dps = (Get-Content C:\temp\dump\processes\raw\dps.txt | Where-Object { $_ -match '!!' -and $_ -match 'exe' -and $_ -match '2024' } | Sort-Object -Unique) -join "`n"
$Cheats1 = ""

$instancePattern = "($Skript|$Hydro|$Astra|$Leet)"

if ($dps -match $instancePattern) {
    $Cheats1 += "`nSevere Traces of Cheats found in Instance`n"
    $Cheats1 += ($dps -split "`n" | Where-Object { $_ -match $instancePattern } | ForEach-Object { "`t$_" }) -join "`n"
}

$Cheats2 = ""
$CheatThreats = $EventsImp | Where-Object { 
    $_.RuleTitle -like "*Defender Alert*" -and 
    ($_.Details -like "*Wacatac*" -or $_.Details -like "*Phonzy*") 
}

if ($CheatThreats) {
    $Cheats2 += "`nPossible Traces of Cheats found in Threat-Protection:`n"
    foreach ($finding in $CheatThreats) {
        $details = $finding.Details
        $threatMatch = [regex]::Match($details, "Threat: ([^¦]+)")
        $pathMatch = [regex]::Match($details, "Path: file:_([^¦]+)")

        if ($threatMatch.Success -and $pathMatch.Success) {
            $threat = $threatMatch.Groups[1].Value -replace 'Virus:', ''
            $path = $pathMatch.Groups[1].Value

            $Cheats2 += "`t$threat found in $path`n"
        }
    }
}

$Cheats3 = $mftImp | Where-Object { 
    $_.Filepath -match "usbdeview|ro9an|aimbot|triggerbot|gambohub|abbyace|hitbox|clumsy" -or 
    $_.Filesize -in $fsSkript, $fsLeet, $fsAstra, $fsHydro, $fsAbby, $fsHitbox, $fsRo9an 
} | Select-Object -ExpandProperty Filepath -Unique

$Cheats3 += $ShellbagsImp | Where-Object { 
    $_ -match "usbdeview|ro9an|aimbot|triggerbot|gambohub|abbyace|hitbox|clumsy|trigger|abbyace|1337-Scripts|1337" 
}

$Cheats3 += $paths | Where-Object { 
    $_ -match "usbdeview|ro9an|aimbot|triggerbot|gambohub|abbyace|hitbox|clumsy" 
}

$Cheats3 = $Cheats3 | Sort-Object -Unique

if ($Cheats3.Count -gt 0) {
    $headerC3 = "`nSevere Traces of Cheats found on Filesystem:`n"
    $formattedC3 = $Cheats3 | Sort-Object -Unique | ForEach-Object { "`t$_" }
    $Cheats3 = @($headerC3) + $formattedC3
}

$Cheats4 = $journalPaths | Where-Object { 
    $_ -match "usbdeview|ro9an|aimbot|triggerbot|gambohub|abbyace|hitbox|clumsy"
}

if ($Cheats4.Count -gt 0) {
    $headerC4 = "`nSevere Traces of Cheats found in Journal:`n"
    $formattedC4 = $Cheats4 | Sort-Object -Unique | ForEach-Object { "`t$_" }
    $Cheats4 = @($headerC4) + $formattedC4
}

$Cheats5 = $usbFileList | Where-Object { 
    $_.FullName -match "usbdeview|ro9an|aimbot|triggerbot|gambohub|abbyace|hitbox|clumsy" -or 
    $_.Length -in @($fsSkript, $fsLeet, $fsAstra, $fsHydro, $fsAbby, $fsHitbox, $fsRo9an)
}

$usbExeDllMatch = $usbFileList | Group-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.FullName) } | Where-Object {
    $extensions = $_.Group | ForEach-Object { [System.IO.Path]::GetExtension($_.FullName) }
    $extensions -contains ".exe" -and $extensions -contains ".dll"
}

if ($Cheats5.Count -gt 0 -or $usbExeDllMatch.Count -gt 0) {
    $outputHeader = "`nSevere Traces of Cheats found on USB:`n"
    
    foreach ($file in $Cheats5) {
        $outputHeader += "`t$($file.FullName)`n"
    }
    
    foreach ($match in $usbExeDllMatch) {
        foreach ($file in $match.Group) {
            $outputHeader += "`t$($file.FullName)`n"
        }
    }

    $Cheats5 = $outputHeader
}

$eventResults2 = $EventsImp | Where-Object { 
    $_.RuleTitle -like "*Credential Manager*" -and 
    $_.Details -match "Skript|Astra|Hydro|Leet-Cheats" 
} | Select-Object @{Name = 'Timestamp'; Expression = { ($_.Timestamp -as [datetime]).ToString("dd/MM/yyyy HH:mm:ss") } }, Details

$Cheats6 = ""

if ($eventResults2.Count -ne 0) {
    $Cheats6 += "`nPossible Cheat-Login Found:`n"
    foreach ($event in $eventResults2) {
        $timestamp = $event.Timestamp
        $details = $event.Details

        if ($details -match "Skript") {
            $Cheats6 += "`tSkript found on $timestamp`n"
        }
        if ($details -match "Astra") {
            $Cheats6 += "`tAstra-Rip found on $timestamp`n"
        }
        if ($details -match "Leet") {
            $Cheats6 += "`tLeet found on $timestamp`n"
        }
        if ($details -match "Hydro") {
            $Cheats6 += "`tHydrogen found on $timestamp`n"
        }
    }
}

$Cheats7 = $HashMatchings

if ($Cheats1 -or $Cheats2 -or $Cheats3 -or $Cheats4 -or $Cheats5 -or $Cheats6 -or $Cheats7) { $Cheatsheader = $h7 }

@($Cheatsheader; $cheats1; $cheats2; $cheats3; $cheats4; $cheats5; $cheats6; $h1; $o1; $susJournal; $browserSuspicion; $minusSettings; $settingslastModified; $t3; $sUptime; $lastColdBoot; $lastRestart; $LastBoot; $h6; $usbOutput; $usbExecutions; $h2; $Tamperings; $h3; $threats; $h4; $eventResults; $h5; $t1; $combine; $t2; $dps1; $r; $t4; $noFilesFound) | Add-Content C:\Temp\Dump\Results.txt

Remove-Item -Path "C:\Temp\Dump\config", "C:\Temp\Dump\logs", "C:\Temp\Dump\rules", "C:\Temp\Dump\RECmd", "C:\Temp\Dump\Events\Haya", "C:\Temp\Dump\Events\Raw" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Temp\Dump\*.exe", "C:\Temp\Dump\*.zip", "C:\Temp\Dump\Detections.txt" -Force -ErrorAction SilentlyContinue
Move-Item -Path C:\Temp\Scripts\Viewer.html -Destination C:\Temp\Dump\Viewer.html
Remove-MpPreference -ExclusionPath 'C:\Temp'

Start-Sleep 2
Clear-Host
$Cheats1
$Cheats2
$Cheats3
$Cheats4
$Cheats5
$Cheats6
$Cheats7
$MFTDllMatchings
Write-Host "`n`n`n`tScript finished" -NoNewline -Foregroundcolor Cyan
Write-Host " - Do you want to open the Results in the Browser? (Y / N): " -NoNewline 
$response = Read-Host

if ($response -eq 'Y') {
    Start-Process powershell -ArgumentList '-File "C:\Temp\Scripts\Localhost.ps1"' -WindowStyle Hidden
    Start-Sleep 1
    Start-Process "http://localhost:8080/viewer.html"
    #Start-Process -FilePath "notepad.exe" -ArgumentList "C:\temp\dump\results.txt"
    Write-Host "`n`n`n`tResults will open" -Foregroundcolor Green
    Write-Host "`tReturning to Menu in " -NoNewline 
    Write-Host "3 " -NoNewLine -ForegroundColor Magenta
    Write-Host "Seconds`n`n`n" -NoNewline
    Start-Sleep 3
}
elseif ($response -eq 'N') {
    Write-Host "`n`n`n`tUser chose No" -Foregroundcolor Red
    Write-Host "`tReturning to Menu in " -NoNewline 
    Write-Host "3 " -NoNewLine -ForegroundColor Magenta
    Write-Host "Seconds`n`n`n" -NoNewline
    Start-Sleep 3
}
Clear-Host

Get-Variable | Where-Object { $_.Name -like '*Imp' } | Remove-Variable
& "C:\Temp\Scripts\Menu.ps1"
