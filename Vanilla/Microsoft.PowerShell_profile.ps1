$Host.UI.RawUI.WindowTitle = ''

function Prompt {
    $lastExit = $?
    $esc = [char]27

    function ColorText($text, $hex) {
        if ($hex.Length -eq 4) {
            $hex = "#$($hex[1])$($hex[1])$($hex[2])$($hex[2])$($hex[3])$($hex[3])"
        }
        $r = [int]("0x$($hex.Substring(1,2))")
        $g = [int]("0x$($hex.Substring(3,2))")
        $b = [int]("0x$($hex.Substring(5,2))")
        return "$esc[38;2;${r};${g};${b}m$text"
    }

    $date = Get-Date -Format "HH:mm:ss"
    $user = [Environment]::UserName.ToLower()
    $hostName = [Environment]::MachineName.ToLower()
    $cwd = $PWD.Path -replace [regex]::Escape($HOME), '~'
    $reset = "$esc[0m"

    # 🔥 ADMIN CHECK
    $principal = [Security.Principal.WindowsPrincipal]::new(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
    $isAdmin = $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    # 🎨 COLOR USER (ADMIN = rouge)
    $userColor = if ($isAdmin) { "#ff4444" } else { "#00aaff" }

    $symbol = if ($lastExit) {
        ColorText "➜" "#00ff88"
    } else {
        ColorText "✗" "#ff4444"
    }

    return (
        (ColorText "╭─[" "#ffffff") +
        (ColorText $date "#ffffff") +
        (ColorText "] [" "#ffffff") +
        (ColorText $user $userColor) +   # 👈 MODIF ICI
        (ColorText "@" "#5555ff") +
        (ColorText $hostName "#ffcc00") +
        (ColorText "]" "#ffffff") +
        (ColorText "`n└─ " "#ffffff") +
        (ColorText $cwd "#ffffff") +
        (ColorText "`n" "#ffffff") +
        $symbol +
        (ColorText " " "#ffffff") +
        $reset
    )
}

# Securité
function vt {param([string]$file);if(!$file){$file=Read-Host "Drag & drop file or enter path"};$file=$file.Trim('"');if(!(Test-Path $file)){Write-Error "File not found";return};do{$api=(Read-Host "VT API key").Trim('"')}until($api -and $api -notmatch '\\|:');Get-AuthenticodeSignature "$file"|Select -ExpandProperty SignerCertificate|Format-List *;f "$file";Get-Content "$file" -Stream Zone.Identifier -ea 0;$sig=Get-AuthenticodeSignature $file;$hash=(Get-FileHash $file -Algorithm SHA256).Hash;try{$vt=Invoke-RestMethod "https://www.virustotal.com/api/v3/files/$hash" -Headers @{"x-apikey"=$api} -ea Stop;$mal=$vt.data.attributes.last_analysis_stats.malicious;$sus=$vt.data.attributes.last_analysis_stats.suspicious}catch{$mal="ERR";$sus="ERR"};[PSCustomObject]@{File=$file;Signature=$sig.Status;Publisher=$sig.SignerCertificate.Subject;SHA256=$hash;VT_Malicious=$mal;VT_Suspicious=$sus}}

# SYSTEME
function reboot     { Restart-Computer }
function poweroff   { Stop-Computer }
function logout     { shutdown /l }
function free       { $os=Get-CimInstance Win32_OperatingSystem; $t=[math]::Round($os.TotalVisibleMemorySize/1MB,2); $f=[math]::Round($os.FreePhysicalMemory/1MB,2); "Used: $([math]::Round($t-$f,2)) GB / Total: $t GB" }
function lsscsi {$sg="sg_scan"; $smart="smartctl"; $res=@(); & $sg | % { if($_ -match "PD(\d+)\s+\[(\w)\]\s+(.+?)\s{2,}"){ $pd=$matches[1]; $letter=$matches[2]; $model=$matches[3].Trim(); $dev="/dev/sd"+[char](97+[int]$pd); $out=& $smart -A $dev 2>$null; function val($k){ $l=($out|Select-String $k|Select-Object -First 1); if($l -and $l.ToString() -match "(\d+)$"){[int64]$matches[1]} else {0}}; $crc=val "UDMA_CRC_Error_Count"; $pending=val "Current_Pending_Sector"; $realloc=val "Reallocated_Sector_Ct"; if($pending -gt 0 -or $realloc -gt 0){$status="BAD";$prio=0} elseif($crc -gt 100){$status="SATA";$prio=1} else{$status="OK";$prio=2}; $res+= [pscustomobject]@{PD="PD$pd";DEV=$dev;L=$letter;MODEL=$model;CRC=$crc;PEND=$pending;REALLOC=$realloc;STATUS=$status;PRIO=$prio} } }; "{0,-5} {1,-10} {2,-3} {3,-28} {4,-6} {5,-6} {6,-7} {7}" -f "PD","DEV","L","MODEL","CRC","PEND","REALLOC","STATUS"; "-"*90; $res | sort PRIO | % { $color = if($_.STATUS -eq "BAD"){"Red"} elseif($_.STATUS -eq "SATA"){"Yellow"} else{"Green"}; Write-Host ("{0,-5} {1,-10} {2,-3} {3,-28} {4,-6} {5,-6} {6,-7} {7}" -f $_.PD,$_.DEV,$_.L,$_.MODEL,$_.CRC,$_.PEND,$_.REALLOC,$_.STATUS) -ForegroundColor $color } }
function df         { Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{N='Used(GB)';E={[math]::Round($_.Used/1GB,2)}}, @{N='Free(GB)';E={[math]::Round($_.Free/1GB,2)}} | Format-Table -AutoSize }
function adm        { $i=[Security.Principal.WindowsIdentity]::GetCurrent(); $p=[Security.Principal.WindowsPrincipal]::new($i); [pscustomobject]@{ AdminAccount=$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator); ElevatedUAC=[bool](whoami /groups | Select-String "S-1-16-12288") } }
function blkid      { Get-Disk | ForEach-Object { $d = $_; Get-Partition -DiskNumber $d.Number | Select-Object @{N='Disk';E={$d.FriendlyName}}, @{N='Serial';E={$d.SerialNumber}}, DiskNumber, PartitionNumber, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,2)}}, @{N='FS';E={ $v = (Get-Volume -Partition $_ -ErrorAction SilentlyContinue).FileSystemType; if ($_.Type -eq 'System') { 'EFI (FAT32)' } elseif ($_.Type -eq 'Reserved') { 'MSR' } elseif ($v) { $v } else { '?' } }}, Type, Guid } | Format-Table -AutoSize }
function blkid-full { $physDisks = Get-PhysicalDisk; $reliability = $physDisks | Get-StorageReliabilityCounter; $physDisks | ForEach-Object { $d = $_; $rel = $reliability | Where-Object { $_.DeviceId -eq $d.DeviceId }; $objectId = if ($rel) { $rel.UniqueId } else { 'N/A' }; $storportGuid = if ($rel -and $rel.UniqueId) { $g = [regex]::Matches($rel.UniqueId, '\{[0-9A-Fa-f-]+\}'); if ($g.Count -gt 0) { $g[-1].Value.Trim('{}') } else { 'N/A' } } else { 'N/A' }; Get-Partition -DiskNumber $d.DeviceId -ErrorAction SilentlyContinue | ForEach-Object { $p = $_; $v = Get-Volume -Partition $p -ErrorAction SilentlyContinue; [PSCustomObject]@{ Disk=$d.FriendlyName; Serial=$d.SerialNumber; BusType=$d.BusType; 'Size(GB)'=[math]::Round($p.Size/1GB,2); FS=if ($p.Type -eq 'System') {'EFI (FAT32)'} elseif ($p.Type -eq 'Reserved') {'MSR'} elseif ($v.FileSystemType) {$v.FileSystemType} else {'?'}; Type=$p.Type; Guid=$p.Guid; UUID=$v.UniqueId; ObjectId=$objectId; StorportGuid=$storportGuid; Health=$d.HealthStatus; Temp_C=$rel.Temperature; 'Wear%'=$rel.Wear; ReadErr=$rel.ReadErrorsUncorrected; WriteErr=$rel.WriteErrorsUncorrected; ReadLatMax_ms=$rel.ReadLatencyMax; WriteLatMax_ms=$rel.WriteLatencyMax } } } | Format-List }
function uptime     { (Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime }
function sysinfo    { Get-ComputerInfo }
function top        { Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 }
function htop       { try { while ($true) { Clear-Host; Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 Name, CPU, WorkingSet | Format-Table -AutoSize; Start-Sleep 2 } } finally { Clear-Host; Write-Host "htop terminated." } }
function fetch      { $os=Get-CimInstance Win32_OperatingSystem; $cpu=Get-CimInstance Win32_Processor; $ram=[math]::Round($os.TotalVisibleMemorySize/1MB,2); $gpu=(Get-CimInstance Win32_VideoController | Select-Object -First 1).Name; $admin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator); Write-Host "User: $env:USERNAME"; Write-Host "Host: $env:COMPUTERNAME"; Write-Host "Admin: $admin"; Write-Host "OS: $($os.Caption)"; Write-Host "Kernel: $($os.Version)"; Write-Host "CPU: $($cpu.Name)"; Write-Host "GPU: $gpu"; Write-Host "RAM: $ram GB" }
function pkill      { param($name) Get-Process $name | Stop-Process -Force }
function pgrep      { param($name) Get-Process | Where-Object { $_.Name -like "*$name*" } }
function path       { $env:PATH -split ';' | Where-Object { $_ } }
function cut { param([string]$d=" ",[int]$f=1) process { $p = $_ -split [regex]::Escape($d); if($p.Count -ge $f){ $p[$f-1].Trim() } } }
function Rdump { if (-not $args[0]) { $path = (Read-Host "Chemin du .dmp").Trim('"') } else { $path = $args[0] } ; cdb -z $path -c "!analyze -v; q" 2>$null | grep -E "IMAGE_NAME|FAILURE_BUCKET|SYMBOL_NAME|BUGCHECK_CODE|PROCESS_NAME|STACK_TEXT|MODULE_NAME|DEFAULT_BUCKET_ID|FAILURE_ID_HASH|EXCEPTION_CODE" }
$locateDB = "$env:USERPROFILE\.locatedb"
function updatedb { $lastRun = if (Test-Path $locateDB) { (Get-Item $locateDB).LastWriteTime } else { [datetime]::MinValue }; Write-Host "Indexation depuis $lastRun..."; $new = Get-ChildItem C:\ -Recurse -ErrorAction SilentlyContinue -Force | Where-Object { $_.LastWriteTime -gt $lastRun } | Select-Object -ExpandProperty FullName; if (Test-Path $locateDB) { ((Get-Content $locateDB) + $new) | Sort-Object -Unique | Set-Content $locateDB } else { $new | Set-Content $locateDB }; Write-Host "Done : $((Get-Content $locateDB).Count) entrees" }
function updatedb-full { Write-Host "Full rescan..."; Get-ChildItem C:\ -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -ExpandProperty FullName | Set-Content $locateDB; Write-Host "Done : $((Get-Content $locateDB).Count) entrees" }
function locate { param([string]$n); if (-not (Test-Path $locateDB)) { Write-Host "Lance updatedb d'abord"; return }; Get-Content $locateDB | Where-Object { $_ -like "*$n*" } }


