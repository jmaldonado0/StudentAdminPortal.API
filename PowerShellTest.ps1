﻿ #TODO: Add server command
 $Server = 'x', 'y', 'z'

 #TODO: Delete and replaced with just error.
 $EventLog = 'Error','Information'

 #Logs to search from DCOD.
 $LogSources = 'System', 'Application'
 
 $DateFormat = "yyyy-MM-dd"
 
 do {
	 try {$userInput = Read-Host "What date would you like to verify from the last 24 hours? In any date format you prefer."}
	 catch {"Invalid format."}
 } while (![boolean]($userInput -as [DateTime]))
  
 #Custom Folder name for logs.
 $FolderName = 'ExpressErrorLogs'
 $FolderPath = ".\$FolderName"

If(!(test-path $FolderPath))
{
      New-Item -ItemType Directory -Force -Path $FolderPath
}

 foreach($logSource in $LogSources){
	 #TODO: At server, detect from what computer name 
    #Name format: TODO(COMPUTER/SERVER NAME)_ServerName_logSource_Date.extension
    $fileName = $logSource + "_"+ [string][DateTime]::Parse($userInput).ToString("yyyy-MM-dd") + ".csv"
    $filePath = "$FolderPath\$fileName"

    If(!(test-path $filePath)){
        #TODO: Add server and select(for specific data) and last 24h of specified date
        Get-EventLog -LogName $logSource -EntryType $EventLog[1] | Export-Csv -Path $filePath }
}