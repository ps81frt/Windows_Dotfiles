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
function reboot   { Restart-Computer }
function poweroff { Stop-Computer }
function logout   { shutdown /l }
function free     { $sum = (Get-Process | Measure-Object WorkingSet -Sum).Sum; "{0:N2} MB" -f ($sum / 1MB) }
function df { Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{N='Used(GB)';E={[math]::Round($_.Used/1GB,2)}}, @{N='Free(GB)';E={[math]::Round($_.Free/1GB,2)}} | Format-Table -AutoSize }
function adm { $i=[Security.Principal.WindowsIdentity]::GetCurrent(); $p=[Security.Principal.WindowsPrincipal]::new($i); [pscustomobject]@{ AdminAccount=$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator); ElevatedUAC=[bool](whoami /groups | Select-String "S-1-16-12288") } }

function blkid { Get-Disk | ForEach-Object { $d = $_; Get-Partition -DiskNumber $d.Number | Select-Object @{N='Disk';E={$d.FriendlyName}}, @{N='Serial';E={$d.SerialNumber}}, DiskNumber, PartitionNumber, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,2)}}, @{N='FS';E={ $v = (Get-Volume -Partition $_ -ErrorAction SilentlyContinue).FileSystemType; if ($_.Type -eq 'System') { 'EFI (FAT32)' } elseif ($_.Type -eq 'Reserved') { 'MSR' } elseif ($v) { $v } else { '?' } }}, Type, Guid } | Format-Table -AutoSize }
function blkid-full { $physDisks = Get-PhysicalDisk; $reliability = $physDisks | Get-StorageReliabilityCounter; $physDisks | ForEach-Object { $d = $_; $rel = $reliability | Where-Object { $_.DeviceId -eq $d.DeviceId }; $objectId = if ($rel) { $rel.UniqueId } else { 'N/A' }; $storportGuid = if ($rel -and $rel.UniqueId) { $g = [regex]::Matches($rel.UniqueId, '\{[0-9A-Fa-f-]+\}'); if ($g.Count -gt 0) { $g[-1].Value.Trim('{}') } else { 'N/A' } } else { 'N/A' }; Get-Partition -DiskNumber $d.DeviceId -ErrorAction SilentlyContinue | ForEach-Object { $p = $_; $v = Get-Volume -Partition $p -ErrorAction SilentlyContinue; [PSCustomObject]@{ Disk=$d.FriendlyName; Serial=$d.SerialNumber; BusType=$d.BusType; 'Size(GB)'=[math]::Round($p.Size/1GB,2); FS=if ($p.Type -eq 'System') {'EFI (FAT32)'} elseif ($p.Type -eq 'Reserved') {'MSR'} elseif ($v.FileSystemType) {$v.FileSystemType} else {'?'}; Type=$p.Type; Guid=$p.Guid; UUID=$v.UniqueId; ObjectId=$objectId; StorportGuid=$storportGuid; Health=$d.HealthStatus; Temp_C=$rel.Temperature; 'Wear%'=$rel.Wear; ReadErr=$rel.ReadErrorsUncorrected; WriteErr=$rel.WriteErrorsUncorrected; ReadLatMax_ms=$rel.ReadLatencyMax; WriteLatMax_ms=$rel.WriteLatencyMax } } } | Format-List }
function uptime   { (Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime }
function sysinfo  { Get-ComputerInfo }
function top      { Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 }
function htop     { while ($true) { Clear-Host; Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 Name, CPU, WorkingSet | Format-Table -AutoSize; Start-Sleep 2 } }

# DIR
function la   { Get-ChildItem -Force }
function ll   { Get-ChildItem -Force | Format-Table Name, Length, LastWriteTime -AutoSize }
function lx   { Get-ChildItem | Sort-Object Extension }
function lk   { Get-ChildItem | Sort-Object Length }
function lc   { Get-ChildItem | Sort-Object LastWriteTime }
function lu   { Get-ChildItem | Sort-Object LastAccessTime }
function lr   { Get-ChildItem -Recurse }
function lt   { Get-ChildItem | Sort-Object LastWriteTime }
function lm   { Get-ChildItem | more }
function lw   { Get-ChildItem }
function labc { Get-ChildItem | Sort-Object Name }
function lf   { Get-ChildItem -File }
function ldir { Get-ChildItem -Directory }
function fetch { $os=Get-CimInstance Win32_OperatingSystem; $cpu=Get-CimInstance Win32_Processor; $ram=[math]::Round($os.TotalVisibleMemorySize/1MB,2); $gpu=(Get-CimInstance Win32_VideoController | Select-Object -First 1).Name; $admin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator); Write-Host "User: $env:USERNAME"; Write-Host "Host: $env:COMPUTERNAME"; Write-Host "Admin: $admin"; Write-Host "OS: $($os.Caption)"; Write-Host "Kernel: $($os.Version)"; Write-Host "CPU: $($cpu.Name)"; Write-Host "GPU: $gpu"; Write-Host "RAM: $ram GB" }
function f { param($p) $i=Get-Item $p -ErrorAction Stop; $l=$w=$c=$e=$t=$h=$null; if(-not $i.PSIsContainer){$r=[System.IO.StreamReader]::new($p,$true); $e=$r.CurrentEncoding.EncodingName; $l=0;$w=0;$c=0; while(($line=$r.ReadLine()) -ne $null){$l++;$c+=$line.Length;$w+=($line -split '\s+' | Where-Object {$_}).Count}; $r.Close(); $t=switch($i.Extension.ToLower()){".txt"{"Text file"}".log"{"Log file"}".csv"{"CSV file"}".xml"{"XML file"}".json"{"JSON file"}".exe"{"Executable"}".dll"{"Library"} default{"Unknown / binary"}}; $h=(Get-FileHash $p -Algorithm SHA256).Hash }; [pscustomobject]@{Name=$i.Name;Path=$i.FullName;Size_KB=[math]::Round($i.Length/1KB,2);Created=$i.CreationTime;Modified=$i.LastWriteTime;Type=$(if($i.PSIsContainer){"Directory"}else{$t});Encoding=$e;Lines=$l;Words=$w;Characters=$c;SHA256=$h} }

