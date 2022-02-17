param(
	$UriAddress,
	#Optional Folder Name, for the logs
	$LogRetrievalFolderName,
	$ScriptReturn = 0
)

function AddProperUriString {
	param (
		[string]$value
	)
	IF ($value) {
		return $value + '/'
	}
}

function IsValidURIAddress {
	param(
		[string]$address
	)
	IF (!$address -or !$address.EndsWith('/')) { return $false }
	$local:uri = $address -as [System.URI]
	return ($null -ne $uri.AbsoluteURI -and $uri.Scheme -match '[http|https]')
}

$Script:UriSplit = $UriAddress.Split('?')

if (!(IsValidURIAddress -address $Script:UriSplit[0]) -or !$Script:UriSplit[1]) {
	"Invalid URI address"
	Exit 1
}

#TODO: Delete and replaced with just error, after testing is done.
$EventLog = 'Error','Information', 'Warning'
  
#Logs sources to search.
$LogSources = 'System'
#TODO: Uncomment after testing is done
#$LogSources = 'Application', 'PARTY', 'CCS', 'EC', 'DCTAutoRetrySvcLog', 'DCTBillingMonitorLog', 'DCTMSMQBillingListener', 'DCTSchedRequestLog'

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
	$local:file = (AddProperUriString -value $LogRetrievalFolderName) + 'TESTLD1_' + $env:computername + '_' + $logSource + '_' + [DateTime]::Parse($DateToCheck).ToString($DateSaveFormat) + '.txt'

	$local:uri = $Script:UriSplit[0] + $local:file + '?' + $Script:UriSplit[1]

	try {
		if($logSource -match '(PARTY|CCS|EC)') { 
			"Logging $logSource Entry Type Infomation"
			$logResult = Get-EventLog -LogName $logSource -EntryType 'Information' -After ([DateTime]($DateToCheck)).AddDays(-1) -Before ([DateTime]($DateToCheck)) | Select-Object * | Out-String
		}
		else { 
			"Logging $logSource on Entry Type Error"
			$logResult = Get-EventLog -LogName $logSource -EntryType $EventLog[0] -After ([DateTime]($DateToCheck)).AddDays(-1) -Before ([DateTime]($DateToCheck)) | Select-Object * | Out-String
		}
	
		if($logResult) {
			"Exporting log source: $logSource"
			$result = Invoke-WebRequest -Uri $local:uri -Method Put -Headers $Headers -Body $logResult
			"Status code $($result.StatusCode) was executed for log source: $logSource"
		}
		else {
			"No logs were found on log source: $logSource"
		}
	}
	catch { 
		"On log source $logSource an exception was caught: $($_.Exception.Message)"
		$_.Exception.Response
		$ScriptReturn = 1
	}
}

Exit $ScriptReturn