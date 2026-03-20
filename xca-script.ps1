# ================================
# CONFIGURAÇÕES
# ================================
$Url = "https://github.com/chris2511/xca/releases/download/RELEASE.2.9.0/xca-2.9.0-win64.msi"
$DownloadPath = "$env:TEMP\xca.msi"
$InstallDir = "C:\Program Files\xca"
$PublicDesktop = "C:\Users\Public\Desktop"
$ShortcutPath = "$PublicDesktop\XCA.lnk"

# ================================
# FUNÇÃO LOG
# ================================
function Write-Log {
    param([string]$Message)
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

# ================================
# DOWNLOAD
# ================================
Write-Log "Baixando XCA..."
Invoke-WebRequest -Uri $Url -OutFile $DownloadPath -UseBasicParsing

if (!(Test-Path $DownloadPath)) {
    Write-Log "Erro no download!"
    exit 1
}

# ================================
# INSTALAÇÃO SILENCIOSA
# ================================
Write-Log "Instalando XCA silenciosamente..."

$arguments = @(
    "/i `"$DownloadPath`"",
    "/qn",
    "INSTALLDIR=`"$InstallDir`"",
    "/norestart"
)

$process = Start-Process "msiexec.exe" -ArgumentList $arguments -Wait -PassThru

if ($process.ExitCode -ne 0) {
    Write-Log "Erro na instalação! Código: $($process.ExitCode)"
    exit 1
}

Write-Log "Instalação concluída!"

# ================================
# LOCALIZAR EXECUTÁVEL
# ================================
$ExePath = Join-Path $InstallDir "xca.exe"

if (!(Test-Path $ExePath)) {
    Write-Log "Executável não encontrado!"
    exit 1
}

# ================================
# CRIAR ATALHO PARA TODOS USUÁRIOS
# ================================
Write-Log "Criando atalho público..."

$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)

$Shortcut.TargetPath = $ExePath
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.Save()

Write-Log "Atalho criado em: $ShortcutPath"

# ================================
# LIMPEZA
# ================================
Remove-Item $DownloadPath -Force

Write-Log "Processo finalizado com sucesso!"