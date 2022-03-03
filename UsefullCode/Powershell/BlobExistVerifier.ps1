#This Code verifies if the URI has the specified content(blob)
try
{
    Invoke-WebRequest -Method Head "***URI?SaS***"
    
}
catch
{
    $_.exception
    if($_.exception -like "*404*")
    {
        Write-Host "Blob Doesn't Exist" -ForegroundColor Yellow
    }
    else 
    {
        Write-Host "Blob Exist" -ForegroundColor Green
    }
}