# FICHIERS
function mkcd  { param($dir) New-Item -ItemType Directory $dir | Set-Location }
function touch { param($f) New-Item -ItemType File $f }

# RESEAU
function ipa      { ipconfig; route print }
function netinfo  { Get-NetIPConfiguration }
function ports    { netstat -ano }
function pingg    { ping 8.8.8.8 }
function flushdns { ipconfig /flushdns }
function myip     { (irm "https://api.ipify.org") }
function dns      { Get-DnsClientServerAddress | Where-Object { $_.AddressFamily -eq 2 } | Select-Object InterfaceAlias, ServerAddresses | Format-Table -AutoSize }

# UTILS
function grep  { param($pattern, $path) Select-String $pattern $path }
function which { param($cmd) Get-Command $cmd | Select-Object -ExpandProperty Source }
function rdp   { param($target) mstsc /v:$target }
function msra { msra.exe }
function giico($p){Get-Item $p|Select-Object *,@{N="IconSizes";E={$b=[IO.File]::ReadAllBytes($_.FullName);$c=[BitConverter]::ToInt16($b,4);(0..($c-1)|%{$o=6+($_*16);$w=$b[$o];if($w-eq0){$w=256};$h=$b[$o+1];if($h-eq0){$h=256};"$w x $h"})-join", "}}}

# EXTRACTION
function ex {
    param([string]$file)
    if (!(Test-Path $file)) {
        Write-Host "'$file' is not a valid file"
        return
    }

    $base = [System.IO.Path]::GetFileName($file)
    $folder = $base `
        -replace "\.tar\.gz$","" `
        -replace "\.tar\.bz2$","" `
        -replace "\.tgz$","" `
        -replace "\.tbz2$","" `
        -replace "\.zip$","" `
        -replace "\.7z$","" `
        -replace "\.rar$","" `
        -replace "\.tar$",""

    $folder = Join-Path (Get-Location) $folder

    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
    }

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

# NAV
function ..   { cd .. }
function ...  { cd ..\.. }
function .... { cd ..\..\.. }
function desk { cd ~\Desktop }
function docs { cd ~\Documents }
function dl   { cd ~\Downloads }

# PROFIL
function reload { . $PROFILE }
function editp  { notepad $PROFILE }

# AIDE
function aliases {
    Write-Host ""
    Write-Host "  SYSTEME"
    Write-Host "  reboot      Redémarrer"
    Write-Host "  poweroff    Éteindre"
    Write-Host "  logout      Se déconnecter"
    Write-Host "  free        RAM utilisée"
    Write-Host "  uptime      Temps depuis démarrage"
    Write-Host "  sysinfo     Infos système"
    Write-Host "  top         Top 20 processus CPU"
    Write-Host "  htop        Top 20 processus CPU live (Ctrl+C pour quitter)"
    Write-Host ""
    Write-Host "  NAVIGATION"
    Write-Host "  ..          cd .."
    Write-Host "  ...         cd ..\.."
    Write-Host "  ....        cd ..\..\.."
    Write-Host "  desk        ~/Desktop"
    Write-Host "  docs        ~/Documents"
    Write-Host "  dl          ~/Downloads"
    Write-Host ""
    Write-Host "  LISTING"
    Write-Host "  la          Liste tout (cachés inclus)"
    Write-Host "  ll          Liste avec détails"
    Write-Host "  lf          Fichiers uniquement"
    Write-Host "  ldir        Dossiers uniquement"
    Write-Host "  lx          Trier par extension"
    Write-Host "  lk          Trier par taille"
    Write-Host "  lc          Trier par date modif"
    Write-Host "  lu          Trier par dernier accès"
    Write-Host "  lr          Récursif"
    Write-Host "  labc        Trier par nom"
    Write-Host ""
    Write-Host "  FICHIERS"
    Write-Host "  mkcd <dir>  Créer un dossier et s'y déplacer"
    Write-Host "  touch <f>   Créer un fichier vide"
    Write-Host ""
    Write-Host "  RESEAU"
    Write-Host "  ipa         ipconfig + route print"
    Write-Host "  netinfo     Interfaces réseau"
    Write-Host "  ports       Ports ouverts (netstat)"
    Write-Host "  pingg       Ping 8.8.8.8"
    Write-Host "  flushdns    Vider le cache DNS"
    Write-Host "  myip        IP publique"
    Write-Host "  dns         Serveurs DNS configurés"
    Write-Host ""
    Write-Host "  UTILS"
    Write-Host "  grep <p> <f>  Chercher un pattern dans un fichier"
    Write-Host "  which <cmd>   Chemin d'une commande"
    Write-Host "  rdp <host>    Ouvrir RDP vers un hôte"
    Write-Host ""
    Write-Host "  PROFIL"
    Write-Host "  reload      Recharger le profil"
    Write-Host "  editp       Éditer le profil"
    Write-Host ""
    Write-Host "  EXTRACTION"
    Write-Host "  ex <file>   Extraire une archive"
    Write-Host ""
}

clear