# NAVIGATION
function ..   { cd .. }
function ...  { cd ..\.. }
function .... { cd ..\..\.. }
function desk { cd ~\Desktop }
function docs { cd ~\Documents }
function dl   { cd ~\Downloads }

# LISTING
function la   { Get-ChildItem -Force }
function ll   { Get-ChildItem -Force | Format-Table Name, Length, LastWriteTime -AutoSize }
function lf   { Get-ChildItem -File }
function ldir { Get-ChildItem -Directory }
function lx   { Get-ChildItem | Sort-Object Extension }
function lk   { Get-ChildItem | Sort-Object Length }
function lc   { Get-ChildItem | Sort-Object LastWriteTime }
function lu   { Get-ChildItem | Sort-Object LastAccessTime }
function lt   { Get-ChildItem | Sort-Object LastWriteTime }
function lr   { Get-ChildItem -Recurse }
function lm   { Get-ChildItem | more }
function lw   { Get-ChildItem }
function labc { Get-ChildItem | Sort-Object Name }
function hist { $find = $args ; Write-Host "Finding in full history using {`$_ -like `"*$find*`"}"; Get-Content (Get-PSReadlineOption).HistorySavePath | ? {$_ -like "*$find*"} | Get-Unique | more }
function histdel { Clear-History; [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory(); Remove-Item (Get-PSReadLineOption).HistorySavePath -Force -ErrorAction SilentlyContinue }

# FICHIERS
function mkcd  { param($dir) New-Item -ItemType Directory $dir | Set-Location }
function touch { param($f) if (Test-Path $f) { (Get-Item $f).LastWriteTime = Get-Date } else { New-Item -ItemType File $f | Out-Null } }
function open  { param($f) Invoke-Item $f }
function edit  { param($f) notepad $f }
function head  { param($f, $n=10) Get-Content $f | Select-Object -First $n }
function tail  { param($f, $n=10) Get-Content $f | Select-Object -Last $n }
function tailf { param($f) Get-Content $f -Wait -Tail 20 }
function du    { param($p='.') "{0:N2} MB" -f ((Get-ChildItem $p -Recurse -File | Measure-Object Length -Sum).Sum / 1MB) }
function clip  { param($t) Set-Clipboard $t }
#function f { param($p) $i=Get-Item $p -ErrorAction Stop; $l=$w=$c=$e=$t=$h=$null; if(-not $i.PSIsContainer -and (Test-Path -LiteralPath $i.FullName)){try{$r=[System.IO.StreamReader]::new($i.FullName,$true);$enc=$r.CurrentEncoding.EncodingName;$fs=[System.IO.File]::OpenRead($i.FullName);$b=New-Object byte[] 3;$fs.Read($b,0,3)|Out-Null;$fs.Close();$bom=($b[0]-eq 0xEF -and $b[1]-eq 0xBB -and $b[2]-eq 0xBF);$e=if($bom){"$enc (UTF-8 BOM)"}else{"$enc (no BOM)"};$l=0;$w=0;$c=0;while(($line=$r.ReadLine()) -ne $null){$l++;$c+=$line.Length;$w+=($line -split '\s+'|Where-Object{$_}).Count};$r.Close();$t=switch($i.Extension.ToLower()){".txt"{"Text file"}".log"{"Log file"}".csv"{"CSV file"}".xml"{"XML file"}".json"{"JSON file"}".exe"{"Executable"}".dll"{"Library"}default{"Unknown / binary"}};$h=(Get-FileHash $i.FullName -Algorithm SHA256).Hash}catch{$e=$null;$l=$w=$c=0;$t="Unreadable file";$h=$null}finally{if($r){$r.Close()}}};[pscustomobject]@{Name=$i.Name;Path=$i.FullName;Size_KB=[math]::Round($i.Length/1KB,2);Created=$i.CreationTime;Modified=$i.LastWriteTime;Type=$(if($i.PSIsContainer){"Directory"}else{$t});Encoding=$e;Lines=$l;Words=$w;Characters=$c;SHA256=$h} }
function f { param($p); $i=Get-Item $p -ErrorAction Stop; $l=$w=$c=$e=$t=$h=$width=$height=$null; if(-not $i.PSIsContainer -and (Test-Path -LiteralPath $i.FullName)){try{$r=[System.IO.StreamReader]::new($i.FullName,$true);$enc=$r.CurrentEncoding.EncodingName;$fs=[System.IO.File]::OpenRead($i.FullName);$b=New-Object byte[] 3;$fs.Read($b,0,3)|Out-Null;$fs.Close();$e=if($b[0]-eq 0xEF -and $b[1]-eq 0xBB -and $b[2]-eq 0xBF){"$enc (UTF-8 BOM)"}else{"$enc (no BOM)"};$l=0;$w=0;$c=0;while(($line=$r.ReadLine()) -ne $null){$l++;$c+=$line.Length;$w+=($line -split '\s+'|Where-Object{$_}).Count};$r.Close();$t=switch($i.Extension.ToLower()){".txt"{"Text file"}".log"{"Log file"}".csv"{"CSV file"}".xml"{"XML file"}".json"{"JSON file"}".exe"{"Executable"}".dll"{"Library"}default{"Unknown / binary"}};$isImage=$i.Extension.ToLower() -in ".jpg",".jpeg",".png",".gif",".bmp",".tiff";if($isImage){try{Add-Type -AssemblyName System.Drawing;$img=[System.Drawing.Image]::FromFile($i.FullName);$width=$img.Width;$height=$img.Height;$img.Dispose()}catch{}};$h=(Get-FileHash $i.FullName -Algorithm SHA256).Hash}catch{$e=$null;$l=$w=$c=0;$t="Unreadable file";$h=$width=$height=$null}finally{if($r){$r.Close()}}};[pscustomobject]@{Name=$i.Name;Path=$i.FullName;Size_KB=[math]::Round($i.Length/1KB,2);Created=$i.CreationTime;Modified=$i.LastWriteTime;Type=$(if($i.PSIsContainer){"Directory"}else{$t});Encoding=$e;Lines=$l;Words=$w;Characters=$c;Width=$width;Height=$height;SHA256=$h} }
function diapo { if(!$args){ $p = Read-Host "Chemin du dossier"; & $env:IRFANVIEW /slideshow="$($p.Trim('"'))" } else { & $env:IRFANVIEW /slideshow="$(($args -join ' ').Trim('"'))" } }


# RESEAU
function ipa      { ipconfig; route print }
function netinfo  { Get-NetIPConfiguration }
function ports    { netstat -ano }
function pingg    { ping 8.8.8.8 }
function flushdns { ipconfig /flushdns }
function myip     { try { Invoke-RestMethod "https://api.ipify.org" -TimeoutSec 5 } catch { Write-Host "Unable to reach ipify: $_" } }
function dns      { Get-DnsClientServerAddress | Where-Object { $_.AddressFamily -eq 2 } | Select-Object InterfaceAlias, ServerAddresses | Format-Table -AutoSize }

# UTILS
function which { param($cmd) Get-Command $cmd | Select-Object -ExpandProperty Source }
function rdp   { param($target) mstsc /v:$target }
function msra  { msra.exe }
function giico($p) { Get-Item $p|Select-Object *,@{N="IconSizes";E={$b=[IO.File]::ReadAllBytes($_.FullName);$c=[BitConverter]::ToInt16($b,4);(0..($c-1)|%{$o=6+($_*16);$w=$b[$o];if($w-eq0){$w=256};$h=$b[$o+1];if($h-eq0){$h=256};"$w x $h"})-join", "}} }
function Convert-VideoToGif{Write-Host "--- CONVERSION VIDEO VERS GIF (MODE INTERACTIF) ---";Write-Host "";$InputPath=(Read-Host "Chemin video").Trim('"').Trim();$Fps=(Read-Host "FPS (ex: 15, 24, 30)").Trim();$Width=(Read-Host "Largeur (ex: 1920, 1280, 960)").Trim();$Flag=(Read-Host "Flag (lanczos, bilinear, bicubic, spline)").Trim();$GifOut=(Read-Host "GIF output").Trim();if(-not(Test-Path $InputPath)){Write-Error "Fichier introuvable";return};if(-not(Get-Command ffmpeg -ErrorAction SilentlyContinue)){Write-Error "FFmpeg non trouvé dans PATH";return};if(-not $GifOut.EndsWith(".gif")){$GifOut+=".gif"};$parentPath=if(Split-Path $InputPath -Parent){Split-Path $InputPath}else{Get-Location};$palettePath=Join-Path $parentPath "palette.png";$vfPalette="scale=${Width}:-1:flags=$Flag,palettegen=stats_mode=diff";$vfGif="[0:v]fps=$Fps,scale=${Width}:-1:flags=$Flag[x];[x][1:v]paletteuse";Write-Host "";Write-Host "ETAPE 1 : palette";& ffmpeg -hide_banner -loglevel info -stats -y -i $InputPath -vf $vfPalette -frames:v 1 $palettePath;if($LASTEXITCODE -ne 0){Write-Error "Palette erreur";return};Write-Host "";Write-Host "ETAPE 2 : GIF";& ffmpeg -hide_banner -loglevel info -stats -y -i $InputPath -i $palettePath -filter_complex $vfGif $GifOut;if($LASTEXITCODE -ne 0){Write-Error "GIF erreur";return};Remove-Item $palettePath -ErrorAction SilentlyContinue;Write-Host "";Write-Host "OK -> $GifOut"}

function lsgpu  { Get-WmiObject Win32_VideoController | ForEach-Object { $pci = $_.PNPDeviceID; $ven = ($pci -replace '.*VEN_(\w+).*','$1').ToLower(); $dev = ($pci -replace '.*DEV_(\w+).*','$1').ToLower(); $rev = ($pci -replace '.*REV_(\w+).*','$1').ToLower(); $bus = ($pci -replace '.*&(\d+&\w+&\d+&\w+)$','$1'); Write-Host "$bus VGA compatible controller [0300]: $($_.Name) [${ven}:${dev}] (rev $rev)" -ForegroundColor Green } }

function lsgpu+ { Get-WmiObject Win32_VideoController | ForEach-Object { $pci=$_.PNPDeviceID; $ven=($pci -replace '.*VEN_(\w+).*','$1').ToLower(); $dev=($pci -replace '.*DEV_(\w+).*','$1').ToLower(); $sub=($pci -replace '.*SUBSYS_(\w+).*','$1').ToLower(); $rev=($pci -replace '.*REV_(\w+).*','$1').ToLower(); $bus=($pci -replace '.*&(\d+&\w+&\d+&\w+)$','$1'); $vendor=switch($ven){'1002'{'AMD'}'10de'{'NVIDIA'}'8086'{'Intel'}default{"[$ven]"}}; $date=[Management.ManagementDateTimeConverter]::ToDateTime($_.DriverDate).ToString("yyyy-MM-dd"); $kernel=$_.InfSection -replace '^[a-z0-9]+_','/' -replace '^/',''; Write-Host "`n$bus VGA compatible controller [0300]: $($_.Name) [${ven}:${dev}] (rev $rev)" -ForegroundColor Green; Write-Host "`n=== $vendor GPU: $($_.Name) ===" -ForegroundColor Cyan; Write-Host "  Driver    : $($_.DriverVersion)  ($date)"; Write-Host "  INF       : $($_.InfFilename)  [$($_.InfSection)]"; Write-Host "  PCI       : VEN=$($ven.ToUpper()) [$vendor]  DEV=$($dev.ToUpper())  SUB=$($sub.ToUpper())  REV=$($rev.ToUpper())"; Write-Host "  Bus       : $pci"; Write-Host "  Kernel    : " -NoNewline; Write-Host $kernel -ForegroundColor Yellow; Write-Host "  Resolution: $($_.CurrentHorizontalResolution) x $($_.CurrentVerticalResolution) @ $($_.CurrentRefreshRate)Hz"; Write-Host "  VRAM      : $([math]::Round($_.AdapterRAM/1GB,0)) GB"; Write-Host "  DAC       : $($_.AdapterDACType)"; Write-Host "  Status    : $($_.Status)"; Write-Host "`n--- Driver Store DLLs ---" -ForegroundColor Yellow; $_.InstalledDisplayDrivers -split ',' | Group-Object {[IO.Path]::GetFileName($_.Trim())} | ForEach-Object { $tag=if($_.Count -gt 1){" (x$($_.Count)—dup)"}else{''}; Write-Host "  $($_.Name)$tag" -ForegroundColor White; Write-Host "    $([IO.Path]::GetDirectoryName($_.Group[0].Trim()))" -ForegroundColor DarkGray }; Write-Host "" } }

function inxi-H { Write-Host "`ninxi-F  Full system report (all modules)" -ForegroundColor Cyan; Write-Host "`nModules:" -ForegroundColor Yellow; Write-Host "  inxi-S    System     OS, kernel, hostname, uptime, shell, WM, theme, locale"; Write-Host "  inxi-MB   Motherboard  Manufacturer, model, BIOS version/date, chipset, chassis"; Write-Host "  inxi-C    CPU        Model, arch, cores, threads, freq/core, cache, flags, virt, temp"; Write-Host "  inxi-M    Memory     Slots, type DDR4/5, freq, vendor, serial, voltage"; Write-Host "  inxi-D    Drives     Model, serial, size, bus, media, firmware, health, temp, wear, errors, latency"; Write-Host "  inxi-P    Partitions Disk/part layout, FS, size, used, free, type, GUID"; Write-Host "  inxi-N    Network    Device, MAC, speed, IP, gateway, DNS, status, driver"; Write-Host "  inxi-A    Audio      Device, vendor, status, driver"; Write-Host "  inxi-B    Battery    Status, charge, runtime, voltage, health, chemistry"; Write-Host "  inxi-G    GPU        Device, vendor, arch, VRAM, driver, INF, resolution, monitor, DX, OpenGL, DLLs"; Write-Host "  inxi-E    PCI        All PCI devices, VEN/DEV IDs, status"; Write-Host "  inxi-U    USB        Connected USB devices, IDs, status"; Write-Host "  inxi-sm   Sensors    ACPI thermal zones, LibreHardwareMonitor (si installé), disques temp"; Write-Host "  inxi-H    Help       Ce message"; Write-Host "" }

function inxi-C { Get-WmiObject Win32_Processor | ForEach-Object { $cpu=$_; $cores=$cpu.NumberOfCores; $threads=$cpu.NumberOfLogicalProcessors; $speed=$cpu.MaxClockSpeed; $socket=$cpu.SocketDesignation; $arch=$cpu.Architecture; $archName=switch($arch){0{'x86'}1{'MIPS'}2{'Alpha'}3{'PowerPC'}5{'ARM'}6{'ia64'}9{'x86_64'}default{"unknown($arch)"}}; $stepping=$cpu.Stepping; $family=$cpu.Family; $l2=[math]::Round($cpu.L2CacheSize/1KB,1); $l3=[math]::Round($cpu.L3CacheSize/1KB,1); $vendor=$cpu.Manufacturer; $load=$cpu.LoadPercentage; $virt=if($cpu.VirtualizationFirmwareEnabled){"Enabled"}else{"Disabled"}; $ht=if($threads -gt $cores){"Enabled"}else{"Disabled"}; $reg=Get-ItemProperty "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0" -ErrorAction SilentlyContinue; $identifier=$reg.Identifier; $flags=($reg.'~MHz'),$reg.FeatureSet; $perfData=Get-WmiObject Win32_PerfFormattedData_PerfOS_Processor -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne '_Total' } | ForEach-Object { "Core$($_.Name):$($_.PercentProcessorTime)%" }; $coreFreqs=Get-WmiObject Win32_PerfFormattedData_Counters_ProcessorInformation -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne '_Total' -and $_.Name -notmatch '0,_Total' } | ForEach-Object { "Core$($_.Name.Split(',')[1]):$($_.ProcessorFrequency)MHz" }; $temp=$null; try { $thermalZone=Get-WmiObject -Namespace "root\wmi" -Class MSAcpi_ThermalZoneTemperature -ErrorAction Stop; $temp=[math]::Round(($thermalZone.CurrentTemperature | Select-Object -First 1)/10 - 273.15,1) } catch {}; $numa=Get-WmiObject Win32_MemoryArray -ErrorAction SilentlyContinue; $numaNodes=(Get-WmiObject Win32_MemoryArrayLocation -ErrorAction SilentlyContinue | Measure-Object).Count; $cache=Get-WmiObject Win32_CacheMemory -ErrorAction SilentlyContinue; $l1=($cache | Where-Object {$_.Level -eq 3} | Measure-Object MaxCacheSize -Sum).Sum; $cpuid=if($reg.Identifier -match 'Family (\d+) Model (\d+)'){[PSCustomObject]@{Family=$matches[1];Model=$matches[2]}}else{$null}; $avx=if([System.Runtime.Intrinsics.X86.Avx]::IsSupported){"avx"}else{""}; $avx2=if([System.Runtime.Intrinsics.X86.Avx2]::IsSupported){"avx2"}else{""}; $sse4=if([System.Runtime.Intrinsics.X86.Sse41]::IsSupported){"sse4_1"}else{""}; $sse42=if([System.Runtime.Intrinsics.X86.Sse42]::IsSupported){"sse4_2"}else{""}; $aes=if([System.Runtime.Intrinsics.X86.Aes]::IsSupported){"aes"}else{""}; $fma=if([System.Runtime.Intrinsics.X86.Fma]::IsSupported){"fma"}else{""}; $bmi1=if([System.Runtime.Intrinsics.X86.Bmi1]::IsSupported){"bmi1"}else{""}; $bmi2=if([System.Runtime.Intrinsics.X86.Bmi2]::IsSupported){"bmi2"}else{""}; $flagList=@($avx,$avx2,$sse4,$sse42,$aes,$fma,$bmi1,$bmi2)|Where-Object{$_}; Write-Host "`nCPU:" -ForegroundColor Cyan -NoNewline; Write-Host "  ----------------------------------------------------------------"; Write-Host "  Model     : $($cpu.Name.Trim())" -ForegroundColor White; Write-Host "  Vendor    : $vendor"; Write-Host "  Arch      : $archName"; Write-Host "  Socket    : $socket"; Write-Host "  Identifier: $identifier"; if($cpuid){Write-Host "  Family    : $($cpuid.Family)  Model: $($cpuid.Model)  Stepping: $stepping"}; Write-Host "  Cores     : $cores  Threads: $threads"; Write-Host "  HyperThread: $ht"; Write-Host "  Virt      : $virt"; Write-Host "  Speed Max : $speed MHz"; if($coreFreqs){Write-Host "  Freq/Core : $($coreFreqs -join '  ')"}; if($load){Write-Host "  Load      : $load %"}; if($perfData){Write-Host "  Load/Core : $($perfData -join '  ')"}; if($temp){Write-Host "  Temp      : ${temp} C" -ForegroundColor Yellow}else{Write-Host "  Temp      : N/A (ACPI non exposé)"}; if($l1){Write-Host "  L1 Cache  : $l1 KB"}; Write-Host "  L2 Cache  : $([math]::Round($cpu.L2CacheSize,0)) KB"; Write-Host "  L3 Cache  : $([math]::Round($cpu.L3CacheSize,0)) KB"; if($flagList){Write-Host "  Flags     : $($flagList -join ' ')" -ForegroundColor DarkGray}; Write-Host "" } }

