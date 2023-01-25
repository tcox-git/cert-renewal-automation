# Description: This script installs certbot, runs the renewal/creation command, converts the certificate to .pfx, then uploads to a key vault.
#
# Usage:
# ./renew-cert.ps1 -Domain {domain_name} `
#                  -ResourceGroup {rg_name} `
#                  -StorageAccount {storage_name} `
#                  -Container {container_name} `
#                  -KeyVault {keyvault_name} `
#                  -CertFile {certfile_name} `
#                  -PkPwd {pk_password} `
#                  -StagingAcmeServer {true/false} `
#                  -Email {email_addr}

param (
    [Parameter(Mandatory, HelpMessage = "Domain name")]
    $Domain, 

    [Parameter(Mandatory, HelpMessage = "Resource group name.")]
    [string] $ResourceGroup,

    [Parameter(Mandatory, HelpMessage = "Storage account name.")]
    [string] $StorageAccount,

    [Parameter(Mandatory, HelpMessage = "Storage container name.")]
    [string] $Container,

    [Parameter(Mandatory, HelpMessage = "Key vault name.")]
    [string] $KeyVault,

    [Parameter(Mandatory, HelpMessage = "Certificate file name.")]
    [string] $CertFile,

    [Parameter(Mandatory, HelpMessage = "Private key password.")]
    [string] $PkPwd,

    [Parameter(HelpMessage = "Use staging ACME server or not. Default to true")]
    [bool] $StagingAcmeServer = $true,

    [Parameter(HelpMessage = "Email address.")]
    [string] $Email = "first.last@gmail.com"
)

Write-Host "Default working directory: $($env:SYSTEM_DEFAULTWORKINGDIRECTORY)"
#$env:SYSTEM_DEFAULTWORKINGDIRECTORY = Get-Location
$AuthHookPath       = "$($env:SYSTEM_DEFAULTWORKINGDIRECTORY)\SparrowInfrastructure\cert-renewal\http\auth-hook.ps1"
$CleanupHookPath    = "$($env:SYSTEM_DEFAULTWORKINGDIRECTORY)\SparrowInfrastructure\cert-renewal\http\cleanup-hook.ps1"
$AcmeServer         = "https://acme-staging-v02.api.letsencrypt.org/directory"
$env:RG_NAME        = $ResourceGroup
$env:STORAGE_NAME   = $StorageAccount
$env:CONTAINER_NAME = $Container

if (!$StagingAcmeServer) {
    $AcmeServer = "https://acme-v02.api.letsencrypt.org/directory"
}
Write-Host "ACME server: $($AcmeServer)"
#cat $AuthHookPath

# install openssl
Write-Host "Install openssl"
choco install openssl --no-progress

# Download certbot
Write-Host "Download certbot to default working directory"
Invoke-WebRequest -Uri https://dl.eff.org/certbot-beta-installer-win32.exe -OutFile "$($env:SYSTEM_DEFAULTWORKINGDIRECTORY)\certbot-beta-installer-win32.exe"

Set-Location $($env:SYSTEM_DEFAULTWORKINGDIRECTORY)

Write-Host "Install certbot"
# /D not working
Start-Process -Wait -FilePath ".\certbot-beta-installer-win32.exe" -ArgumentList "/S" -PassThru

# Request a new certificate with -n (or --noninteractive) flag
#   note: certbot must be run on a shell with administrative rights.
Write-Host "Request a new certificate"
Set-Location "C:\Program Files (x86)\Certbot\bin"
.\certbot.exe certonly --manual --preferred-challenges=http --manual-auth-hook $AuthHookPath -d $Domain --email $Email --manual-cleanup-hook $CleanupHookPath --agree-tos -n --server $AcmeServer

Set-Location "C:\Certbot\live\$Domain\"

# Convert certificate to .pfx
Write-Host "Convert certificate to .pfx"
openssl pkcs12 -export -out "$CertFile.pfx" -inkey privkey.pem -in fullchain.pem -passout pass:$PkPwd

# Import certificate to KeyVault
$Password = ConvertTo-SecureString -String $PkPwd -AsPlainText -Force
Import-AzKeyVaultCertificate -VaultName $KeyVault -Name $CertFile -FilePath "$CertFile.pfx" -Password $Password
