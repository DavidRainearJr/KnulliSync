# ====== CONFIG ======
$deviceA = "\\KNULLI34XX\share"
$deviceB = "\\KNULLI35xxSP\share"
$backupRoot = "D:\Knulli_Backups"
$logFile = Join-Path $backupRoot "knulli_sync_log.txt"
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

function CopyMissingFiles($srcDir, $dstDir) {
    $files = Get-ChildItem -Path $srcDir -Recurse -Force -File | Where-Object { -not (ShouldExclude $_) }
    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($srcDir.TrimEnd('\').Length).TrimStart('\')
        $destPath = Join-Path $dstDir $relativePath
        if (-not (Test-Path $destPath)) {
            New-Item -ItemType Directory -Path (Split-Path $destPath) -Force | Out-Null
            Copy-Item -Path $file.FullName -Destination $destPath
            Write-Host "Copied: $relativePath"
            Log "Copied: $relativePath"
        }
    }
}

function BackupFile($file, $relativePath) {
    $backupPath = Join-Path $backupRoot $relativePath
    New-Item -ItemType Directory -Path (Split-Path $backupPath) -Force | Out-Null
    Copy-Item -Path $file.FullName -Destination $backupPath -Force
    Log "Backed up before overwrite: $relativePath"
}

function SyncSaves($dirA, $dirB) {
    $savesA = Get-ChildItem -Path $dirA -Recurse -File
    $savesB = Get-ChildItem -Path $dirB -Recurse -File
    $allSaves = @{}

    foreach ($file in $savesA + $savesB) {
        $rel = $file.FullName.Substring($file.DirectoryName.Length).TrimStart('\')
        if (-not $allSaves.ContainsKey($rel)) {
            $allSaves[$rel] = @{}
        }
        $side = $file.FullName.StartsWith($dirA) ? "A" : "B"
        $allSaves[$rel][$side] = $file
    }

    foreach ($relPath in $allSaves.Keys) {
        $entry = $allSaves[$relPath]
        $fileA = $entry["A"]
        $fileB = $entry["B"]

        if ($fileA -and -not $fileB) {
            $dest = Join-Path $dirB $relPath
            New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
            BackupFile $fileA $relPath
            Copy-Item -Path $fileA.FullName -Destination $dest
            Write-Host "Synced save A → B: $relPath"
            Log "Synced save A → B: $relPath"

        } elseif ($fileB -and -not $fileA) {
            $dest = Join-Path $dirA $relPath
            New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
            BackupFile $fileB $relPath
            Copy-Item -Path $fileB.FullName -Destination $dest
            Write-Host "Synced save B → A: $relPath"
            Log "Synced save B → A: $relPath"

        } elseif ($fileA -and $fileB) {
            if ($fileA.LastWriteTime -gt $fileB.LastWriteTime) {
                BackupFile $fileB $relPath
                Copy-Item -Path $fileA.FullName -Destination $fileB.FullName -Force
                Write-Host "Updated save on B: $relPath"
                Log "Updated save on B: $relPath"
            } elseif ($fileB.LastWriteTime -gt $fileA.LastWriteTime) {
                BackupFile $fileA $relPath
                Copy-Item -Path $fileB.FullName -Destination $fileA.FullName -Force
                Write-Host "Updated save on A: $relPath"
                Log "Updated save on A: $relPath"
            }
        }
    }
}

# ========== START ==========
if (-not (Test-Path $backupRoot)) {
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
}

Log "==== Knulli sync started ===="

foreach ($folder in $foldersToSync) {
    Write-Host "`nSyncing $folder folder..."
    Log "Syncing $folder folder..."
    CopyMissingFiles -srcDir (Join-Path $deviceA $folder) -dstDir (Join-Path $deviceB $folder)
    CopyMissingFiles -srcDir (Join-Path $deviceB $folder) -dstDir (Join-Path $deviceA $folder)
}

Write-Host "`nSyncing saves with conflict resolution and backup..."
Log "Syncing saves with conflict resolution..."
SyncSaves -dirA (Join-Path $deviceA "saves") -dirB (Join-Path $deviceB "saves")

Log "==== Knulli sync completed ===="
Write-Host "`nDone. Log written to $logFile"
