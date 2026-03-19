Write-Host "======================================="
Write-Host "DEPLOY GLOBAL DO KLEOPATRA - LABORATORIO"
Write-Host "======================================="

$gpg4winUrl = "https://files.gpg4win.org/gpg4win-latest.exe"
$tempInstaller = "$env:TEMP\gpg4win.exe"
$installPath = "C:\Program Files (x86)\Gpg4win"

# -------------------------------
# Baixar Gpg4win
# -------------------------------

if (!(Test-Path "$installPath\bin\gpg.exe")) {

    Write-Host "Baixando Gpg4win..."

    Invoke-WebRequest $gpg4winUrl -OutFile $tempInstaller

    Write-Host "Instalando silenciosamente..."

    Start-Process $tempInstaller -ArgumentList "/S" -Wait

}
else {

    Write-Host "Gpg4win ja instalado"

}

# -------------------------------
# Criar template publico
# -------------------------------

$template = "C:\Users\Public\gnupg-template"

if (!(Test-Path $template)) {

    New-Item -ItemType Directory -Path $template -Force

}

Set-Content "$template\gpg.conf" "use-agent"
Add-Content "$template\gpg.conf" "keyserver hkps://keys.openpgp.org"

Set-Content "$template\dirmngr.conf" "standard-resolver"

Write-Host "Template publico criado"

# -------------------------------
# Configurar perfil Default
# -------------------------------

$defaultProfile = "C:\Users\Default\AppData\Roaming\gnupg"

if (!(Test-Path $defaultProfile)) {

    New-Item -ItemType Directory -Path $defaultProfile -Force

}

Copy-Item "$template\*" $defaultProfile -Force

Write-Host "Perfil Default configurado"

# -------------------------------
# Corrigir usuarios existentes
# -------------------------------

$users = Get-ChildItem "C:\Users" | Where-Object {
    $_.Name -notin @("Public","Default","Default User","All Users")
}

foreach ($user in $users) {

    $userPath = "C:\Users\$($user.Name)\AppData\Roaming\gnupg"

    if (!(Test-Path $userPath)) {

        New-Item -ItemType Directory -Path $userPath -Force

    }

    Copy-Item "$template\*" $userPath -Force

}

Write-Host "Usuarios existentes configurados"

# -------------------------------
# Criar script de logon automatico
# -------------------------------

$logonScript = "C:\ProgramData\Fix_GnuPG_User.ps1"

$scriptContent = @'
$template="C:\Users\Public\gnupg-template"
$user="$env:APPDATA\gnupg"

if(!(Test-Path $user)){
Copy-Item $template $user -Recurse
}

& "C:\Program Files (x86)\Gpg4win\bin\gpgconf.exe" --launch gpg-agent
'@

Set-Content $logonScript $scriptContent

Write-Host "Script de logon criado"

# -------------------------------
# Registrar no startup global
# -------------------------------

$startup = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Fix_GnuPG_User.cmd"

$cmd = "powershell -ExecutionPolicy Bypass -File `"$logonScript`""

Set-Content $startup $cmd

Write-Host "Startup automatico configurado"

# -------------------------------
# Reiniciar serviços GPG
# -------------------------------

& "$installPath\bin\gpgconf.exe" --kill all
& "$installPath\bin\gpgconf.exe" --launch gpg-agent

Write-Host "Servicos reiniciados"

Write-Host ""
Write-Host "======================================="
Write-Host "CONFIGURACAO CONCLUIDA"
Write-Host "======================================="