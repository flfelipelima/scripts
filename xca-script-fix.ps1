# ================================
# CONFIGURAÇÕES
# ================================
$Url = "https://github.com/chris2511/xca/releases/download/RELEASE.2.9.0/xca-2.9.0-win64.msi"
$DownloadPath = "$env:TEMP\xca.msi"
$LogPath = "$env:TEMP\xca_install.log"

# ================================
# LOG
# ================================
function Write-Log {
    param([string]$Message)
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

# ================================
# ADMIN CHECK
# ================================
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Log "Execute como Administrador!"
    exit 1
}

# ================================
# REMOVER INSTALAÇÃO EXISTENTE
# ================================
Write-Log "Verificando instalação existente..."

$ProductCode = "{9CD31286-F9BC-476F-8025-05B06EEF7510}"

$existing = Get-WmiObject -Class Win32_Product | Where-Object {
    $_.IdentifyingNumber -eq $ProductCode
}

if ($existing) {
    Write-Log "Versão existente encontrada. Removendo..."

    $uninstall = Start-Process "msiexec.exe" -ArgumentList "/x $ProductCode /qn /norestart" -Wait -PassThru

    if ($uninstall.ExitCode -ne 0) {
        Write-Log "Erro ao remover versão anterior: $($uninstall.ExitCode)"
        exit 1
    }

    Write-Log "Versão anterior removida."
} else {
    Write-Log "Nenhuma instalação existente encontrada."
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

Unblock-File -Path $DownloadPath

# ================================
# INSTALAÇÃO
# ================================
Write-Log "Instalando..."

$arguments = @(
    "/i `"$DownloadPath`"",
    "/qn",
    "ALLUSERS=1",
    "/norestart",
    "/L*v `"$LogPath`""
)

$process = Start-Process "msiexec.exe" -ArgumentList $arguments -Wait -PassThru

if ($process.ExitCode -ne 0) {
    Write-Log "Erro na instalação: $($process.ExitCode)"
    Write-Log "Ver log: $LogPath"
    exit 1
}

Write-Log "Instalação concluída com sucesso!"

# ================================
# LIMPEZA
# ================================
Remove-Item $DownloadPath -Force -ErrorAction SilentlyContinue

Write-Log "Finalizado com sucesso!"