function inxi-G { Get-WmiObject Win32_VideoController | ForEach-Object { $pci=$_.PNPDeviceID; $ven=($pci -replace '.*VEN_(\w+).*','$1').ToLower(); $dev=($pci -replace '.*DEV_(\w+).*','$1').ToLower(); $sub=($pci -replace '.*SUBSYS_(\w+).*','$1').ToLower(); $rev=($pci -replace '.*REV_(\w+).*','$1').ToLower(); $bus=($pci -replace '.*&(\d+&\w+&\d+&\w+)$','$1'); $vendor=switch($ven){'1002'{'AMD'}'10de'{'NVIDIA'}'8086'{'Intel'}default{"[$ven]"}}; $date=[Management.ManagementDateTimeConverter]::ToDateTime($_.DriverDate).ToString("yyyy-MM-dd"); $kernel=$_.InfSection -replace '^[a-z0-9]+_','/' -replace '^/',''; $vram=[math]::Round($_.AdapterRAM/1GB,0); $arch=switch -Regex ($kernel){'Polaris'{'GCN 4.0 (Polaris)'}'Navi'{'RDNA 1/2 (Navi)'}'Vega'{'GCN 5.0 (Vega)'}'Ellesmere'{'GCN 4.0'}'Turing'{'NVIDIA Turing'}'Ampere'{'NVIDIA Ampere'}'Ada'{'NVIDIA Ada Lovelace'}'Xe'{'Intel Xe'}default{'unknown'}}; $display=Get-WmiObject Win32_DesktopMonitor|Select-Object -First 1; $refresh=$_.CurrentRefreshRate; $resH=$_.CurrentHorizontalResolution; $resV=$_.CurrentVerticalResolution; $bits=$_.CurrentBitsPerPixel; Write-Host "`nGraphics:" -ForegroundColor Cyan -NoNewline; Write-Host "  ----------------------------------------------------------------"; Write-Host "  Device-1  : $($_.Name)" -ForegroundColor White; Write-Host "  Vendor    : $vendor  [VEN:$($ven.ToUpper())]"; Write-Host "  Device-ID : $($dev.ToUpper())  SUB:$($sub.ToUpper())  REV:$($rev.ToUpper())"; Write-Host "  Bus-ID    : $bus  PCI class [0300]"; Write-Host "  PNP-ID    : $pci"; Write-Host "  Arch      : $arch"; Write-Host "  VRAM      : $vram GB  ($($_.AdapterRAM) bytes)"; Write-Host "  Driver    : " -NoNewline; Write-Host $kernel -ForegroundColor Yellow -NoNewline; Write-Host "  v: $($_.DriverVersion)  date: $date"; Write-Host "  INF       : $($_.InfFilename)  [$($_.InfSection)]"; Write-Host "  DAC       : $($_.AdapterDACType)"; Write-Host "  Status    : $($_.Status)  Availability: $($_.Availability)"; Write-Host "`n  Display:" -ForegroundColor Cyan; Write-Host "  Resolution: ${resH} x ${resV}  @ ${refresh}Hz  $bits bpp"; if($display){Write-Host "  Monitor   : $($display.Name)  [$($display.ScreenWidth)x$($display.ScreenHeight)]"}; Write-Host "`n  OpenGL / DX:" -ForegroundColor Cyan; $dx=Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectX" -ErrorAction SilentlyContinue; if($dx){Write-Host "  DirectX   : $($dx.Version)  ($($dx.Description))"}; $gl=Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\OpenGLDrivers\*" -ErrorAction SilentlyContinue|Select-Object -First 1; if($gl){Write-Host "  OpenGL DLL: $($gl.Dll)"}; Write-Host "`n  Driver Store DLLs:" -ForegroundColor Cyan; $_.InstalledDisplayDrivers -split ','|Group-Object {[IO.Path]::GetFileName($_.Trim())}|ForEach-Object{$tag=if($_.Count -gt 1){" (x$($_.Count))"}else{''}; Write-Host "  $($_.Name)$tag" -ForegroundColor White; Write-Host "    $([IO.Path]::GetDirectoryName($_.Group[0].Trim()))" -ForegroundColor DarkGray}; Write-Host "" } }

