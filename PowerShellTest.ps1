#TODO: Delete and replaced with just error, after testing is done.
$EventLog = 'Error','Information', 'Warning'
  
#Logs sources to search.
$LogSources = 'System'
#$LogSources = 'PARTY', 'CCS', 'EC', 'DCTAutoRetrySvcLog', 'DCTBillingMonitorLog', 'DCTMSMQBillingListener', 'DCTSchedRequestLog'

#Optional Folder Name, for the logs
$FolderName = ''

#Input for blob enpoint with sas
$FullEnpoint = ''
$UrlWithSas = $FullEnpoint.Split('?')

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
	#TODO: Remove 'TESTLD1_'
	#File naming Concatenate format: Folder Name(if applied)/ServerName_logSource_Date.extension 
	$file = (AddProperUriString -value $FolderName) + 'TESTLD1_' + $env:computername + '_' + $logSource + '_' + [string][DateTime]::Parse($DateToCheck).ToString($SaveDateFormat) + '.txt'

	#Uri concatenation
	$uri = $UrlWithSas[0] + $file + '?' + $UrlWithSas[1]

	try 
	{ 
		$logResult = Get-EventLog -LogName $logSource -EntryType $EventLog[2] -After ([DateTime]($DateToCheck)).AddDays(-1) -Before ([DateTime]($DateToCheck)) | ConvertTo-Csv | ConvertFrom-Csv

		$result = Invoke-WebRequest -Uri $uri -Method Put -Headers $Headers -Body $logResult
		"Status code $($result.StatusCode) was executed"
	}
	catch { 
		"An exception was caught: $($_.Exception.Message)"
		$_.Exception.Response 
	}
}

#Checks if the string is empty then returns with a forward slash
function AddProperUriString {
	param (
		[string]$value
	)
	IF ($value) 
	{
		return $value + '/'
	}
}