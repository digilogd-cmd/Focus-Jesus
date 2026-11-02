# Moves FOCUS JESUS (and the Flutter SDK set up for it) from drive C: to
# E:\claude, then deletes the C: copies after checking the copy is complete.
# Run with move_to_e.bat (it bypasses the script execution policy for this
# one run only). Nothing is deleted without typing Y.

$ErrorActionPreference = 'Stop'
$Target = 'E:\claude'
$ProjectDest = Join-Path $Target 'focus-jesus'
$FlutterDest = Join-Path $Target 'flutter'

function Say($text, $color = 'Gray') { Write-Host $text -ForegroundColor $color }

function Test-FocusJesus($dir) {
    $pubspec = Join-Path $dir 'pubspec.yaml'
    (Test-Path $pubspec) -and ((Get-Content $pubspec -TotalCount 5) -match '^name:\s*focus_jesus')
}

# File count and total size under $dir, leaving out folders named in
# $exclude at any depth (the same rule robocopy /XD applies).
function Get-Stats($dir, $exclude) {
    $root = (Resolve-Path -LiteralPath $dir).Path.TrimEnd('\')
    $files = Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue
    if ($exclude) {
        $files = $files | Where-Object {
            $segments = $_.DirectoryName.Substring($root.Length) -split '\\'
            -not ($segments | Where-Object { $exclude -contains $_ })
        }
    }
    [pscustomobject]@{ Count = @($files).Count; Bytes = ($files | Measure-Object Length -Sum).Sum }
}

# Copies $src to $dest with robocopy (keeps timestamps), then compares file
# count and total size. Returns $true only when they match.
function Copy-Verified($src, $dest, $exclude) {
    # Excluded folders (build output) are regenerated, not copied.
    $copyArgs = @($src, $dest, '/E', '/COPY:DAT', '/R:1', '/W:1', '/NFL', '/NDL', '/NP')
    if ($exclude) { $copyArgs += '/XD'; $copyArgs += $exclude }
    & robocopy @copyArgs | Out-Null
    if ($LASTEXITCODE -ge 8) { Say "  robocopy failed (code $LASTEXITCODE)." 'Red'; return $false }
    $a = Get-Stats $src $exclude; $b = Get-Stats $dest $exclude
    Say ("  C: {0} files / {1:N0} bytes  ->  E: {2} files / {3:N0} bytes" -f $a.Count, $a.Bytes, $b.Count, $b.Bytes)
    return ($a.Count -eq $b.Count -and $a.Bytes -eq $b.Bytes)
}

Say '=== FOCUS JESUS: move from C: to E:\claude ===' 'Cyan'
if (-not (Test-Path 'E:\')) { Say 'Drive E: was not found. Nothing was changed.' 'Red'; exit 1 }
New-Item -ItemType Directory -Force -Path $Target | Out-Null

# 1. Find the project on C:.
$candidates = @('C:\dev\focus-jesus', 'C:\dev\Focus-Jesus', 'C:\focus-jesus',
    "$env:USERPROFILE\Downloads\focus-jesus", "$env:USERPROFILE\Desktop\focus-jesus",
    "$env:USERPROFILE\Documents\focus-jesus", "$env:USERPROFILE\Downloads\FOCUS-JESUS-local-1.5.0\focus-jesus")
$project = $candidates | Where-Object { Test-FocusJesus $_ } | Select-Object -First 1
$zip = Get-ChildItem "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop" -Filter 'FOCUS-JESUS-local-*.zip' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (Test-Path $ProjectDest) {
    Say "$ProjectDest already exists. Leaving it as it is (nothing overwritten)." 'Yellow'
} elseif ($project) {
    Say "Project found: $project"
    if (-not (Copy-Verified $project $ProjectDest @('build', '.dart_tool'))) {
        Say 'The copy does not match. C: is left untouched.' 'Red'; exit 1
    }
    Say "  Copied to $ProjectDest" 'Green'
} elseif ($zip) {
    Say "No project folder on C:. Unpacking $($zip.FullName)"
    Expand-Archive -LiteralPath $zip.FullName -DestinationPath $Target
    $project = $null
} else {
    Say 'No FOCUS JESUS folder or package zip was found on C:. Download the package and run again.' 'Red'
    exit 1
}
if (-not (Test-FocusJesus $ProjectDest)) { Say "Something is wrong: $ProjectDest has no focus_jesus pubspec." 'Red'; exit 1 }

# 2. The Flutter SDK, if it was installed under C:\dev as the guide said.
$flutterSrc = @('C:\dev\flutter', 'C:\flutter', 'C:\src\flutter') |
    Where-Object { Test-Path (Join-Path $_ 'bin\flutter.bat') } | Select-Object -First 1
$flutterMoved = $false
if ($flutterSrc -and -not (Test-Path $FlutterDest)) {
    Say "Flutter SDK found: $flutterSrc"
    if (Copy-Verified $flutterSrc $FlutterDest $null) {
        $flutterMoved = $true
        # Point the user PATH at the new location.
        $path = [Environment]::GetEnvironmentVariable('Path', 'User')
        $old = Join-Path $flutterSrc 'bin'
        $new = Join-Path $FlutterDest 'bin'
        $parts = @($path -split ';' | Where-Object { $_ -and ($_.TrimEnd('\') -ne $old.TrimEnd('\')) })
        if ($parts -notcontains $new) { $parts = @($new) + $parts }
        [Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User')
        $env:Path = "$new;$env:Path"
        Say "  Copied to $FlutterDest; user PATH now uses $new" 'Green'
    } else {
        Say '  The Flutter copy does not match. C: Flutter is kept.' 'Red'
    }
} elseif (Test-Path $FlutterDest) {
    Say "$FlutterDest already exists; Flutter not copied." 'Yellow'
}

# 3. Rebuild the machine-specific files in the new location.
Push-Location $ProjectDest
try {
    if (Test-Path 'android\local.properties') { Remove-Item 'android\local.properties' -Force }
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        Say 'Running flutter pub get in the new folder...'
        & flutter pub get
    } else {
        Say 'flutter is not on PATH yet; run scripts\windows\setup.bat after installing it.' 'Yellow'
    }
} finally { Pop-Location }

# 4. Delete the C: copies, only after confirmation.
$toDelete = @()
if ($project) { $toDelete += $project }
if ($flutterMoved) { $toDelete += $flutterSrc }
if ($toDelete.Count -gt 0) {
    Say ''
    Say 'Copies on E: are verified. These C: folders will be DELETED:' 'Yellow'
    $toDelete | ForEach-Object { Say "  $_" 'Yellow' }
    $answer = Read-Host 'Type Y to delete them (anything else keeps them)'
    if ($answer -eq 'Y' -or $answer -eq 'y') {
        foreach ($d in $toDelete) {
            try {
                Remove-Item -LiteralPath $d -Recurse -Force
                Say "  Deleted $d" 'Green'
            } catch {
                # Usually a file held open by VS Code, Android Studio or a
                # running Dart process. The E: copy is complete either way.
                Say "  Could not delete all of $d : $($_.Exception.Message)" 'Red'
                Say '  Close VS Code / Android Studio and delete it by hand.' 'Red'
            }
        }
        $parent = 'C:\dev'
        if ((Test-Path $parent) -and -not (Get-ChildItem $parent -Force)) {
            Remove-Item $parent -Force; Say "  Deleted empty $parent" 'Green'
        }
    } else {
        Say 'Kept the C: folders.' 'Yellow'
    }
}

Say ''
Say "Done. Project: $ProjectDest" 'Cyan'
Say 'Open a NEW command prompt (PATH changes apply there), then run:' 'Cyan'
Say "  $ProjectDest\scripts\windows\setup.bat" 'Cyan'
