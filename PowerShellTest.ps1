#TODO: Delete and replaced with just error, after testing is done.
$EventLog = 'Error','Information', 'Warning'
  
#Logs sources to search.
$LogSources = 'System'
#$LogSources = 'PARTY', 'CCS', 'EC', 'DCTAutoRetrySvcLog', 'DCTBillingMonitorLog', 'DCTMSMQBillingListener', 'DCTSchedRequestLog'
  
#Blob container name
$Container = ''
#Container Url
$Url = ""
#Container Sas
$Sas = ""
#Header for web request
$Headers = @{
	'x-ms-blob-type' = 'BlockBlob'
	'x-ms-blob-content-type' = 'text/plain'
} 

#Date to check from its last 24 hours
$DateToCheck = Get-Date
#Save Date Format for the file
$SaveDateFormat = 'yyyy-MM-dd'

"From date $(([DateTime]($DateToCheck)).AddDays(-1)) to $DateToCheck"

foreach($logSource in $LogSources){
	#Concatenate Name format: Computer/ServerName_logSource_Date.extension
	$fileName = 'TESTLD1_'+ $env:computername + "_" + $logSource + "_"+ [string][DateTime]::Parse($DateToCheck).ToString($SaveDateFormat) + ".txt"
	#File path for uri
	$filePath = "$Container/$fileName"
	
	#Uri concatenation
	$uri = $Url + $filePath + $Sas

	$logResult = Get-EventLog -LogName $logSource -EntryType $EventLog[2] -After ([DateTime]($DateToCheck)).AddDays(-1) -Before ([DateTime]($DateToCheck)) | ConvertTo-Csv | ConvertFrom-Csv
	
	try 
	{ 
		$result = Invoke-WebRequest -Uri $uri -Method Put -Headers $Headers -Body $logResult
	}
	catch { 
		"An exception was caught: $($_.Exception.Message)"
		$_.Exception.Response 
	}
}