<#
.SYNOPSIS
    Installs CapsLang - a Windows utility that switches keyboard layout with CapsLock key.

.DESCRIPTION
    This script downloads the latest CapsLang release from GitHub and installs it
    using either the Startup folder or Scheduled Task method.

.PARAMETER Method
    Installation method: 1 = Startup folder (user only), 2 = Scheduled task (admin).

.PARAMETER Quiet
    Run without interactive prompts (use default options).

.EXAMPLE
    .\install.ps1
    Interactive installation with prompts

.EXAMPLE
    .\install.ps1 -Method 2 -Quiet
    Install using scheduled task silently
#>
param(
    [ValidateSet(1, 2)][int]$Method = 2,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

$REPO_OWNER = "edanko"
$REPO_NAME = "capslang"
$GITHUB_API = "https://api.github.com"

function Write-Banner {
    Write-Host "CapsLang Installer" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
}

function Get-LatestVersion {
    Write-Host "`nFetching latest release..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$GITHUB_API/repos/$REPO_OWNER/$REPO_NAME/releases/latest" `
            -Headers @{ "Accept" = "application/vnd.github+json" }
        return $response.tag_name
    } catch {
        Write-Error "Failed to fetch latest release: $_"
        exit 1
    }
}

function Select-Method {
    param([int]$DefaultMethod)

    Write-Host "`nInstallation method:" -ForegroundColor Yellow
    Write-Host "  1. Startup folder (user only, no admin required)"
    Write-Host "     - CapsLang runs when you log in"
    Write-Host "     - Limited to your user account"
    Write-Host "  2. Scheduled task (admin privileges - recommended)"
    Write-Host "     - CapsLang runs with highest privileges"
    Write-Host "     - Works in all applications including admin apps"
    Write-Host ""

    if ($Quiet) {
        return $DefaultMethod
    }

    $selected = Read-Host "Select (1-2) [$DefaultMethod]"
    if ($selected -eq "") { $selected = $DefaultMethod }

    if ($selected -notmatch '^[12]$') {
        Write-Error "Invalid selection"
        exit 1
    }

    return [int]$selected
}

function Install-StartupFolder {
    param([string]$ExePath)

    $shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\CapsLang.lnk"

    Write-Host "Creating startup shortcut..." -ForegroundColor Yellow
    try {
        $ws = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcutPath)
        $ws.TargetPath = $ExePath
        $ws.WorkingDirectory = (Get-Item $ExePath).Directory.FullName
        $ws.Save()
        Write-Host "  Created: $shortcutPath" -ForegroundColor Green
    } catch {
        Write-Error "Failed to create shortcut: $_"
        exit 1
    }
}

function Install-ScheduledTask {
    param([string]$ExePath)

    $taskName = "CapsLang"
    $absPath = (Get-Item $ExePath).FullName

    Write-Host "Creating scheduled task..." -ForegroundColor Yellow

    schtasks /delete /tn $taskName /f 2>$null | Out-Null

    $result = schtasks /create `
        /tn $taskName `
        /sc ONLOGON `
        /tr "`"$absPath`"" `
        /rl HIGHEST `
        /delay 0000:30 `
        /f

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create scheduled task (exit code: $LASTEXITCODE)"
        exit 1
    }

    Write-Host "  Created task: $taskName" -ForegroundColor Green
    Write-Host "  Runs with: Highest privileges" -ForegroundColor Green
    Write-Host "  Trigger: On user logon (30s delay)" -ForegroundColor Green
}

function Install-CapsLang {
    param(
        [int]$Method
    )

    Write-Banner

    $version = Get-LatestVersion
    Write-Host "`nVersion: $version" -ForegroundColor Yellow

    if ($Method -eq 0) {
        $Method = Select-Method -DefaultMethod 2
    }

    $downloadUrl = "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$version/capslang-windows-x86_64.zip"
    $tempZip = [System.IO.Path]::GetTempFileName() + ".zip"
    $installDir = "$env:LOCALAPPDATA\capslang"

    Write-Host "`nDownloading..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing
        Write-Host "  Downloaded: $tempZip" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download: $_"
        exit 1
    }

    Write-Host "Extracting..." -ForegroundColor Yellow
    try {
        if (Test-Path $installDir) {
            Remove-Item -Recurse -Force $installDir
        }
        New-Item -ItemType Directory -Force -Path $installDir | Out-Null

        Expand-Archive -Path $tempZip -DestinationPath $installDir -Force
        Write-Host "  Extracted to: $installDir" -ForegroundColor Green
    } catch {
        Write-Error "Failed to extract: $_"
        exit 1
    }

    $exePath = "$installDir\capslang.exe"
    if (-not (Test-Path $exePath)) {
        Write-Error "Executable not found after extraction"
        exit 1
    }

    Write-Host "`nInstalling..." -ForegroundColor Yellow
    switch ($Method) {
        1 { Install-StartupFolder -ExePath $exePath }
        2 { Install-ScheduledTask -ExePath $exePath }
    }

    Remove-Item $tempZip -Force 2>$null | Out-Null

    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  Installation complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Exit CapsLang: Ctrl + Alt + L" -ForegroundColor White
    Write-Host ""

    if (-not $Quiet) {
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        [Console]::ReadKey($true) | Out-Null
    }
}

Install-CapsLang -Method $Method
