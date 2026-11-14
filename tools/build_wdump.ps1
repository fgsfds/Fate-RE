# Build an analysis-only native wdump from the pinned external Open Watcom source.
param([string]$Compiler = 'C:\msys64\mingw64\bin\gcc.exe')
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$upstream = Join-Path $repo 'reference\open-watcom-v2'
$output = Join-Path $repo 'work\wcdatool-full'
$revision = '29a0323978834da7599500a1ed208fa4303f2ea5'
if ((& git -C $upstream rev-parse HEAD) -ne $revision) { throw 'Unexpected Open Watcom revision.' }
& git -C $upstream diff --quiet HEAD -- bld/exedump bld/watcom bld/dip/watcom/h
if ($LASTEXITCODE -ne 0) { throw 'Upstream dumper sources differ from pinned revision.' }
$directories = @('bld\exedump\h', 'bld\watcom\h', 'bld\dip\watcom\h')
foreach ($directory in $directories) {
    if (-not (Test-Path (Join-Path $upstream $directory))) {
        throw "Missing source directory $directory; see docs/WCDATOOL-FULL.md."
    }
}
New-Item -ItemType Directory -Force $output | Out-Null
$sources = @(Get-ChildItem (Join-Path $upstream 'bld\exedump\c\*.c') | Sort-Object Name | ForEach-Object { $_.FullName })
$sources += Join-Path $upstream 'bld\watcom\c\leb128rd.c'
$sources += Join-Path $upstream 'bld\watcom\c\clibext.c'
$arguments = @('-std=gnu99', '-O2', '-DBOOTSTRAP', '-D__NT__', '-D_BLDVER=1300', '-include', 'getopt.h')
foreach ($directory in $directories) { $arguments += '-I' + (Join-Path $upstream $directory) }
$arguments += $sources
$arguments += @('-o', (Join-Path $output 'wdump.exe'))
$oldPath = $env:PATH
try {
    $env:PATH = (Split-Path $Compiler) + ';' + $oldPath
    $version = (& $Compiler --version | Select-Object -First 1)
    & $Compiler @arguments 2> (Join-Path $output 'wdump-build.log')
    if ($LASTEXITCODE -ne 0) { throw 'wdump build failed; inspect ignored build log.' }
    $metadata = [ordered]@{
        upstream_revision = $revision
        compiler = $version
        compiler_sha256 = (Get-FileHash $Compiler -Algorithm SHA256).Hash.ToLower()
        output_sha256 = (Get-FileHash (Join-Path $output 'wdump.exe') -Algorithm SHA256).Hash.ToLower()
        sources_modified = $false
        flags = @('-std=gnu99', '-O2', '-DBOOTSTRAP', '-D__NT__', '-D_BLDVER=1300', '-include', 'getopt.h')
        source_files = @($sources | ForEach-Object { $_.Substring($upstream.Length+1).Replace('\', '/') })
    }
    $metadata | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 (Join-Path $output 'wdump-build.json')
    Write-Output "Built pinned-source wdump: $($metadata.output_sha256)"
} finally {
    $env:PATH = $oldPath
}
