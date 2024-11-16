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
# 16 - November - 2024

$ErrorActionPreference = "SilentlyContinue"
$MFTPath = "C:\temp\dump\MFT"
Set-Location "$MFTPath"

Write-Host "   Dumping"
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
$mftCsvFiles = Get-ChildItem -Path $mftFolderPath -Filter *.csv | Where-Object { $_.Name -notlike "*MFT_Output.csv" }

Write-Host "   Prefilter (split, then pick extensions)"
$mftFilteredData = [System.Collections.Generic.List[string]]::new()
$extensionPattern = [regex]::new('\.(exe|rar|zip|identifier|rpf|dll)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$cutoffDate = (Get-Date).AddMonths(-6).ToString("yyyy-MM-dd HH:mm:ss") + ".0000000"

foreach ($mftFile in $mftCsvFiles) {
    $lines = Get-Content -Path $mftFile.FullName -ReadCount 0
    $header = $lines[0] -split ','
    $extensionIndex = [Array]::IndexOf($header, 'Extension')
    $createdDateIndex = [Array]::IndexOf($header, 'Created0x10')

    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i] -split ','

        $createdDate = $line[$createdDateIndex]
        if ($createdDate -lt $cutoffDate) {
            continue
        }

        if ($extensionPattern.IsMatch($line[$extensionIndex])) {
            $mftFilteredData.Add($line -join ',')
        }
    }

    if ($mftFilteredData.Count -gt 0) {
        $mftOutputFile = Join-Path -Path $mftFolderPath -ChildPath "$($mftFile.BaseName)_filtered.csv"
        $header -join ',' | Out-File -FilePath $mftOutputFile -Encoding UTF8
        $mftFilteredData | Out-File -FilePath $mftOutputFile -Append -Encoding UTF8
        $mftFilteredData.Clear()
    }
}

Write-Host "   Sizefilter"

$FilesizeL = 2000000
Get-ChildItem "C:\Temp\Dump\MFT\Raw" -Filter "*FileListing_filtered.csv" |
ForEach-Object {
    $csvData = Import-Csv $_.FullName
    Write-Host "Processing file: $($_.FullName)"
    $filteredData = $csvData |
        Where-Object { 
            [int]$_.FileSize -ge $FilesizeL -and $_.IsDirectory -ne "TRUE"
        }

    Write-Host "Filtered records count: $($filteredData.Count)"
    
    $filteredData |
    ForEach-Object {
        $FormattedTimestamp = [datetime]::Parse($_.Created0x10).ToString("yyyy-MM-dd HH:mm:ss")
        $FormattedLastModified = [datetime]::Parse($_.LastModified0x10).ToString("yyyy-MM-dd HH:mm:ss")

        [PSCustomObject]@{
            CreatedTimestamp = $FormattedTimestamp
            FilePath         = $_.FullPath
            FileSize         = $_.FileSize
            Extension        = $_.Extension
            LastModified     = $FormattedLastModified
        }
    } |
    Sort-Object CreatedTimestamp -Descending |
    Export-Csv $_.FullName -NoTypeInformation
}

Write-Host "   Move Items"
Get-ChildItem -Path "C:\temp\dump\mft\raw" -Recurse -Filter "*_Filtered.csv" | 
    Move-Item -Destination "C:\temp\dump\mft\Filtered"

Write-Host "   Drive Column"
$folderPath = "C:\Temp\Dump\MFT\Filtered"

function Get-DriveLetter {
    param ($fileBaseName)
    return "$($fileBaseName[0]):"
}

function ProcessJOutput {
    param ($reader, $writer, $driveLetter)

    $header = $reader.ReadLine()
    $headerColumns = $header -split ','

    $updateTimestampIndex = $headerColumns.IndexOf("UpdateTimestamp")
    $parentPathIndex = $headerColumns.IndexOf("ParentPath")
    $updateReasonsIndex = $headerColumns.IndexOf("UpdateReasons")
    $extensionIndex = $headerColumns.IndexOf("Extension")
    $nameIndex = $headerColumns.IndexOf("Name")

    $newHeader = "UpdateTimestamp,FullPath,UpdateReasons,Extension"
    $writer.WriteLine($newHeader)

    while ($line = $reader.ReadLine()) {
        $columns = $line -split ','

        if ($parentPathIndex -ge 0 -and $nameIndex -ge 0) {
            $fullPath = $driveLetter + ($columns[$parentPathIndex] -replace '^\.', '') + "\" + $columns[$nameIndex]
            $filteredColumns = @(
                $columns[$updateTimestampIndex],
                $fullPath,
                $columns[$updateReasonsIndex],
                $columns[$extensionIndex]
            )
            $writer.WriteLine(($filteredColumns -join ','))
        }
    }
}

$csvFiles = Get-ChildItem -Path $folderPath -Filter *csv

    foreach ($csvFile in $csvFiles) {
        $csvFilePath = $csvFile.FullName
        $tempFilePath = [System.IO.Path]::GetTempFileName()
        $driveLetter = Get-DriveLetter -fileBaseName $csvFile.BaseName

        try {
            $reader = [System.IO.StreamReader]::new($csvFilePath)
            $writer = [System.IO.StreamWriter]::new($tempFilePath, $false)

            if ($csvFile.BaseName -match "FileListing_filtered") {
                ProcessFileListing -reader $reader -writer $writer -driveLetter $driveLetter
            }
            elseif ($csvFile.BaseName -match "J_Output_filtered") {
                ProcessJOutput -reader $reader -writer $writer -driveLetter $driveLetter
            }

            $reader.Dispose()
            $writer.Dispose()

            Remove-Item -Path $csvFilePath -Force
            Move-Item -Path $tempFilePath -Destination $csvFilePath

        } catch {
            Write-Error "Failed to process file ${csvFilePath}: $_"
            if (Test-Path $tempFilePath) { Remove-Item -Path $tempFilePath -Force }
        }
    }

Get-ChildItem -Path "C:\temp\dump\MFT\Filtered" -Filter "*Filelisting_Filtered.csv" | ForEach-Object {
    $DriveLetter = ($_.Name.Substring(0, 1)) + ":"
    Import-Csv $_.FullName | ForEach-Object {
        $FilePath = if ($_.FilePath) {
            "$DriveLetter\$($_.FilePath.TrimStart('.\'))"
        }
        else {
            "$DriveLetter\UNKNOWNPATH"
        }
        
        [PSCustomObject]@{
            CreatedTimestamp = $_.CreatedTimestamp
            FilePath         = $FilePath
            FileSize         = $_.FileSize
            Extension        = $_.Extension
            LastModified     = $_.LastModified
        }
    }
} | Sort-Object CreatedTimestamp -Descending | Export-Csv "C:\temp\dump\MFT\MFT.csv" -NoTypeInformation -Append

Write-Host "   Merge Journal"
Get-ChildItem -Path "C:\temp\dump\MFT\Filtered" -Filter "*J_Output_filtered.csv" | 
    Get-Content | 
    Set-Content -Path "C:\temp\dump\journal\Raw\Journal.csv"

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
