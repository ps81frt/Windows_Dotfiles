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

    $symbol = if ($lastExit) {
        ColorText "➜" "#00ff88"
    } else {
        ColorText "✗" "#ff4444"
    }

    return (
        (ColorText "╭─[" "#ffffff") +
        (ColorText $date "#ffffff") +
        (ColorText "] [" "#ffffff") +
        (ColorText $user "#ffffff") +
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
function f     { param($p) $i=Get-Item $p -ErrorAction Stop; $l=$w=$c=$e=$t=$h=$null; if(-not $i.PSIsContainer -and (Test-Path -LiteralPath $i.FullName)){try{$r=[System.IO.StreamReader]::new($i.FullName,$true);$e=$r.CurrentEncoding.EncodingName;$l=0;$w=0;$c=0;while(($line=$r.ReadLine()) -ne $null){$l++;$c+=$line.Length;$w+=($line -split '\s+'|Where-Object{$_}).Count};$r.Close();$t=switch($i.Extension.ToLower()){".txt"{"Text file"}".log"{"Log file"}".csv"{"CSV file"}".xml"{"XML file"}".json"{"JSON file"}".exe"{"Executable"}".dll"{"Library"}default{"Unknown / binary"}};$h=(Get-FileHash $i.FullName -Algorithm SHA256).Hash}catch{$e=$null;$l=$w=$c=0;$t="Unreadable file";$h=$null}finally{if($r){$r.Close()}}};[pscustomobject]@{Name=$i.Name;Path=$i.FullName;Size_KB=[math]::Round($i.Length/1KB,2);Created=$i.CreationTime;Modified=$i.LastWriteTime;Type=$(if($i.PSIsContainer){"Directory"}else{$t});Encoding=$e;Lines=$l;Words=$w;Characters=$c;SHA256=$h} }

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
function reload { . $PROFILE }
function editp  { notepad $PROFILE }

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
