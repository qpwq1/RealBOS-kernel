@echo off
set BASE=.\
cd /d "%BASE%"

echo Compiling...
nasm -f bin boot.asm -o boot
nasm -f bin load.asm -o load

echo Creating image...
qemu-img.exe create -f raw floppy.img 1440K > nul

echo Writing boot...
powershell -c "$f=[System.IO.File]::OpenWrite('%BASE%\floppy.img');$f.Write([System.IO.File]::ReadAllBytes('%BASE%\boot'),0,512);$f.Close()"

echo Writing load...
powershell -c "$load=[System.IO.File]::ReadAllBytes('%BASE%\load');$f=[System.IO.File]::OpenWrite('%BASE%\floppy.img');$f.Seek(512,0);$f.Write($load,0,$load.Length);$f.Close()"

echo Verifying...
powershell -c "$img=[System.IO.File]::ReadAllBytes('%BASE%\floppy.img');Write-Host('Image size: {0}' -f $img.Length);Write-Host('Boot sig: {0}' -f [BitConverter]::ToString($img[510..511]));Write-Host('Load sig: {0}' -f [BitConverter]::ToString($img[512..513]))"

echo Starting QEMU...
qemu-system-x86_64 -fda floppy.img -no-reboot

pause
