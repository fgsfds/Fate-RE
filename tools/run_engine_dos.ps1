# Compatibility entry point; production leaf builds use the shared Python manifest.
param([ValidateSet('105', '106')][string]$Version = '106', [switch]$Leaves, [switch]$Cache,
      [ValidatePattern('^[A-Za-z0-9_-]+$')][string]$ScratchName = "dos$Version",
      [string]$CompilerDirectory, [string]$DosboxDirectory,
      [string[]]$Objects, [switch]$Incremental, [string]$Python = 'python')
$ErrorActionPreference = 'Stop'
if ($Leaves -and $Cache) { throw 'Choose either -Leaves or -Cache.' }
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$scratch = Join-Path $repo "work\$ScratchName"
if ($Leaves) {
    $arguments = @((Join-Path $PSScriptRoot 'restoration_build.py'), $scratch, '--version', $Version)
    if ($CompilerDirectory) { $arguments += @('--compiler', $CompilerDirectory) }
    if ($DosboxDirectory) { $arguments += @('--dosbox', (Join-Path $DosboxDirectory 'DOSBox.exe')) }
    if ($Objects) { $arguments += @('--objects') + $Objects }
    if ($Incremental) { $arguments += '--incremental' }
    & $Python @arguments
    if ($LASTEXITCODE -ne 0) { throw 'Restoration compilation failed; inspect the reported log.' }
    return
}
if ($Objects -or $Incremental) { throw '-Objects and -Incremental require -Leaves.' }

# Historical whole-engine/cache research, not the exact executable build.
$compilerFolder = if ($Version -eq '105') { 'watcom105-recovered' } else { 'watcom106' }
$compilerHash = if ($Version -eq '105') {
    '1b97a68f7b8a3efd89b05f64ce99836b1e533f398699305f96dc423254939d6a'
} else {
    'a257b6a25a95f02b404c4571839297af0a8cd941479f4dd19149ea949fd88c42'
}
if (-not $CompilerDirectory) { $CompilerDirectory = Join-Path $repo "reference/$compilerFolder/binw" }
if (-not $DosboxDirectory) { $DosboxDirectory = Join-Path $repo 'reference/dosbox' }
$dosbox = Join-Path $DosboxDirectory 'DOSBox.exe'
$pinnedTools = @{
    (Join-Path $CompilerDirectory 'wcc386.exe') = $compilerHash
    (Join-Path $CompilerDirectory 'w32run.exe') = 'f3b2864d171319728baaf95c1188e7b98d5b9ce2bb13768b5272e3ec5c94f4f4'
    $dosbox = 'dcfd46fa521f5ce89dce3bf026056f3a1d15533f80321ee887403e30d7949f5e'
}
foreach ($tool in $pinnedTools.GetEnumerator()) {
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $tool.Key).Hash -ne $tool.Value) {
        throw "Tool hash mismatch: $($tool.Key)"
    }
}
New-Item -ItemType Directory -Force $scratch | Out-Null
foreach ($name in @('wcc386.exe', 'w32run.exe')) {
    Copy-Item (Join-Path $CompilerDirectory $name) $scratch -Force
}
$headerFolder = if ($Version -eq '105') { 'watcom105-full' } else { 'watcom110c' }
$headerName = if ($Version -eq '105') { 'h105' } else { 'h110c' }
foreach ($name in @('ENGINE.C', 'BUILD.H', 'PRAGMAS.H', 'VES2.H')) {
    Copy-Item (Join-Path $repo "reference\build\$name") $scratch -Force
}
New-Item -ItemType Directory -Force (Join-Path $scratch $headerName) | Out-Null
Copy-Item (Join-Path $repo "reference\$headerFolder\h\*") (Join-Path $scratch $headerName) -Recurse -Force
$commands = @('@echo off', 'set WATCOM=C:\', "set INCLUDE=C:\$headerName")
if ($Cache) {
    Copy-Item (Join-Path $repo 'reference\build\CACHE1D.C') $scratch -Force
    $source = 'cache1d'
    $revisions = [ordered]@{cache95='19951025'; cache963='19960319'; cache969='19960925'}
} else {
    $source = 'engine'
    $revisions = [ordered]@{eng9510='19951025'; eng9603='19960305'; eng96320='19960320'}
}
foreach ($item in $revisions.GetEnumerator()) {
    $short = $item.Key
    $commands += "wcc386 $source.c /4r /s /or /bt=dos /dLIBVER_BUILDREV=$($item.Value) /fo=$short.obj > $short.log"
    $commands += 'if errorlevel 1 goto failed'
}
$commands += @('echo PASS > matrix.txt', 'goto done', ':failed', 'echo FAIL > matrix.txt', ':done')
($commands -join "`r`n") | Set-Content -Encoding ascii (Join-Path $scratch 'engine.bat')
$config = Join-Path $scratch 'engine.conf'
@"
[sdl]
fullscreen=false
output=surface
[dosbox]
memsize=31
[cpu]
core=dynamic
cycles=max
[mixer]
nosound=true
[midi]
mpu401=none
[autoexec]
mount c "$scratch"
c:
call engine.bat
exit
"@ | Set-Content -Encoding ascii $config
'PENDING' | Set-Content -Encoding ascii (Join-Path $scratch 'matrix.txt')
$oldVideo, $oldAudio = $env:SDL_VIDEODRIVER, $env:SDL_AUDIODRIVER
try {
    $env:SDL_VIDEODRIVER = 'dummy'
    $env:SDL_AUDIODRIVER = 'dummy'
    $process = Start-Process -FilePath $dosbox -ArgumentList '-conf', "`"$config`"", '-noconsole' -WorkingDirectory $scratch -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(180000)) {
        $process.Kill()
        throw 'Compiler matrix exceeded three minutes; inspect scratch logs.'
    }
    if ($process.ExitCode -ne 0 -or (Get-Content (Join-Path $scratch 'matrix.txt') -Raw).Trim() -ne 'PASS') {
        throw 'Compiler matrix failed; inspect scratch logs.'
    }
    foreach ($log in $revisions.Keys) { Get-Content (Join-Path $scratch "$log.log") -Tail 4 }
} finally {
    $env:SDL_VIDEODRIVER, $env:SDL_AUDIODRIVER = $oldVideo, $oldAudio
}
