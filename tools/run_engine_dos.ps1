# Compile controlled source branches under DOSBox, with only scratch files mounted.
param([ValidateSet('105', '106')][string]$Version = '106', [switch]$Leaves, [switch]$Cache,
      [ValidatePattern('^[A-Za-z0-9_-]+$')][string]$ScratchName = "dos$Version",
      [string]$CompilerDirectory, [string]$DosboxDirectory)
$ErrorActionPreference = 'Stop'
if ($Leaves -and $Cache) { throw 'Choose either -Leaves or -Cache.' }
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$scratch = Join-Path $repo "work\$ScratchName"
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
if (-not $Leaves) {
    foreach ($name in @('ENGINE.C', 'BUILD.H', 'PRAGMAS.H', 'VES2.H')) {
        Copy-Item (Join-Path $repo "reference\build\$name") $scratch -Force
    }
    New-Item -ItemType Directory -Force (Join-Path $scratch $headerName) | Out-Null
    Copy-Item (Join-Path $repo "reference\$headerFolder\h\*") (Join-Path $scratch $headerName) -Recurse -Force
}
$batch = @'
@echo off
set WATCOM=C:\
set INCLUDE=C:\@HEADER@
wcc386 engine.c /4r /s /or /bt=dos /dLIBVER_BUILDREV=19951025 /fo=eng9510.obj > eng9510.log
if errorlevel 1 goto failed
wcc386 engine.c /4r /s /or /bt=dos /dLIBVER_BUILDREV=19960305 /fo=eng9603.obj > eng9603.log
if errorlevel 1 goto failed
wcc386 engine.c /4r /s /or /bt=dos /dLIBVER_BUILDREV=19960320 /fo=eng96320.obj > eng96320.log
if errorlevel 1 goto failed
echo PASS > matrix.txt
goto done
:failed
echo FAIL > matrix.txt
:done
'@
$logs = @('eng9510', 'eng9603', 'eng96320')
if ($Leaves) {
    $names = [ordered]@{
        'engine/krand' = 'krand'
        'engine/spriteinsert' = 'insert'
        'engine/clipinsidebox' = 'clbox'
        'engine/clipinsideboxline' = 'clipline'
        'engine/inside' = 'inside'
        'engine/animateoffs' = 'animate'
        'engine/getmousevalues' = 'mouse'
        'engine/lastwall' = 'lastwall'
        'engine/spritewallfront' = 'sprfront'
        'engine/updatesector' = 'updsect'
        'engine/alignslopes' = 'slopes'
        'engine/allocatepermanenttile' = 'alloctil'
        'cache/agecache' = 'agecache'
        'cache/allocache' = 'allocach'
        'cache/initcache' = 'initcach'
        'cache/messages' = 'cachemsg'
        'cache/messages_const' = 'cachecon'
        'cache/klseek' = 'klseek'
        'cache/kfilelength' = 'kfilelen'
        'cache/kclose' = 'kclose'
        'engine/pixels' = 'pixels'
        'cache/uninitgroupfile' = 'uninitgr'
        'cache/kopen4load' = 'kopen4'
        'cache/kread' = 'kread'
        'cache/initgroupfile' = 'initgr'
        'cache/reportandexit' = 'report'
        'engine/editor16' = 'editor16'
        'engine/clippoly4' = 'clippoly'
        'cache/cacheprefix' = 'cacheprf'
        'cache/cachelayout' = 'cachelay'
        'cache/cacheunit' = 'cacheunt'
        'fate/remove_listed_sprite' = 'remove'
        'fate/add_listed_sprite' = 'add'
        'fate/move_listed_sprite' = 'movelist'
        'engine/stereo' = 'stereo'
        'network/initcrc' = 'initcrc'
        'network/convalloc32' = 'convallo'
        'network/uninstallbicomhandlers' = 'uninstbc'
        'engine/raytrace' = 'raytrace'
        'engine/clipadd' = 'clipadd'
        'engine/ceilscan' = 'ceilscan'
        'engine/ceilspr' = 'ceilspr'
        'fate/advance_sequences' = 'advance'
        'fate/append_sprite_event' = 'event'
        'fate/start_sequence' = 'startseq' # Research candidate, excluded from exact inventory.
        'fate/melee_trigger' = 'melee'
        'fate/activate_crush_sector' = 'crushact' # Unmatched research candidate.
        'fate/crush_dispatch' = 'crdisp'
        'fate/interpolation' = 'interp'
        'fate/interpolation_draw' = 'intdraw'
        'fate/interpolation_restore' = 'intrest'
        'fate/update_audio' = 'updaudio'
        'fate/audio_volume' = 'avol'
        'fate/dispatch_presentation' = 'dispres'
        'fate/presentation_group' = 'presgrp'
        'fate/animation' = 'anim'
        'fate/advance_animation' = 'animstep'
        'fate/animation_prestep' = 'prestep'
        'fate/animation_defaults' = 'animdefs'
        'fate/mouse_defaults' = 'mousedef'
        'engine/spritechange' = 'sprchang'
        'engine/spritelists' = 'sprlists'
        'engine/loadtables' = 'loadtabl'
        'engine/ksqrt' = 'ksqrt'
        'engine/getangle' = 'getangle'
        'fate/presentation_input' = 'presinp'
        'fate/dispatch_timing' = 'distime'
        'fate/dispatcher' = 'dispatch'
        'fate/init_crush_bank' = 'crushini'
        'fate/game_loop' = 'gameloop'
        'fate/is_crush_sector' = 'crushchk'
        'fate/clear_crush_bank' = 'crushclr'
        'fate/init_object_sequences' = 'initseq'
        'fate/select_map' = 'selmap'
        'fate/shutdown' = 'shutdown'
        'fate/frame_prefix' = 'frameprf'
        'fate/frame_group' = 'framegrp' # Rejected larger compiler-group candidate.
        'fate/startup_strings' = 'maintext'
        'fate/main' = 'fatemain'
        'fate/main_cleanup' = 'maincln'
        'fate/startup_group' = 'startgrp'
        'fate/nearby_force_constants' = 'forcecon'
        'fate/apply_nearby_force' = 'force' # Unmatched research candidate.
        'network/installbicomhandlers' = 'instbico'
        'network/getcrc' = 'getcrc'
        'network/comsend' = 'comsend'
        'network/startcom' = 'startcom'
        'network/comhandler' = 'comhandl'
        'network/simulateint' = 'simint'
        'network/defaults' = 'netdefs'
        'network/netinitconnection' = 'netinitc'
        'network/netuninitconnection' = 'netuninc'
        'fate/lookup_type_index' = 'type'
        'engine/transcol' = 'transcol'
        'engine/pallook' = 'pallook'
        'fate/record_lookups' = 'reclook'
        'fate/spawn_template_sprite' = 'spawn'
        'fate/lookup_record_value' = 'lookup'
    }
    Copy-Item (Join-Path $repo 'src/fate/copybuf.h') (Join-Path $scratch 'copybuf.h') -Force
    $includes = [ordered]@{
        'engine/ceilhl' = 'ceilhl'
        'cache/globals' = 'cacheglo'
        'cache/messages_const' = 'msgconst'
        'engine/drawline256' = 'line256'
        'engine/drawline16' = 'line16'
        'engine/lines' = 'lines'
        'engine/modes16' = 'modes16'
        'engine/clear2dscreen' = 'clear2d'
        'engine/draw2dgrid' = 'grid2d'
    }
    foreach ($item in $includes.GetEnumerator()) {
        Copy-Item (Join-Path $repo "src\$($item.Key).c") (Join-Path $scratch "$($item.Value).c") -Force
    }
    $commands = @('@echo off', 'set WATCOM=C:\')
    foreach ($item in $names.GetEnumerator()) {
        Copy-Item (Join-Path $repo "src\$($item.Key).c") (Join-Path $scratch "$($item.Value).c") -Force
        $short = $item.Value
        $defines = if ($short -in @('editor16', 'cacheprf', 'cachelay', 'cachecon', 'cacheunt', 'startgrp', 'frameprf', 'framegrp', 'presgrp')) { ' /dFATE_DOS_SHORT_NAMES' } else { '' }
        $commands += "wcc386 $short.c /4r /s /or /bt=dos$defines /fo=$short.obj > $short.log"
        $commands += 'if errorlevel 1 goto failed'
    }
    $commands += @('echo PASS > matrix.txt', 'goto done', ':failed', 'echo FAIL > matrix.txt', ':done')
    $batch = $commands -join "`r`n"
    $logs = @($names.Values)
}
if ($Cache) {
    Copy-Item (Join-Path $repo 'reference\build\CACHE1D.C') $scratch -Force
    $commands = @('@echo off', 'set WATCOM=C:\', 'set INCLUDE=C:\@HEADER@')
    $revisions = [ordered]@{cache95='19951025'; cache963='19960319'; cache969='19960925'}
    foreach ($item in $revisions.GetEnumerator()) {
        $short = $item.Key
        $commands += "wcc386 cache1d.c /4r /s /or /bt=dos /dLIBVER_BUILDREV=$($item.Value) /fo=$short.obj > $short.log"
        $commands += 'if errorlevel 1 goto failed'
    }
    $commands += @('echo PASS > matrix.txt', 'goto done', ':failed', 'echo FAIL > matrix.txt', ':done')
    $batch = $commands -join "`r`n"
    $logs = @($revisions.Keys)
}
$batch.Replace('@HEADER@', $headerName) | Set-Content -Encoding ascii (Join-Path $scratch 'engine.bat')
if ($Leaves) {
    # Watcom embeds each input's DOS local modification time in its OMF comments.
    # Preserve the timestamps used by the checked-in object hashes on fresh checkouts.
    $sourceTimes = @{
        'animdefs.c' = '2026-11-13T04:23:26'
        'cacheunt.c' = '2026-11-13T00:54:54'
        'cacheprf.c' = '2026-11-13T00:11:44'
        'initcach.c' = '2026-11-12T23:48:20'
        'allocach.c' = '2026-11-12T23:46:18'
        'agecache.c' = '2026-11-12T23:42:00'
        'report.c'   = '2026-11-13T00:07:36'
        'initgr.c'   = '2026-11-13T00:03:20'
        'uninitgr.c' = '2026-11-12T23:57:48'
        'kopen4.c'   = '2026-11-12T23:58:30'
        'kread.c'    = '2026-11-12T23:57:48'
        'klseek.c'   = '2026-11-12T23:52:34'
        'kfilelen.c' = '2026-11-12T23:52:34'
        'kclose.c'   = '2026-11-12T23:55:20'
        'msgconst.c' = '2026-11-13T00:50:50'
        'cachemsg.c' = '2026-11-13T00:35:06'
        'cacheglo.c' = '2026-11-13T00:38:36'
        'forcecon.c' = '2026-11-13T02:41:10'
        'maintext.c' = '2026-11-13T03:37:10'
        'mousedef.c' = '2026-11-13T10:47:10'
        'netdefs.c'  = '2026-11-13T02:05:40'
    }
    foreach ($entry in $sourceTimes.GetEnumerator()) {
        $source = Get-Item -LiteralPath (Join-Path $scratch $entry.Key)
        $source.LastWriteTime = [datetime]::ParseExact(
            $entry.Value, "yyyy-MM-dd'T'HH:mm:ss", [Globalization.CultureInfo]::InvariantCulture)
    }
}
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
    foreach ($log in $logs) { Get-Content (Join-Path $scratch "$log.log") }
} finally {
    $env:SDL_VIDEODRIVER, $env:SDL_AUDIODRIVER = $oldVideo, $oldAudio
}
