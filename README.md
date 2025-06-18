# KnulliSync

**KnulliSync** is a PowerShell-based tool for syncing ROMs, BIOS, and save files between two handheld devices running the [Knulli](https://github.com/knulliwulf/knulli) firmware (e.g. Anbernic RG35XX SP, RG35XX H, or similar).

It automatically:
- Copies missing ROMs and BIOS files in both directions
- Moves and updates the most recent save files across devices
- Backs up any overwritten saves
- Skips unnecessary subfolders like `images`, `manuals`, and `videos`
- Keeps a clean, timestamped log of sync activity

---

## 🔧 Requirements

- Two devices running Knulli with network sharing enabled
- PowerShell **7.0 or later** (PowerShell 5.1 is not supported) -> https://github.com/PowerShell/PowerShell/releases
- Both devices must be accessible on the same local network

---

## 🛠 Setup Instructions

1. **On both Knulli devices:**
   - Press **Start** on the main menu
   - Go to **Network Settings**
   - Change the **HOSTNAME** to a unique name (e.g., `KNULLI34XX`, `KNULLI35XXSP`)
   - Reboot to apply

2. **Edit the script:**
   - At the top of `knulli_sync.ps1` and `knulli_sync_dryrun.ps1`, set your device hostnames:
     ```powershell
     $deviceA = "\\KNULLI34XX\share"
     $deviceB = "\\KNULLI35xxSP\share"
     ```

3. **Run the script:**
   - Open PowerShell 7
   - Navigate to the folder with the script
   - Run:
     ```powershell
     Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
     .\knulli_sync.ps1
     ```
   - For a test without making changes, use:
     ```powershell
     .\knulli_sync_dryrun.ps1
     ```

---

## 📂 Output

- Logs are written to the folder where the script is run:
  - `knulli_sync_log.txt`
  - `knulli_sync_log_dryrun.txt` (for dry runs)
- Save file backups are placed in a `Save_Backups` subfolder in the same location.

---

## 🚫 Exclusions

The script will **not** copy:
- Any folders named `images`, `manuals`, or `videos` (under any console directory)
- Files named `_info.txt` or `gamelist.xml`
- ROMs or saves already present with matching timestamps

---

## ✅ Features

- Two-way sync for `roms`, `Bios`, and `saves`
- Automatic conflict resolution for save files (based on last modified time)
- Safe, structured backups of save files before overwriting
- Clean and readable logs for tracking sync activity
- Designed with Anbernic devices and Knulli firmware in mind, but expandable to others (e.g. Batocera)

---

## 🔐 License

MIT License — free to use, modify, and share. See `LICENSE` file for details.

---

## 📬 Contributions & Feedback

Feel free to open issues or submit pull requests. If you’re using this with Batocera or other systems, share your setup so we can expand compatibility.
