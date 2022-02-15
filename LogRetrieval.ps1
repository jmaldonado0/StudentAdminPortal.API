param(
	$EndPointUrl,
	$EndPointContainer,
	$Sas,
	#Optional Folder Name, for the logs
	$FolderName,
	$ScriptReturn = 0
)

#TODO: Delete and replaced with just error, after testing is done.
$EventLog = 'Error','Information', 'Warning'
  
#Logs sources to search.
$LogSources = 'System'
#TODO: Uncomment after testing is done
#$LogSources = 'PARTY', 'CCS', 'EC', 'DCTAutoRetrySvcLog', 'DCTBillingMonitorLog', 'DCTMSMQBillingListener', 'DCTSchedRequestLog'

$Headers = @{
	'x-ms-blob-type' = 'BlockBlob'
	'x-ms-blob-content-type' = 'text/plain'
}

$DateToCheck = Get-Date
$DateSaveFormat = 'yyyy-MM-dd'

"From date $(([DateTime]($DateToCheck)).AddDays(-1)) to $DateToCheck"

foreach($logSource in $LogSources){
	#TODO: Remove 'TESTLD1_'
	#File naming concatenate format: Folder Name(if applied)/ServerName_logSource_Date.extension 
	$file = (AddProperUriString -value $FolderName) + 'TESTLD1_' + $env:computername + '_' + $logSource + '_' + [DateTime]::Parse($DateToCheck).ToString($DateSaveFormat) + '.txt'

	$uri = $EndPointUrl + (AddProperUriString -value $EndPointContainer) + $file + $Sas

	try { 
		$logResult = Get-EventLog -LogName $logSource -EntryType $EventLog[0] -After ([DateTime]($DateToCheck)).AddDays(-1) -Before ([DateTime]($DateToCheck)) | ConvertTo-Csv | ConvertFrom-Csv | Out-String
		
		if($logResult) {
			$result = Invoke-WebRequest -Uri $uri -Method Put -Headers $Headers -Body $logResult
			"Status code $($result.StatusCode) was executed for log source: $logSource"
		}
		else {
			"File was empty for log source: $logSource"
		}
	}
	catch { 
		"On log source $logSource an exception was caught: $($_.Exception.Message)"
		$_.Exception.Response
	}
}

function AddProperUriString {
	param (
		[string]$value
	)
	IF ($value) {
		return $value + '/'
	}
}

Exit $ScriptReturn