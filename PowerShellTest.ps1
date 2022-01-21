 #TODO: Delete and replaced with just error, after testing is done.
 $EventLog = 'Error','Information'
  
 #Logs to search from DCOD.
 $LogSources = 'System', 'Application'
  
 $SaveDateFormat = "yyyy-MM-dd"
 
 $FolderName = 'ErrorLogs'
 
 $QuitKeys = 'no', 'q'
 
 "(Type "+ ($QuitKeys -join " or ") + " to exit)"
 do {
	 do {
		 try {$UserInput = Read-Host "What date would you like to verify from the last 24 hours? In any date format you prefer" 
			  if($QuitKeys.Contains($UserInput.Trim().ToLower())) {Exit}
			 }
		 catch {"Invalid format."}
	 } while (![boolean]($UserInput -as [DateTime]))
	 
	 "From date " + ([DateTime]($UserInput)).AddDays(-1) + " to $UserInput"
	  
	 $FolderPath = ".\$FolderName"

	 If(!(test-path $FolderPath))
	 {
		New-Item -ItemType Directory -Force -Path $FolderPath
	 }
	 
	 foreach($logSource in $LogSources){
		#Name format: Computer/ServerName_logSource_Date.extension
		$fileName = $env:computername + "_" + $logSource + "_"+ [string][DateTime]::Parse($UserInput).ToString($SaveDateFormat) + ".csv"
		$filePath = "$FolderPath\$fileName"

		If(!(test-path $filePath)){
			Get-EventLog -LogName $logSource -EntryType $EventLog[1] -After ([DateTime]($UserInput)).AddDays(-1) -Before ([DateTime]($UserInput)).AddDays(1) |
			Export-Csv -Path $filePath
		}
	}
	"Process Done`n`n"
}while($true)