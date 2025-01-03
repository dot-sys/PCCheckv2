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
# 30 - October - 2024

Clear-Host
Write-Host "`n`n`n`tThis Script requires the Full-Check to be run FIRST!" -Foregroundcolor Yellow
Write-Host "`n`n`n`t`tChecking for Dependancy." -Foregroundcolor Yellow
Start-Sleep 3

$filesizePaths = "C:\Temp\Dump\Processes\Filesize.txt"
if (-not (Test-Path $filesizePaths) -or (Get-Content $filesizePaths).Count -eq 0) {
    Write-Host "No Entries to check found - Nothing Detected."
    & C:\temp\scripts\Menu.ps1
}

New-Item -Path "C:\temp\dump\DIE" -ItemType Directory -Force | Out-Null

$culture = (Get-Culture).Name
if ($culture -like 'de*') {
    $lang = "Dieses Program benoetigt 1GB freien Speicherplatz auf deiner System-Festplatte.`n`n`nDie folgenden Programme werden gedownloaded: `n`n- DIE by horsicq (more Infos at https://github.com/horsicq).`n`nDer Check ist völlig Lokal, keine Daten werden gesammelt.`nFalls Spuren von Cheats gefunden werden, wird dazu geraten den PC zurueckzusetzen, ansonsten könnten Konsequenzen auf anderen Servern folgen.`nPC Check Programme auszufuehren - dazu gehoert auch dieses Script - kann außerhalb von PC Checks zu einem verfaelschten Ergebnis fuehren und ist verboten.`nStimmst du einem PC Check zu und moechtest du die oben genannten Tools Downloaden? (Y/N)"
} elseif ($culture -like 'tr*') {
    $lang = "Bu programı için Sistem Diskinizde 1GB boş disk gerekir.`n`n`nŞu programları indireceğiz`n`n- DIE by horsicq (more Infos at https://github.com/horsicq)`n`nBu tamamen yerel olacak, hiçbir veri toplanmayacak.`nEğer hile izleri bulunursa, bilgisayarınızı sıfırlamanız şiddetle tavsiye edilir, aksi takdirde diğer sunucularda da aynı durumla karşılaşabilirsiniz.`nBu script de dahil olmak üzere PC Kontrol Programlarını PC Kontrolleri haricinde çalıştırmak sonuca etki edebilir.`nPC Kontrolünü kabul ediyor musunuz ve söz konusu araçları programları indirmeyi kabul ediyor musunuz? (Y/N)"
} else {
    $lang = "This program requires 1GB of free disk space on your System Disk.`n`n`nWe will be downloading the programs: `n`n- DIE by horsicq (more Infos at https://github.com/horsicq)`n`nThis will be fully local, no data will be collected.`nIf Traces of Cheats are found, you are highly advised to reset your PC or you could face repercussions on other Servers.`nRunning PC Checking Programs, including this script, outside of PC Checks may have impact on the outcome.`nDo you agree to a PC Check and do you agree to download said tools? (Y/N)"
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
        @{url = "https://github.com/horsicq/DIE-engine/releases/download/3.09/die_win64_portable_3.09_x64.zip"; path = "C:\temp\dump\DIE\DIE.zip" }
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

    foreach ($filePath in Get-ChildItem 'C:\temp\dump\DIE' -Recurse -Filter '*.zip') {
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
    exit
}

Clear-Host
Write-Host "`n`n`n-------------------------"-ForegroundColor yellow
Write-Host "|   Script is Running   |" -ForegroundColor yellow
Write-Host "|      Please Wait      |" -ForegroundColor yellow
Write-Host "-------------------------`n"-ForegroundColor yellow
Write-Host " This takes ca. 5 Minutes`n`n`n"-ForegroundColor yellow

$resultsFile = "C:\Temp\Dump\Detection.txt"
$foundFiles = @()

Clear-Content $resultsFile -ErrorAction SilentlyContinue

$filesizeFound = Get-Content $filesizePaths | Where-Object { $_ -like "*.exe" }

foreach ($file in $filesizeFound) {
    $output = & "C:\Temp\Dump\DIE\diec.exe" -u "`"$file`""

    if ($output -like "*Windows Authenticode*") {
        continue
    }

    if ($output -like "*VMProtect*" -and $output -like "*Packer Detected*") {
        $cheatName = "Hydrogen"
        $foundFiles += $file
    } elseif ($output -like "*Generic*" -and $output -like "*Packer Detected*") {
        $cheatName = "Leet"
        $foundFiles += $file
    } elseif ($output -like "*Themida*" -and $output -like "*Packer Detected*") {
        $cheatName = "AstraRip"
        $foundFiles += $file
    } elseif ($output -like "*Visual*" -and $output -like "*C++*" -and $output -like "*Packer Detected*") {
        $cheatName = "Skript"
        $foundFiles += $file
    }
}

if ($foundFiles.Count -gt 0) {
    $headerMessage = "Severe Traces of Cheats found - Reverse Engineering Protection found:`n"
    Add-Content $resultsFile $headerMessage
    foreach ($file in $foundFiles) {
        Add-Content $resultsFile "Possible Detection in: $file`n"
    }
}

Add-Content $resultsFile "`nAll files processed:`n"
Add-Content $resultsFile ($filesizeFound -join "`n")

if ($foundFiles.Count -gt 0) {
    Write-Host "Possible detections found."
    $inputs = Read-Host "Script completed. Do you want to open the results? (Y/N)"
    
    if ($inputs -eq "Y") {
        Start-Process notepad.exe $resultsFile
    } else {
        Write-Host "No action taken. Returning to menu."
    }
}

& "C:\Temp\Scripts\Menu.ps1"
