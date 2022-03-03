param(
	$UriAddress,
	#Optional Folder Name, for the logs
	$LogRetrievalFolderName,
	$ScriptReturn = 0
)

function AddProperUriString 
{
	param (
		[string]$value
	)

	if ($value) { return $value + '/' }
}

function IsValidURIAddress 
{
	param(
		[string]$address 
	)

	if(!$address.EndsWith('/')) { return $false }

	$local:uri = $address -as [System.URI]

	return $null -ne $uri.AbsoluteURI -and $uri.Scheme -match '[http|https]'
}

if($null -eq $UriAddress)
{ 
	Write-Error 'No URI has been provided.'
	exit 1
}

$Script:UriSplit = $UriAddress.ToString().Split('?')

if (!(IsValidURIAddress -address $Script:UriSplit[0]) -or !$Script:UriSplit[1]) 
{
	Write-Error 'Invalid URI address'
	Exit 1
}

#Logs sources to search.
$LogSources = 'System', 'Application', 'PARTY', 'CCS', 'EC', 'DCTAutoRetrySvcLog', 'DCTBillingMonitorLog', 'DCTMSMQBillingListener', 'DCTSchedRequestLog'

$Headers = 
@{
	'x-ms-blob-type' = 'BlockBlob'
	'x-ms-blob-content-type' = 'text/csv'
}

$Script:LogDate = Get-Date

#LD = log date
$Script:PreviousDayOfLD = $Script:LogDate.AddDays(-1)

$DateSaveFormat = 'yyyy-MM-dd'

"From date $Script:PreviousDayOfLD to $Script:LogDate"

foreach($logSource in $LogSources)
{
	#File naming concatenation: Folder Name(if applied)/ServerName_logSource_Date.extension 
	$local:file = (AddProperUriString -value $LogRetrievalFolderName) + ($env:computername, $logSource, $Script:PreviousDayOfLD.ToString($DateSaveFormat) -join '_') + '.csv'
	
	$local:uri = $Script:UriSplit[0] + $local:file + '?' + $Script:UriSplit[1]

	try 
	{
		Write-Host "Logging $logSource"

		$logResult = Get-EventLog -LogName $logSource -After $Script:PreviousDayOfLD -Before $Script:LogDate | Sort-Object -Property TimeGenerated | ConvertTo-Csv -NoTypeInformation | Out-String
		
		if($logResult) 
		{
			Write-Host "Attempting to export log source: $logSource"

			$result = Invoke-WebRequest -Uri $local:uri -Method Put -Headers $Headers -Body $logResult

			Write-Host "Status code $($result.StatusCode) was executed for log source: $logSource`n" -ForegroundColor Green
		}

		else 
		{
			Write-Warning "No logs were found on log source: $logSource`n" 
		}
	}

	catch 
	{ 
		Write-Warning "On log source $logSource an exception was caught:`n$($_.Exception.Message)`n"

		$ScriptReturn = 1
	}
}

Exit $ScriptReturn