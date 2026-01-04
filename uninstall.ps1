<#
.SYNOPSIS
    Uninstalls CapsLang - removes keyboard layout switcher utility.

.DESCRIPTION
    Removes CapsLang from the system, cleaning up:
    - Startup folder shortcut (if installed)
    - Scheduled task (if created)
    - Installation directory

.EXAMPLE
    .\uninstall.ps1
    Interactive uninstallation

.EXAMPLE
    .\uninstall.ps1 -Quiet
    Silent uninstallation
#>
param(
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

$STARTUP_PATH = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\CapsLang.lnk"
$TASK_NAME = "CapsLang"
$INSTALL_DIR = "$env:LOCALAPPDATA\capslang"

function Write-Banner {
    Write-Host "`n  CapsLang Uninstaller" -ForegroundColor Cyan
    Write-Host "  ===================" -ForegroundColor Cyan
}

function Remove-StartupFolder {
    Write-Host "Removing from Startup folder..." -ForegroundColor Yellow

    if (-not (Test-Path $STARTUP_PATH)) {
        Write-Host "  Not found in Startup folder" -ForegroundColor Gray
        return $false
    }

    try {
        Remove-Item $STARTUP_PATH -Force
        if (-not (Test-Path $STARTUP_PATH)) {
            Write-Host "  Removed: $STARTUP_PATH" -ForegroundColor Green
            return $true
        }
        Write-Host "  Failed to remove" -ForegroundColor Red
        return $false
    } catch {
        Write-Host "  Failed to remove: $_" -ForegroundColor Red
        return $false
    }
}

function Remove-ScheduledTask {
    Write-Host "Removing scheduled task..." -ForegroundColor Yellow

    schtasks /Delete /TN $TASK_NAME /F 2>$null | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Removed task: $TASK_NAME" -ForegroundColor Green
        return $true
    }

    Write-Host "  Task not found" -ForegroundColor Gray
    return $false
}

function Remove-InstallDir {
    Write-Host "Removing installation directory..." -ForegroundColor Yellow

    if (-not (Test-Path $INSTALL_DIR)) {
        Write-Host "  Not found" -ForegroundColor Gray
        return $false
    }

    try {
        Remove-Item $INSTALL_DIR -Recurse -Force
        if (-not (Test-Path $INSTALL_DIR)) {
            Write-Host "  Removed: $INSTALL_DIR" -ForegroundColor Green
            return $true
        }
        Write-Host "  Failed to remove" -ForegroundColor Red
        return $false
    } catch {
        Write-Host "  Failed to remove: $_" -ForegroundColor Red
        return $false
    }
}

function Uninstall-CapsLang {
    param([switch]$Quiet)

    Write-Banner

    $removed = $false
    $removed = Remove-StartupFolder -or $removed
    $removed = Remove-ScheduledTask -or $removed
    $removed = Remove-InstallDir -or $removed

    Write-Host ""

    if ($removed) {
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  Uninstallation complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  CapsLang has been removed from your system." -ForegroundColor White
    } else {
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "  CapsLang was not found" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  CapsLang is not installed on this system." -ForegroundColor White
    }

    Write-Host ""

    if (-not $Quiet) {
        Write-Host "Press Enter to exit..." -ForegroundColor Yellow
        Read-Host
    }
}

Uninstall-CapsLang -Quiet:$Quiet
