# =============================================================================
# ANDROID STUDIO  (VERSÃO LAB - AUTOMAÇÃO TOTAL)
# =============================================================================

# 1. VERIFICAÇÃO DE PRIVILÉGIOS
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "ERRO: Este script deve ser executado como ADMINISTRADOR."
    exit
}

# --- Configurações de Caminhos Globais ---
$AndroidRoot  = "C:\Android"
$SdkPath      = "$AndroidRoot\Sdk"
$AvdPath      = "$AndroidRoot\Avds"
$GradlePath   = "C:\GradleCache"
$StudioDir    = "C:\Program Files\Android\Android Studio"
$Temp         = "$env:TEMP\AndroidLab"

# --- Links de Download (Versões Estáveis) ---
$StudioUrl     = "https://redirector.gvt1.com/edgedl/android/studio/install/2025.2.2.8/android-studio-2025.2.2.8-windows.exe"
$CmdLineUrl    = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"


if (!(Test-Path $Temp)) { New-Item -ItemType Directory $Temp | Out-Null }

Write-Host "`n[1/4] Preparando Pastas e Permissões Globais..." -ForegroundColor Cyan
@( $SdkPath, $GradlePath, $AvdPath ) | ForEach-Object {
    if (!(Test-Path $_)) { New-Item -ItemType Directory -Force -Path $_ | Out-Null }
}

# Permissões via SID (S-1-5-32-545 = Grupo Usuários Autenticados)
$UserSID = "S-1-5-32-545"
icacls $AndroidRoot /grant "*${UserSID}:(OI)(CI)M" /T /C /Q
icacls $GradlePath /grant "*${UserSID}:(OI)(CI)M" /T /C /Q

# Variáveis de Ambiente de Sistema
$EnvVars = @{
    "ANDROID_HOME"     = $SdkPath
    "ANDROID_SDK_ROOT" = $SdkPath
    "GRADLE_USER_HOME" = $GradlePath
    "ANDROID_AVD_HOME" = $AvdPath
}
foreach ($key in $EnvVars.Keys) {
    [System.Environment]::SetEnvironmentVariable($key, $EnvVars[$key], 'Machine')
}

Write-Host "`n[2/4] Baixando Componentes (Aguarde)..." -ForegroundColor Cyan
$Downloads = @{
    "Studio" = $StudioUrl; "Cmd" = $CmdLineUrl
}
foreach ($item in $Downloads.GetEnumerator()) {
    $ext = if ($item.Name -eq "Cmd" -or $item.Name -eq "Plugin") { "zip" } else { "exe" }
    $dest = "$Temp\$($item.Name).$ext"
    if (!(Test-Path $dest)) {
        Write-Host "Baixando $($item.Name)..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $item.Value -OutFile $dest -UseBasicParsing
    }
}

Write-Host "`n[3/4] Instalando e Configurando SDK..." -ForegroundColor Cyan
# Instalação Silenciosa do Android Studio
if (!(Test-Path $StudioDir)) {
    Write-Host "Instalando Android Studio..." -ForegroundColor Yellow
    Start-Process "$Temp\Studio.exe" -ArgumentList "/S" -Wait
}

# Configurar Command Line Tools (Estrutura: Sdk\cmdline-tools\latest\bin)
Write-Host "Configurando CmdLineTools..." -ForegroundColor Gray
$CmdZip = "$Temp\Cmd.zip"
$CmdBase = "$SdkPath\cmdline-tools"
Expand-Archive $CmdZip -DestinationPath $CmdBase -Force
if (Test-Path "$CmdBase\cmdline-tools") {
    if (Test-Path "$CmdBase\latest") { Remove-Item "$CmdBase\latest" -Recurse -Force }
    Move-Item -Path "$CmdBase\cmdline-tools" -Destination "$CmdBase\latest"
}

# Aceitar Licenças usando o Java embutido do Studio
$JbrPath = Get-ChildItem -Path $StudioDir -Directory -Filter "jbr" -Recurse | Select-Object -First 1 -ExpandProperty FullName
if ($JbrPath) {
    Write-Host "Aceitando licenças do SDK..." -ForegroundColor Gray
    $env:JAVA_HOME = $JbrPath
    $sdkManager = "$SdkPath\cmdline-tools\latest\bin\sdkmanager.bat"
    if (Test-Path $sdkManager) {
        # Envia 'y' para todas as perguntas de licença
        $process = Start-Process $sdkManager -ArgumentList "--licenses", "--sdk_root=$SdkPath" -RedirectStandardInput (New-TemporaryFile) -NoNewWindow -PassThru
        # Nota: Em automação real, pode ser necessário um echo "y" | sdkmanager
        cmd /c "echo y | `"$sdkManager`" --licenses --sdk_root=`"$SdkPath`""
    }
}

# Atualização do PATH do Sistema
$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$NewPaths = @("$SdkPath\platform-tools", "$SdkPath\emulator", "$SdkPath\cmdline-tools\latest\bin")
foreach ($p in $NewPaths) {
    if ($CurrentPath -notlike "*$p*") { $CurrentPath = "$p;$CurrentPath" }
}
[Environment]::SetEnvironmentVariable("Path", $CurrentPath, "Machine")

# Limpeza
Remove-Item $Temp -Recurse -Force
Write-Host "`n✅ CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
Write-Host "Localização do SDK: $SdkPath"
Write-Host "Localização AVDs: $AvdPath"