function inxi-S { $os=Get-CimInstance Win32_OperatingSystem; $cs=Get-CimInstance Win32_ComputerSystem; $bios=Get-CimInstance Win32_BIOS; $uptime=(Get-Date)-$os.LastBootUpTime; $shell="PowerShell $($PSVersionTable.PSVersion)"; $wm="DWM (Desktop Window Manager)"; $theme=(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes" -ErrorAction SilentlyContinue).InstallTheme; $themeName=if($theme){[IO.Path]::GetFileNameWithoutExtension($theme)}else{"N/A"}; $locale=$os.Locale; $lang=$os.MUILanguages -join ','; Write-Host "`nSystem:" -ForegroundColor Cyan -NoNewline; Write-Host "  ----------------------------------------------------------------"; Write-Host "  Host      : $($cs.Name)" -ForegroundColor White; Write-Host "  OS        : $($os.Caption) $($os.OSArchitecture)"; Write-Host "  Build     : $($os.Version)  Build: $($os.BuildNumber)"; Write-Host "  Kernel    : Windows NT $($os.Version)"; Write-Host "  Uptime    : $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s"; Write-Host "  Shell     : $shell"; Write-Host "  WM        : $wm"; Write-Host "  Theme     : $themeName"; Write-Host "  Locale    : $locale  Lang: $lang"; Write-Host "  Install   : $($os.InstallDate)"; Write-Host "" }
function inxi-MB { $mb=Get-CimInstance Win32_BaseBoard; $bios=Get-CimInstance Win32_BIOS; $cs=Get-CimInstance Win32_ComputerSystem; $chipsets=Get-WmiObject Win32_IDEController -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name; $biosDate=try{[Management.ManagementDateTimeConverter]::ToDateTime($bios.ReleaseDate).ToString('yyyy-MM-dd')}catch{"N/A"}; Write-Host "`nMotherboard:" -ForegroundColor Cyan -NoNewline; Write-Host "  ----------------------------------------------------------------"; Write-Host "  Model     : $($mb.Manufacturer) $($mb.Product) ($($mb.Version))" -ForegroundColor White; Write-Host "  Serial    : $($mb.SerialNumber)"; Write-Host "  BIOS      : $($bios.Manufacturer)  v: $($bios.SMBIOSBIOSVersion)"; Write-Host "  BIOS Date : $biosDate"; Write-Host "  BIOS Type : $($bios.BIOSVersion -join ', ')"; Write-Host "  Chassis   : $($cs.SystemType)"; Write-Host "  Form      : $($mb.FormFactor)"; if($chipsets){Write-Host "  Chipset   : $($chipsets -join ' | ')"}; Write-Host "" }

function inxi-M { $slots=Get-CimInstance Win32_PhysicalMemory; $total=[math]::Round(($slots|Measure-Object Capacity -Sum).Sum/1GB,2); $os=Get-CimInstance Win32_OperatingSystem; $free=[math]::Round($os.FreePhysicalMemory/1MB,2); $used=[math]::Round($total-$free,2); Write-Host "`nMemory:" -ForegroundColor Cyan -NoNewline; Write-Host "  ----------------------------------------------------------------"; Write-Host "  Total     : $total GB  Used: $used GB  Free: $free GB" -ForegroundColor White; $slots | ForEach-Object { $cap=[math]::Round($_.Capacity/1GB,2); $freq=$_.ConfiguredClockSpeed; $type=switch($_.MemoryType){20{'DDR'}21{'DDR2'}24{'DDR3'}26{'DDR4'}34{'DDR5'}default{"Unknown($($_.MemoryType))"}}; $ff=switch($_.FormFactor){8{'DIMM'}12{'SODIMM'}default{"Other($($_.FormFactor))"}}; Write-Host "  Slot      : $($_.DeviceLocator)  Bank: $($_.BankLabel)" -ForegroundColor White; Write-Host "  Size      : $cap GB  Type: $type $ff  Speed: $freq MHz"; Write-Host "  Vendor    : $($_.Manufacturer)  Serial: $($_.SerialNumber)  PN: $($_.PartNumber.Trim())"; Write-Host "  Voltage   : $($_.ConfiguredVoltage) mV" ; Write-Host "" } }

function inxi-D { $disks=Get-PhysicalDisk; $rel=$disks|Get-StorageReliabilityCounter -ErrorAction SilentlyContinue; Write-Host "`nDrives:" -ForegroundColor Cyan -NoNewline; Write-Host "  ----------------------------------------------------------------"; $disks | ForEach-Object { $d=$_; $r=$rel|Where-Object{$_.DeviceId -eq $d.DeviceId}; $size=[math]::Round($d.Size/1GB,2); $temp=if($r.Temperature){"$($r.Temperature) C"}else{"N/A"}; $wear=if($r.Wear){"$($r.Wear) %"}else{"N/A"}; $readErr=if($r.ReadErrorsUncorrected -ne $null){$r.ReadErrorsUncorrected}else{"N/A"}; $writeErr=if($r.WriteErrorsUncorrected -ne $null){$r.WriteErrorsUncorrected}else{"N/A"}; $readLat=if($r.ReadLatencyMax){"$($r.ReadLatencyMax) ms"}else{"N/A"}; $writeLat=if($r.WriteLatencyMax){"$($r.WriteLatencyMax) ms"}else{"N/A"}; $health=$d.HealthStatus; $healthColor=if($health -eq 'Healthy'){'Green'}elseif($health -eq 'Warning'){'Yellow'}else{'Red'}; Write-Host "  Model     : $($d.FriendlyName)" -ForegroundColor White; Write-Host "  Serial    : $($d.SerialNumber)"; Write-Host "  Size      : $size GB  Bus: $($d.BusType)  Media: $($d.MediaType)"; Write-Host "  Firmware  : $($d.FirmwareVersion)"; Write-Host "  Health    : " -NoNewline; Write-Host $health -ForegroundColor $healthColor; Write-Host "  Temp      : $temp  Wear: $wear"; Write-Host "  ReadErr   : $readErr  WriteErr: $writeErr"; Write-Host "  ReadLat   : $readLat  WriteLat: $writeLat"; Write-Host "" } }

function inxi-P { Write-Host "`nPartitions:" -ForegroundColor Cyan -NoNewline; Write-Host "  ----------------------------------------------------------------"; Get-Disk | ForEach-Object { $disk=$_; Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue | ForEach-Object { $p=$_; $v=Get-Volume -Partition $p -ErrorAction SilentlyContinue; $size=[math]::Round($p.Size/1GB,2); $used=if($v.Size -and $v.SizeRemaining){[math]::Round(($v.Size-$v.SizeRemaining)/1GB,2)}else{"N/A"}; $free=if($v.SizeRemaining){[math]::Round($v.SizeRemaining/1GB,2)}else{"N/A"}; $fs=if($p.Type -eq 'System'){'EFI (FAT32)'}elseif($p.Type -eq 'Reserved'){'MSR'}elseif($v.FileSystemType){$v.FileSystemType}else{'?'}; $label=if($v.FileSystemLabel){$v.FileSystemLabel}else{"(no label)"}; $letter=if($p.DriveLetter){"$($p.DriveLetter):"}else{"(no letter)"}; Write-Host "  Disk $($disk.Number) Part $($p.PartitionNumber) : $letter  Label: $label" -ForegroundColor White; Write-Host "  Size      : $size GB  Used: $used GB  Free: $free GB  FS: $fs"; Write-Host "  Type      : $($p.Type)  GUID: $($p.Guid)"; Write-Host "" } } }

function inxi-N { Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true } | ForEach-Object { $na=$_; $nic=Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $na.DeviceID }; $speed=if($na.Speed){[math]::Round($na.Speed/1MB,0)}else{"N/A"}; $mac=$na.MACAddress; $ip=($nic.IPAddress -join ', '); $dns=($nic.DNSServerSearchOrder -join ', '); $gw=($nic.DefaultIPGateway -join ', '); $driver=(Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -like "*$($na.Name)*" } | Select-Object -First 1); Write-Host "`nNetwork:" -ForegroundColor Cyan -NoNewline; Write-Host "  ----------------------------------------------------------------"; Write-Host "  Device    : $($na.Name)" -ForegroundColor White; Write-Host "  MAC       : $mac"; Write-Host "  Speed     : $speed Mbps"; Write-Host "  IP        : $ip"; Write-Host "  Gateway   : $gw"; Write-Host "  DNS       : $dns"; Write-Host "  Status    : $($na.NetConnectionStatus)"; Write-Host "  Driver    : $($driver.DriverVersion)  Date: $($driver.DriverDate)"; Write-Host "" } }

