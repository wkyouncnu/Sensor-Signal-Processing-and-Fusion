# rename_top_folders.ps1 -- rename the two remaining top-level folders.
#
#   Proj_SHI_USV_MILS  ->  10_yeongu_USV_MILS  (Korean name below)
#   gangui-jaryo       ->  20_gangui-jaryo     (Korean name below)
#
# WHY THIS EXISTS
#
#   On 2026-09-04 every other top-level folder was renamed, but these two were
#   locked. No file inside them was locked -- only the directories themselves,
#   by a Claude Code project-folder watcher and by Dropbox. A reboot clears it.
#
# SAFETY
#
#   Renames only. Never deletes, moves or overwrites. Counts the files before
#   and after and shouts if the two differ. Skips a target that already exists.
#
# ENCODING
#
#   This file must stay UTF-8 WITH BOM. Windows PowerShell 5.1 reads a BOM-less
#   file as the ANSI codepage and mangles the Korean folder names into a parse
#   error. All messages are ASCII on purpose; only the folder names are Korean.
#
# USAGE
#
#   powershell -ExecutionPolicy Bypass -File _tools\rename_top_folders.ps1

$ErrorActionPreference = 'Stop'
$root = 'C:\Users\admin\Dropbox\센서신호처리및융합'

$targets = @(
    @{ from = 'Proj_SHI_USV_MILS'; to = '10_연구_USV_MILS' },
    @{ from = '강의자료';           to = '20_강의자료'      }
)

function Get-FileCount($p) {
    (Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object).Count
}

$blocked = 0
foreach ($t in $targets) {
    $src = Join-Path $root $t.from
    $dst = Join-Path $root $t.to

    if (Test-Path -LiteralPath $dst) { Write-Host ("already done : " + $t.to); continue }
    if (-not (Test-Path -LiteralPath $src)) { Write-Host ("not found    : " + $t.from); continue }

    $before = Get-FileCount $src
    try {
        Rename-Item -LiteralPath $src -NewName $t.to -ErrorAction Stop
    } catch {
        Write-Host ("BLOCKED      : {0}  ({1} files, left untouched)" -f $t.from, $before)
        $blocked++
        continue
    }

    $after = Get-FileCount $dst
    if ($after -eq $before) {
        Write-Host ("renamed      : {0} -> {1}   ({2} files, unchanged)" -f $t.from, $t.to, $after)
    } else {
        Write-Host ("WARNING      : {0} -> {1}   file count went {2} -> {3}" -f $t.from, $t.to, $before, $after)
        Write-Host  "               check the Recycle Bin and Dropbox 'deleted files'."
    }
}

Write-Host ""
Write-Host "top level now:"
Get-ChildItem -LiteralPath $root -Force | ForEach-Object { "  " + $_.Name }

if ($blocked -gt 0) { exit 1 }
exit 0
