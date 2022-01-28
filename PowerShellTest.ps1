#TODO: Delete and replaced with just error, after testing is done.
$EventLog = 'Error','Information', 'Warning'
  
#Logs sources to search.
$LogSources = 'PARTY', 'CCS', 'EC', 'DCTAutoRetrySvcLog', 'DCTBillingMonitorLog', 'DCTMSMQBillingListener', 'DCTSchedRequestLog', 'System'
  
$SaveDateFormat = "yyyy-MM-dd"
 
$FolderName = 'ErrorLogs'
 
$DateToCheck = Get-Date
	 
"From date " + ([DateTime]($DateToCheck)).AddDays(-1) + " to $DateToCheck"
  
$FolderPath = ".\$FolderName"

If(!(test-path $FolderPath))
{
	New-Item -ItemType Directory -Force -Path $FolderPath
}
 
foreach($logSource in $LogSources){
	#Name format: Computer/ServerName_logSource_Date.extension
	$fileName = $env:computername + "_" + $logSource + "_"+ [string][DateTime]::Parse($DateToCheck).ToString($SaveDateFormat) + ".csv"
	$filePath = "$FolderPath\$fileName"

	If(!(test-path $filePath)){
		Get-EventLog -LogName $logSource -EntryType $EventLog[2] -After ([DateTime]($DateToCheck)).AddDays(-1) -Before ([DateTime]($DateToCheck)).AddDays(1) |
		Export-Csv -Path $filePath
	}
}
#testing  12,.2232