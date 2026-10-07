param(
    [string[]]$Sources = @("boot.asm", "stage2.asm"),
    [string]$Output = "disk.img",
    [ValidateSet("floppy", "harddisk")]
    [string]$Boot = "floppy",
    [string]$Qemu = "qemu-system-i386",
    [string[]]$QemuArgs = @(),
    [switch]$NoRun
)

$ErrorActionPreference = "Stop"

# --- 1. 编译 ---
$bins = @()
foreach ($src in $Sources) {
    if (-not (Test-Path $src)) {
        Write-Error "Source not found: $src"
        exit 1
    }
    $bin = [System.IO.Path]::ChangeExtension($src, ".bin")
    Write-Host "nasm -f bin $src -o $bin"
    & nasm -f bin $src -o $bin
    if ($LASTEXITCODE -ne 0) {
        Write-Error "nasm failed on $src"
        exit 1
    }
    $bins += $bin
}

# --- 2. 拼接 ---
if (Test-Path $Output) { Remove-Item $Output }

$fs = [System.IO.File]::OpenWrite($Output)
try {
    foreach ($b in $bins) {
        $data = [System.IO.File]::ReadAllBytes($b)
        $fs.Write($data, 0, $data.Length)
        Write-Host ("  {0,-16} {1,8} bytes" -f $b, $data.Length)
    }
} finally {
    $fs.Close()
}

$size = (Get-Item $Output).Length
Write-Host ("Wrote {0} ({1} bytes, {2} sectors)" -f $Output, $size, ($size / 512))

if ($size % 512 -ne 0) {
    Write-Warning "Image size is not a multiple of 512"
}

if ($NoRun) { exit 0 }

# --- 3. 启动 ---
$bootArg = switch ($Boot) {
    "floppy"   { @("-fda", $Output) }
    "harddisk" { @("-hda", $Output) }
}

$allArgs = $bootArg + $QemuArgs
Write-Host ("{0} {1}" -f $Qemu, ($allArgs -join " "))
& $Qemu @allArgs