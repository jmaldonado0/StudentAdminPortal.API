param(
	$UriAddress,
	#Optional Folder Name, for the logs
	$LogRetrievalFolderName,
	$ScriptReturn = 0
)

$Script:UriSplit = $UriAddress.Split('?')

if (!(IsValidURIAddress -address $Script:UriSplit[0]) -or !$Script:UriSplit[1]) {
	"Invalid URI"
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

	$local:uri = $Script:UriSplit[0] + $local:file + '?'+ $Script:UriSplit[1]

	try { 
		#TODO: Maybe modify entry type to only accept 'x' log source
		#$logResult = Get-EventLog -LogName $logSource -EntryType $EventLog[0] -After ([DateTime]($DateToCheck)).AddDays(-1) -Before ([DateTime]($DateToCheck)) | ConvertTo-Csv | ConvertFrom-Csv | Out-String
		$logResult = Get-WinEvent -LogName $logSource| 
		Select-Object * | 
		Where-Object { 
			$_.LevelDisplayName -eq $EventLog[0] -and 
			($_.TimeCreated -gt ([DateTime]($DateToCheck)).AddDays(-1) -and	$_.TimeCreated -lt ([DateTime]($DateToCheck))) 
			} | 
		Out-String
		
		if($logResult) {
			$result = Invoke-WebRequest -Uri $local:uri -Method Put -Headers $Headers -Body $logResult
			"Status code $($result.StatusCode) was executed for log source: $logSource"
		}
		else {
			"File was empty for log source: $logSource"
			$ScriptReturn = 1
		}
	}
	catch { 
		"On log source $logSource an exception was caught: $($_.Exception.Message)"
		$_.Exception.Response
		$ScriptReturn = 1
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

function IsValidURIAddress {
	param(
		[string]$address
	)
	IF (!$address -or !$address.EndsWith('/')) { return $false }
	$local:uri = $address -as [System.URI]
	return ($null -ne $uri.AbsoluteURI -and $uri.Scheme -match '[http|https]')
}

Exit $ScriptReturn