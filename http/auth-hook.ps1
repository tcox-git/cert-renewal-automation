# Description: This script runs as the hook for the certbot certificate creation. It uploads a file with http challenge value to blob storage.
# 

# Create a file containing challenge value
$File = "$($env:SYSTEM_DEFAULTWORKINGDIRECTORY)\$($env:CERTBOT_TOKEN)"
New-Item $File -ItemType File -Value "$($env:CERTBOT_VALIDATION)"

#Write-Host "ACME challenge file name: $($env:CERTBOT_TOKEN)"
#Write-Host "================= ACME challenge file content ================="
#cat $File
Write-Host "================= ACME challenge file content ================="

$STORAGECONTEXT = (Get-AzStorageAccount -ResourceGroupName $env:RG_NAME -Name $env:STORAGE_NAME).Context

# Upload the file to blob storage
Set-AzStorageBlobContent -Container $env:CONTAINER_NAME -File $File -Context $STORAGECONTEXT -Blob ".well-known/acme-challenge/$($env:CERTBOT_TOKEN)"

Start-Sleep -Seconds 30