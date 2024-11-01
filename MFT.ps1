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
# 01 - November - 2024

$ErrorActionPreference = "SilentlyContinue"
$MFTPath = "C:\temp\dump\MFT"
Set-Location "$MFTPath"

$mftDrives = Get-WmiObject Win32_LogicalDisk | Select-Object -ExpandProperty DeviceID | ForEach-Object { $_.Substring(0, 1) }
foreach ($mftDriveLetter in $mftDrives) {
    & "C:\temp\dump\mftecmd.exe" -f "${mftDriveLetter}:\`$Extend\`$UsnJrnl:`$J" -m "${mftDriveLetter}:\`$MFT" --fl --csv "C:\Temp\Dump\MFT"
    
    $mftFiles = Get-ChildItem "$MFTPath\*.csv" | Select-Object -Unique
    foreach ($mftFile in $mftFiles) {
        $mftNewName = "${mftDriveLetter}_$($mftFile.Name)"
        $mftNewPath = "$MFTPath\$mftNewName"
        Rename-Item -Path $mftFile.FullName -NewName $mftNewName
        Move-Item -Path $mftNewPath -Destination "$MFTPath\Raw"
    }
}


$mftFolderPath = "$MFTPath\Raw"
$mftCsvFiles = Get-ChildItem -Path $mftFolderPath -Filter *.csv
    
foreach ($mftFile in $mftCsvFiles) {
    $mftCsvPath = $mftFile.FullName
    $mftTempPath = [System.IO.Path]::GetTempFileName()
    $mftDriveLetter = $mftFile.BaseName[0]
    
    try {
        $mftReader = [System.IO.StreamReader]::new($mftCsvPath)
        $mftWriter = [System.IO.StreamWriter]::new($mftTempPath, $false)
            
        $mftHeader = $mftReader.ReadLine()
        if ($mftHeader) {
            if ($mftHeader -match 'Drive') {
                $mftWriter.WriteLine($mftHeader)
            }
            else {
                $mftWriter.WriteLine("Drive,$mftHeader")
            }
            
            while ($mftLine = $mftReader.ReadLine()) {
                if ($mftHeader -match 'Drive') {
                    $mftWriter.WriteLine($mftLine)
                }
                else {
                    $mftWriter.WriteLine("$mftDriveLetter,$mftLine")
                }
            }
        }
            
        $mftReader.Close()
        $mftWriter.Close()
    
        Remove-Item -Path $mftCsvPath -Force
        Move-Item -Path $mftTempPath -Destination $mftCsvPath
    
    }
    catch {
        Write-Error "Failed to process file ${mftCsvPath}: $_"
        if (Test-Path $mftTempPath) { Remove-Item -Path $mftTempPath -Force }
    }
}
    
$mftSourcePath = "$MFTPath\Raw"
    
Get-ChildItem -Path $mftSourcePath -File | Where-Object {
    $_.Name -like '*$J_output.csv' -or $_.Name -like '*Filelisting.csv'
} | ForEach-Object {
    $mftInputFile = $_.FullName
    $mftOutputFile = Join-Path -Path $mftSourcePath -ChildPath "$($_.BaseName)_filtered.csv"
    
    Import-Csv -Path $mftInputFile | Where-Object { $_.Extension -match '\.(exe|rar|zip|identifier|rpf|dll)$' } | Export-Csv -Path $mftOutputFile -NoTypeInformation
}
    
$mftSourcePath = "$MFTPath\Raw"
$mftDestinationPath = "$MFTPath\Filtered"
    
Get-ChildItem -Path $mftSourcePath -Filter '*_filtered.csv' | ForEach-Object {
    Move-Item -Path $_.FullName -Destination $mftDestinationPath -Force
}
    
$mftSourceDir = "$MFTPath\Filtered"
$mftFileListingFiles = Get-ChildItem -Path $mftSourceDir -Filter '*FileListing_filtered.csv' | Select-Object -ExpandProperty FullName
$mftOutputFiles = Get-ChildItem -Path $mftSourceDir -Filter '*Output_filtered.csv' | Select-Object -ExpandProperty FullName
    
function mftJoinSortAndSelectCsv {
    param (
        [string[]]$mftFiles,
        [string]$mftSortColumn,
        [string[]]$mftSelectColumns
    )
    
    if ($mftFiles.Length -eq 0) {
        return
    }
    
    $mftAllData = Import-Csv -Path $mftFiles[0]
    foreach ($mftFile in $mftFiles[1..($mftFiles.Length - 1)]) {
        $mftAllData += Import-Csv -Path $mftFile
    }
    
    $mftSortedData = $mftAllData | Sort-Object -Property $mftSortColumn -Descending
    $mftSelectedData = $mftSortedData | Select-Object -Property $mftSelectColumns
    return $mftSelectedData
}
    
$mftFileListingColumns = 'Drive', 'FullPath', 'Extension', 'FileSize', 'Created0x10', 'LastModified0x10'
$mftFileListingData = mftJoinSortAndSelectCsv -mftFiles $mftFileListingFiles -mftSortColumn 'Created0x10' -mftSelectColumns $mftFileListingColumns
$mftFileListingData | Where-Object { $_.FileSize -ne 0 } | Export-Csv -Path "$MFTPath\MFT.csv" -NoTypeInformation
    
