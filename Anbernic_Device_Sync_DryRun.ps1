# ====== CONFIG ======
$deviceA = "\\KNULLI34XX\share"
$deviceB = "\\KNULLI35xxSP\share"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupRoot = Join-Path $scriptRoot "Save_Backups"  # Not used in dry run, just reserved
$logFile = Join-Path $scriptRoot "knulli_sync_log_dryrun.txt"

$excludedDirs = @("images", "manuals", "videos")
$excludedFiles = @("_info.txt", "gamelist.xml")
$foldersToSync = @("roms", "Bios")
# ====================

function Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] $message"
}

function ShouldExclude($item) {
    foreach ($dir in $excludedDirs) {
        if ($item.FullName -match "\\$dir(\\|$)") {
            return $true
        }
    }
    if ($excludedFiles -contains $item.Name) {
        return $true
    }
    return $false
}

function ReportMissingFiles($srcDir, $dstDir) {
    $files = Get-ChildItem -Path $srcDir -Recurse -Force -File | Where-Object { -not (ShouldExclude $_) }
    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($srcDir.TrimEnd('\').Length).TrimStart('\')
        $destPath = Join-Path $dstDir $relativePath
        if (-not (Test-Path $destPath)) {
            Write-Host "Would copy: $relativePath"
            Log "Would copy: $relativePath"
        }
    }
}

function ReportSaveDifferences($dirA, $dirB) {
    $savesA = Get-ChildItem -Path $dirA -Recurse -File
    $savesB = Get-ChildItem -Path $dirB -Recurse -File
    $allSaves = @{}

    foreach ($file in $savesA + $savesB) {
        $rel = $file.FullName.Substring($file.DirectoryName.Length).TrimStart('\')
        if (-not $allSaves.ContainsKey($rel)) {
            $allSaves[$rel] = @{}
        }

        if ($file.FullName.StartsWith($dirA)) {
            $allSaves[$rel]["A"] = $file
        } elseif ($file.FullName.StartsWith($dirB)) {
            $allSaves[$rel]["B"] = $file
        }
    }

    foreach ($relPath in $allSaves.Keys) {
        $entry = $allSaves[$relPath]
        $fileA = $entry["A"]
        $fileB = $entry["B"]

        if ($fileA -and -not $fileB) {
            Write-Host "Would copy save A → B: $relPath"
            Log "Would copy save A → B: $relPath"

        } elseif ($fileB -and -not $fileA) {
            Write-Host "Would copy save B → A: $relPath"
            Log "Would copy save B → A: $relPath"

        } elseif ($fileA -and $fileB) {
            if ($fileA.LastWriteTime -gt $fileB.LastWriteTime) {
                Write-Host "Would overwrite B with newer A: $relPath"
                Log "Would overwrite B with newer A: $relPath"
            } elseif ($fileB.LastWriteTime -gt $fileA.LastWriteTime) {
                Write-Host "Would overwrite A with newer B: $relPath"
                Log "Would overwrite A with newer B: $relPath"
            }
        }
    }
}

# ========== DRY RUN ==========
New-Item -ItemType Directory -Path $scriptRoot -Force | Out-Null
Log "==== Knulli DRY RUN started ===="

foreach ($folder in $foldersToSync) {
    Write-Host "`nChecking $folder folder..."
    Log "Checking $folder folder..."
    ReportMissingFiles -srcDir (Join-Path $deviceA $folder) -dstDir (Join-Path $deviceB $folder)
    ReportMissingFiles -srcDir (Join-Path $deviceB $folder) -dstDir (Join-Path $deviceA $folder)
}

Write-Host "`nChecking save differences (dry run)..."
Log "Checking save differences..."
ReportSaveDifferences -dirA (Join-Path $deviceA "saves") -dirB (Join-Path $deviceB "saves")

Log "==== Knulli DRY RUN completed ===="
Write-Host "`nDry run complete. Log written to $logFile"