function inxi-A { Get-WmiObject Win32_SoundDevice | ForEach-Object { $driver=(Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -like "*$($_.Name)*" } | Select-Object -First 1); Write-Host "`nAudio:" -ForegroundColor Cyan -NoNewline; Write-Host "  ----------------------------------------------------------------"; Write-Host "  Device    : $($_.Name)" -ForegroundColor White; Write-Host "  Vendor    : $($_.Manufacturer)"; Write-Host "  Status    : $($_.Status)"; Write-Host "  Driver    : $($driver.DriverVersion)  Date: $($driver.DriverDate)"; Write-Host "" } }

function inxi-B { $bat=Get-WmiObject Win32_Battery -ErrorAction SilentlyContinue; if(!$bat){ Write-Host "`nBattery: N/A (desktop or not detected)" -ForegroundColor Cyan; Write-Host ""; return }; $bat | ForEach-Object { $status=switch($_.BatteryStatus){1{'Discharging'}2{'AC (plugged)'}3{'Fully Charged'}4{'Low'}5{'Critical'}6{'Charging'}7{'Charging+High'}8{'Charging+Low'}9{'Charging+Critical'}10{'Undefined'}11{'Partially Charged'}default{"Unknown($($_.BatteryStatus))"}}; $health=if($_.DesignCapacity -and $_.FullChargeCapacity){[math]::Round($_.FullChargeCapacity/$_.DesignCapacity*100,1)}else{"N/A"}; Write-Host "`nBattery:" -ForegroundColor Cyan -NoNewline; Write-Host "  ----------------------------------------------------------------"; Write-Host "  Name      : $($_.Name)" -ForegroundColor White; Write-Host "  Status    : $status"; Write-Host "  Charge    : $($_.EstimatedChargeRemaining) %"; Write-Host "  Runtime   : $($_.EstimatedRunTime) min"; Write-Host "  Voltage   : $($_.DesignVoltage) mV"; Write-Host "  Health    : $health %"; Write-Host "  Chemistry : $($_.Chemistry)"; Write-Host "" } }

