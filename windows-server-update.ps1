#Creates a scheduled task for once a week, Saturday at 3AM, does not run task until scheduled time.
$TaskExists = Get-ScheduledTask -TaskName "Windows Update Checker"
if (-not $TaskExists) {
	Write-Output "Creating Scheduled Task"
	$TaskAction = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument “-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File C:\Scripts\windows-update-checker.ps1"
	$TaskTrigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Saturday -At 3am
	Register-ScheduledTask "Windows Update Checker" -Action $TaskAction -Trigger $TaskTrigger
	Start-Sleep -Seconds 5
} elseif ($TaskExists) {
	# Sets security protocol to TLS 1.2 as Windows Server defaults to 1.0 which doesn't work for getting modules
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	# Ensure NuGet and PSWindowsUpdate module is installed
	if (-not (Get-Module -ListAvailable -Name NuGet)) {
		Write-Output "Installing NuGet"
		Install-PackageProvider -Name NuGet -Force -SkipPublisherCheck
	}

	if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
		Write-Output "Installing PSWindowsUpdate"
		Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck
	}
	#Imports into the current session
	Import-Module PSWindowsUpdate

	#Check available updates
	$Updates = Get-WindowsUpdate -MicrosoftUpdate -IgnoreUserInput -Confirm:$false
	if ($Updates) {
		Write-Output "Available Updates:"
		$Updates | Format-Table -Property KBArticle, Title
		Start-Sleep -Seconds 5
		Install-WindowsUpdate -AcceptAll -AutoReboot
	}
	#To check history of updates run this
	#Get-WUHistory
} #https://github.com/OddPrograms/PSWindowsServerCoreUpdateTask