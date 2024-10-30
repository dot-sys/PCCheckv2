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

$port = 8080
$webroot = "C:\temp\dump"
$timeoutHours = 2
$startTime = Get-Date

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

while ($listener.IsListening) {
    if ((Get-Date) -gt $startTime.AddHours($timeoutHours)) {
        $listener.Stop()
        break
    }
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $relativePath = ($request.Url.AbsolutePath -replace '/', '\').TrimStart('\')
    $localPath = Join-Path $webroot $relativePath

    if (Test-Path $localPath) {
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        
        $extension = [System.IO.Path]::GetExtension($localPath).ToLower()
        
        switch ($extension) {
            '.html' { $response.ContentType = "text/html" }
            '.csv' { $response.ContentType = "text/csv" }
            default { $response.ContentType = "application/octet-stream" }
        }
        
        $content = Get-Content $localPath -Raw
        $buffer = [Text.Encoding]::UTF8.GetBytes($content)
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    } else {
        $response.StatusCode = 404
        $errorMessage = "File not found: $relativePath"
        $buffer = [Text.Encoding]::UTF8.GetBytes($errorMessage)
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    }
    $response.Close()
}

$listener.Stop()