function inxi-E { Write-Host "`nPCI Devices:" -ForegroundColor Cyan -NoNewline; Write-Host "  ----------------------------------------------------------------"; Get-WmiObject Win32_PnPEntity | Where-Object { $_.PNPDeviceID -like "PCI\*" } | ForEach-Object { $pci=$_.PNPDeviceID; $ven=($pci -replace '.*VEN_(\w+).*','$1').ToLower(); $dev=($pci -replace '.*DEV_(\w+).*','$1').ToLower(); Write-Host "  $($_.Name)" -ForegroundColor White; Write-Host "  ID        : VEN:$($ven.ToUpper()) DEV:$($dev.ToUpper())  Status: $($_.Status)"; Write-Host "" } }

function inxi-U { Write-Host "`nUSB Devices:" -ForegroundColor Cyan -NoNewline; Write-Host "  ----------------------------------------------------------------"; Get-WmiObject Win32_PnPEntity | Where-Object { $_.PNPDeviceID -like "USB\*" -and $_.Name -notmatch "Root Hub|Host Controller|Composite" } | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor White; Write-Host "  ID        : $($_.PNPDeviceID)  Status: $($_.Status)"; Write-Host "" } }

function inxi-sm { Write-Host "`nSensors:" -ForegroundColor Cyan -NoNewline; Write-Host "  ----------------------------------------------------------------"; try { $tz=Get-WmiObject -Namespace "root\wmi" -Class MSAcpi_ThermalZoneTemperature -ErrorAction Stop; $tz | ForEach-Object { $t=[math]::Round($_.CurrentTemperature/10-273.15,1); Write-Host "  ThermalZone: $($_.InstanceName)  Temp: $t C" -ForegroundColor Yellow } } catch { Write-Host "  ACPI Thermal: N/A" }; try { $lhm=Get-WmiObject -Namespace "root\LibreHardwareMonitor" -Class Sensor -ErrorAction Stop | Where-Object { $_.SensorType -eq 'Temperature' }; $lhm | ForEach-Object { Write-Host "  $($_.Parent) / $($_.Name) : $([math]::Round($_.Value,1)) C" -ForegroundColor Yellow } } catch { Write-Host "  LibreHardwareMonitor: N/A (non installé)" }; $disks=Get-PhysicalDisk; $rel=$disks|Get-StorageReliabilityCounter -ErrorAction SilentlyContinue; $disks | ForEach-Object { $d=$_; $r=$rel|Where-Object{$_.DeviceId -eq $d.DeviceId}; if($r.Temperature){ Write-Host "  Disk $($d.FriendlyName) : $($r.Temperature) C" -ForegroundColor Yellow } }; Write-Host "" }

