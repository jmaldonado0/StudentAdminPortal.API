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

	if ($value) {
		return $value + '/'
	}
}

function IsValidURIAddress {
	param(
		[string]$address 
	)

	if(!$address.EndsWith('/')) { return $false }

	$local:uri = $address -as [System.URI]

	return $null -ne $uri.AbsoluteURI -and $uri.Scheme -match '[http|https]'
}

if($null -eq $UriAddress)
{ 
	"No URI has been provided."
	exit 1
}

$Script:UriSplit = $UriAddress.ToString().Split('?')

if (!(IsValidURIAddress -address $Script:UriSplit[0]) -or !$Script:UriSplit[1]) {
	"Invalid URI address"

	Exit 1
}

#Logs sources to search.
$LogSources = 'System', 'Application', 'PARTY', 'CCS', 'EC', 'DCTAutoRetrySvcLog', 'DCTBillingMonitorLog', 'DCTMSMQBillingListener', 'DCTSchedRequestLog'

$Headers = @{
	'x-ms-blob-type' = 'BlockBlob'
	'x-ms-blob-content-type' = 'text/csv'
}

$Script:DateToCheck = Get-Date

$DateSaveFormat = 'yyyy-MM-dd'

"From date $(([DateTime]($Script:DateToCheck)).AddDays(-1)) to $Script:DateToCheck"

foreach($logSource in $LogSources){
	#File naming concatenation: Folder Name(if applied)/ServerName_logSource_Date.extension 
	$local:file = (AddProperUriString -value $LogRetrievalFolderName) + $env:computername + '_' + $logSource + '_' + [DateTime]::Parse($Script:DateToCheck).AddDays(-1).ToString($DateSaveFormat) + '.csv'
	
	$local:uri = $Script:UriSplit[0] + $local:file + '?' + $Script:UriSplit[1]

	try {
		"Logging $logSource"

		$logResult = Get-EventLog -LogName $logSource -After ([DateTime]($Script:DateToCheck)).AddDays(-1) -Before ([DateTime]($Script:DateToCheck)) | Sort-Object -Property TimeGenerated | ConvertTo-Csv 
		
		if($logResult) {
			"Exporting log source: $logSource"

			$result = Invoke-WebRequest -Uri $local:uri -Method Put -Headers $Headers -Body $logResult

			"Status code $($result.StatusCode) was executed for log source: $logSource`n"
		}

		else {
			"No logs were found on log source: $logSource`n"
		}
	}

	catch { 
		"On log source $logSource an exception was caught: $($_.Exception.Message)"

		$_.Exception.Response + "`n"

		$ScriptReturn = 1
	}
}

Exit $ScriptReturn