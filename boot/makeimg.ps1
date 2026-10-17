param(
    [string[]]$Sources = @("boot.asm", "stage2.asm"),
    [string]$Output = "disk.img",
    [int]$PadTo = 1474560
)

$ErrorActionPreference = "Stop"

# 强制所有操作以脚本所在目录为基准
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
[Environment]::CurrentDirectory = $scriptDir
Push-Location $scriptDir

try {
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

    # --- 2. 拼接 + 填充 ---
    if (Test-Path $Output) { Remove-Item $Output }

    $fs = [System.IO.File]::OpenWrite($Output)
    try {
        $total = 0
        foreach ($b in $bins) {
            $data = [System.IO.File]::ReadAllBytes($b)
            $fs.Write($data, 0, $data.Length)
            $total += $data.Length
            Write-Host ("  {0,-16} {1,8} bytes" -f $b, $data.Length)
        }

        if ($PadTo -gt 0) {
            if ($total -gt $PadTo) {
                Write-Warning "Image ($total bytes) exceeds PadTo ($PadTo bytes), skipping padding"
            } else {
                $padBytes = $PadTo - $total
                if ($padBytes -gt 0) {
                    $zeros = New-Object byte[] $padBytes
                    $fs.Write($zeros, 0, $padBytes)
                    Write-Host ("  {0,-16} {1,8} bytes" -f "<padding>", $padBytes)
                }
            }
        }
    } finally {
        $fs.Close()
    }

    $size = (Get-Item $Output).Length
    Write-Host ("Wrote {0} ({1} bytes, {2} sectors)" -f $Output, $size, ($size / 512))

    if ($size % 512 -ne 0) {
        Write-Warning "Image size is not a multiple of 512"
    }
} finally {
    Pop-Location
}