$mftOutputColumns = 'Drive', 'ParentPath', 'Name', 'Extension', 'UpdateTimestamp', 'UpdateReasons'
$mftOutputData = mftJoinSortAndSelectCsv -mftFiles $mftOutputFiles -mftSortColumn 'UpdateTimestamp' -mftSelectColumns $mftOutputColumns
$mftOutputData | Export-Csv -Path "$MFTPath\Journal.csv" -NoTypeInformation
    
Write-Host "   Sorting USN Journal"-ForegroundColor yellow
Set-Location "$MFTPath"

Import-Csv "Journal.csv" | ForEach-Object {
    $FilePath = if ($_.ParentPath) {
        "$($_.Drive):$($_.ParentPath.TrimStart('.'))\$($_.Name)"
    }
    else {
        "$($_.Drive):\UNKNOWNPATH\$($_.Name)"
    }
    
    $FormattedTimestamp = [datetime]::Parse($_.UpdateTimestamp).ToString("yyyy-MM-dd HH:mm:ss")
    
    [PSCustomObject]@{
        UpdateTimestamp = $FormattedTimestamp
        FilePath        = $FilePath
        UpdateReasons   = $_.UpdateReasons
        Extension       = $_.Extension
    }
} | Export-Csv "C:\temp\dump\Journal\Raw\Journal.csv" -NoTypeInformation
    
Import-Csv "MFT.csv" | ForEach-Object {
    $FilePath = if ($_.FullPath) {
        "$($_.Drive):$($_.FullPath.TrimStart('.'))"
    }
    else {
        "$($_.Drive):\UNKNOWNPATH"
    }
    
    $FormattedTimestamp = [datetime]::Parse($_.Created0x10).ToString("yyyy-MM-dd HH:mm:ss")
    
    [PSCustomObject]@{
        CreatedTimestamp = $FormattedTimestamp
        FilePath         = $FilePath
        FileSize         = $_.FileSize
        Extension        = $_.Extension
        LastModified     = $_.LastModified0x10
    }
    
} | Sort-Object CreatedTimestamp -Descending | Export-Csv "C:\temp\dump\MFT\MFT2.csv" -NoTypeInformation
    
Remove-Item "C:\temp\dump\MFT\Journal.csv"
Remove-Item "C:\temp\dump\MFT\MFT.csv"
Rename-Item -Path "C:\temp\dump\MFT\MFT2.csv" -NewName "C:\temp\dump\MFT\MFT.csv"

Write-Host "   Filtering Journal"
Set-Location "C:\temp\dump\Journal"
$usnDump = Import-Csv "C:\temp\dump\Journal\Raw\Journal.csv"
$usnDump = $usnDump |
    Where-Object { $_.updatereasons -in @(
        "FileDelete|Close",
        "FileCreate",
        "DataTruncation",
        "DataOverwrite",
        "RenameNewName",
        "RenameOldName",
        "Close",
        "HardLinkChange",
        "SecurityChange",
        "DataExtend|DataTruncation"
    )} | Sort-Object -Property * -Unique
$usnDump | Where-Object { $_.Extension -in @('.exe', '.dll', '.zip', '.rar') } | Sort-Object -Property UpdateTimestamp -Descending | Export-Csv -Path "C:\temp\dump\Journal\Raw\Journal_Overview.csv" -NoTypeInformation
$usnDump | Where-Object { $_.'Extension' -eq ".exe" -and $_.'UpdateReasons' -match 'FileCreate' } | Select-Object 'FilePath', 'UpdateTimestamp' | Sort-Object 'UpdateTimestamp' -Descending -Unique | Out-String -Width 4096 | Format-Table -HideTableHeaders | Out-File CreatedFiles.txt -Append -Width 4096
$usnDump | Where-Object { $_.'Extension' -eq ".exe" -and $_.'UpdateReasons' -match 'FileDelete' } | Select-Object 'FilePath', 'UpdateTimestamp' | Sort-Object 'UpdateTimestamp' -Descending -Unique | Out-String -Width 4096 | Out-File DeletedFiles.txt -Append -Width 4096
$usnDump | Where-Object { $_.'UpdateReasons' -match 'RenameOldName' -or $_.'UpdateReasons' -match 'RenameNewName' } | Sort-Object 'UpdateTimestamp' -Descending | Group-Object "UpdateTimestamp" | Format-Table -AutoSize @{l = "Timestamp"; e = { $_.Name } }, @{l = "Old Name"; e = { Split-Path -Path $_.Group.'FilePath'[0] -Leaf } }, @{l = "New Name"; e = { Split-Path -Path $_.Group.'FilePath'[1] -Leaf } } | Out-File -FilePath Renamed_Files.txt -Append -Width 4096
$usnDump | Where-Object { $_.'Extension' -in ".rar", ".zip", ".7z" } | Select-Object 'FilePath', 'UpdateTimestamp' | Sort-Object 'UpdateTimestamp' -Descending -Unique | Out-File Compressed.txt -Append -Width 4096
$usnDump | Where-Object { $_.'UpdateReasons' -match "DataTruncation" -and $_.'Extension' -eq ".exe" } | Select-Object 'FilePath', 'UpdateTimestamp' | Sort-Object 'UpdateTimestamp' -Descending -Unique | Out-File ReplacedExe.txt -Append -Width 4096
$usnDump | Where-Object { $_.'FilePath' -match '\?' } | Select-Object 'FilePath', 'UpdateTimestamp' | Sort-Object 'UpdateTimestamp' -Descending -Unique | Out-File EmptyCharacter.txt -Append -Width 4096
