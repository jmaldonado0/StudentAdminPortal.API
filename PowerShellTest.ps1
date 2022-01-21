﻿ #TODO: Delete and replaced with just error, after testing is done.
 $EventLog = 'Error','Information'
  
 #Logs to search from DCOD.
 $LogSources = 'System', 'Application'
  
 $SaveDateFormat = "yyyy-MM-dd"
 
 "(Type 'no' or 'q' to exit)"
 do {
	 do {
		 try {$UserInput = Read-Host "What date would you like to verify from the last 24 hours? In any date format you prefer" 
			  if($UserInput -eq 'no' -or $UserInput -eq 'q') {Exit}
			 }
		 catch {"Invalid format."}
	 } while (![boolean]($UserInput -as [DateTime]))
	 
	 "From date " + ([DateTime]($UserInput)).AddDays(-1) + " to $UserInput"
	  
	 #Custom Folder name for the logs.
	 $FolderName = 'ExpressErrorLogs'
	 $FolderPath = ".\$FolderName"

	 If(!(test-path $FolderPath))
	 {
		New-Item -ItemType Directory -Force -Path $FolderPath
	 }
	 
	 foreach($logSource in $LogSources){
		 #TODO: At server, detect from what computer name 
		#Name format: TODO(COMPUTER/SERVER NAME)_ServerName_logSource_Date.extension
		$fileName = $logSource + "_"+ [string][DateTime]::Parse($UserInput).ToString($SaveDateFormat) + ".csv"
		$filePath = "$FolderPath\$fileName"

		If(!(test-path $filePath)){
			#TODO: Add server and select(for specific data) and last 24h of specified date
			Get-EventLog -LogName $logSource -EntryType $EventLog[1] -After ([DateTime]($UserInput)).AddDays(-1) -Before ([DateTime]($UserInput)).AddDays(1) |
			Export-Csv -Path $filePath
		}
	}
	"Process Done`n`n"
}while($true)