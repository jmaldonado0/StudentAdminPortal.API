$taskName = "LogRetrievalScheduleTask"
$taskDescription = "Selects and Retrieves the Windows error event logs, and uploads it to a azure blob."
$taskArgs = "-EndPointUrl #{endPointUrl} -EndPointContainer #{endPointContainer} -Sas #{sas}"
$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $taskName}

if($taskExists)
{
    Write-Host "$taskName task already exists. Unregistering the existing task!"
	UnRegister-ScheduledTask -TaskName $taskName -Confirm:$false
}

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "#{deployPath}\LogRetrieval.ps1 $taskArgs"
$trigger = New-ScheduledTaskTrigger -Daily -At 10:35am#-Daily -At 12:00am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -TaskPath "#{Instance}\DuckCreek" -Description $taskDescription #-User '#{IdentUser}' -Password '#{IdentPass}'
Disable-ScheduledTask $taskName -TaskPath "#{Instance}\DuckCreek"