function inxi-F { inxi-S; inxi-MB; inxi-C; inxi-M; inxi-D; inxi-P; inxi-N; inxi-A; inxi-B; inxi-G; inxi-E; inxi-U; inxi-sm }
# EXTRACTION

function ex {
    param([string]$file)
    if (!(Test-Path $file)) { Write-Host "'$file' is not a valid file"; return }

    $base   = [System.IO.Path]::GetFileName($file)
    $folder = $base -replace "\.tar\.gz$","" -replace "\.tar\.bz2$","" -replace "\.tgz$","" -replace "\.tbz2$","" -replace "\.zip$","" -replace "\.7z$","" -replace "\.rar$","" -replace "\.tar$",""
    $folder = Join-Path (Get-Location) $folder

    if (!(Test-Path $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }

    switch -Regex ($file) {
        "\.tar\.gz$"  { 7z x $file -o"$folder" }
        "\.tar\.bz2$" { 7z x $file -o"$folder" }
        "\.tgz$"      { 7z x $file -o"$folder" }
        "\.tbz2$"     { 7z x $file -o"$folder" }
        "\.zip$"      { Expand-Archive $file -DestinationPath $folder }
        "\.7z$"       { 7z x $file -o"$folder" }
        "\.rar$"      { 7z x $file -o"$folder" }
        "\.tar$"      { 7z x $file -o"$folder" }
        "\.gz$"       { 7z x $file }
        "\.bz2$"      { 7z x $file }
        "\.Z$"        { Write-Host "Unsupported format (.Z)" }
        default       { Write-Host "'$file' cannot be extracted via ex()" }
    }
}

# PROFIL

function editp  { notepad $PROFILE }function reload { . $PROFILE }

# AIDE
function aliases {
    Write-Host ""
    Write-Host "  SYSTEME"
    Write-Host "  reboot          Redémarrer"
    Write-Host "  poweroff        Éteindre"
    Write-Host "  logout          Se déconnecter"
    Write-Host "  free            RAM utilisée (réelle)"
    Write-Host "  df              Espace disque par lecteur"
    Write-Host "  adm             Vérifier droits admin / niveau UAC"
    Write-Host "  blkid           Partitions et systèmes de fichiers"
    Write-Host "  blkid-full      Infos disque complètes (santé, temp, erreurs…)"
    Write-Host "  uptime          Temps depuis démarrage"
    Write-Host "  sysinfo         Infos système complètes"
    Write-Host "  top             Top 20 processus CPU"
    Write-Host "  htop            Top 20 processus CPU live (Ctrl+C pour quitter)"
    Write-Host "  fetch           Résumé système (OS, CPU, GPU, RAM…)"
    Write-Host "  pkill <n>       Tuer un processus par nom"
    Write-Host "  pgrep <n>       Chercher un processus par nom"
    Write-Host "  path            Afficher le PATH proprement"
    Write-Host "  lsscsi          lsscsi Inventaire disques + santé SMART (CRC, secteurs, statut: OK/SATA/BAD)"
    Write-Host "Rdump <path.dmp>  Analyse un minidump BSOD et retourne le driver coupable"
    Write-Host ""
    Write-Host "  NAVIGATION"
    Write-Host "  ..              cd .."
    Write-Host "  ...             cd ..\.."
    Write-Host "  ....            cd ..\..\..\"
    Write-Host "  desk            ~/Desktop"
    Write-Host "  docs            ~/Documents"
    Write-Host "  dl              ~/Downloads"
    Write-Host ""
    Write-Host "  LISTING"
    Write-Host "  la              Liste tout (cachés inclus)"
    Write-Host "  ll              Liste avec détails"
    Write-Host "  lf              Fichiers uniquement"
    Write-Host "  ldir            Dossiers uniquement"
    Write-Host "  lx              Trier par extension"
    Write-Host "  lk              Trier par taille"
    Write-Host "  lc              Trier par date de modification"
    Write-Host "  lu              Trier par dernier accès"
    Write-Host "  lt              Trier par date (alias lc)"
    Write-Host "  lr              Récursif"
    Write-Host "  lm              Liste avec pause (more)"
    Write-Host "  lw              Liste simple"
    Write-Host "  labc            Trier par nom"
    Write-Host ""
    Write-Host "  FICHIERS"
    Write-Host "  mkcd <dir>      Créer un dossier et s'y déplacer"
    Write-Host "  touch <f>       Créer un fichier vide (ou maj timestamp)"
    Write-Host "  open <f>        Ouvrir avec l'appli par défaut"
    Write-Host "  edit <f>        Ouvrir dans notepad"
    Write-Host "  head <f> [n]    Afficher les n premières lignes (défaut: 10)"
    Write-Host "  tail <f> [n]    Afficher les n dernières lignes (défaut: 10)"
    Write-Host "  tailf <f>       Suivre un fichier en temps réel"
    Write-Host "  du [path]       Taille d'un dossier en MB"
    Write-Host "  clip <text>     Copier dans le presse-papier"
    Write-Host "  f <file>        Infos fichier (lignes, mots, hash SHA256…)"
    Write-Host ""
    Write-Host "  RESEAU"
    Write-Host "  ipa             ipconfig + route print"
    Write-Host "  netinfo         Interfaces réseau"
    Write-Host "  ports           Ports ouverts (netstat)"
    Write-Host "  pingg           Ping 8.8.8.8"
    Write-Host "  flushdns        Vider le cache DNS"
    Write-Host "  myip            IP publique"
    Write-Host "  dns             Serveurs DNS configurés"
    Write-Host ""
    Write-Host "  UTILS"
    Write-Host "  grep <p> <f>    Chercher un pattern dans un fichier"
    Write-Host "  which <cmd>     Chemin d'une commande"
    Write-Host "  cut -d X -f N   Split ligne et prendre champ N (ex: cut -d '-->' -f 2)"
    Write-Host "  rdp <host>      Ouvrir RDP vers un hôte"
    Write-Host "  msra            Assistance à distance Windows"
    Write-Host "  giico <path>    Infos icône .ico (tailles incluses)"
    Write-Host "  histdel         Effacer l'historique PowerShell (session + fichier)"
    Write-Host ""
    Write-Host "  EXTRACTION"
    Write-Host "  ex <file>       Extraire une archive (zip, 7z, rar, tar…)"
    Write-Host ""
    Write-Host "  PROFIL"
    Write-Host "  reload          Recharger le profil"
    Write-Host "  editp           Éditer le profil"
    Write-Host ""
}

# PSREADLINE
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -PredictionSource History

clear

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8



$OutputEncoding=[System.Text.Encoding]::UTF8



$OutputEncoding=[System.Text.Encoding]::UTF8
function Wintoolkit { & "C:\Program Files\Wintoolkit\Wintoolkit.ps1" }

