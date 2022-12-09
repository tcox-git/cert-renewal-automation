# Description: This script delete the file that was added from the auth-hook script after the certificate has been created.
# 

# Remove the file from storage container after ACME challenge has passed and certificate has been generated
Remove-AzStorageBlob -Container $env:STORAGE_NAME  -Context $env:STORAGECONTEXT -Blob $env:BlobName 
