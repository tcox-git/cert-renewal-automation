# Description: This script delete the file that was added from the auth-hook script after the certificate has been created.
# 

$STORAGECONTEXT = (Get-AzStorageAccount -ResourceGroupName $env:RG_NAME -Name $env:STORAGE_NAME).Context

# Remove the file from storage container after ACME challenge has passed and certificate has been generated
Remove-AzStorageBlob -Container $env:STORAGE_NAME  -Context $STORAGECONTEXT -Blob ".well-known/acme-challenge/$($env:CERTBOT_TOKEN)" 
