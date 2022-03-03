#This code allows you to check if the azure containter exist
$context = New-AzureStorageContext -ConnectionString "***BlobEndpointHere****"

try
{   
    $blob = Get-AzureStorageContainer -Name dev-logs -Context $context -ErrorAction Stop
}
 catch [Microsoft.WindowsAzure.Commands.Storage.Common.ResourceNotFoundException]
 {
     # Add logic here to remember that the blob doesn't exist...
     Write-Host "BlobEndpoint Not Found"
}
catch
{
    # Report any other error
    Write-Error "BlobEndpoint not found"
}