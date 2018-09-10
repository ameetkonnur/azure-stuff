$count = 0
mkdir "D:\Logs1"
$logPath = 'D:\Logs1\file.txt'
"Writing Logs" | Out-File $logPath

"---check in a loop untill the curent VM of VMSS is domain joined. If no, don't attach Windows 2016 S2D." |  Out-File $logPath -Append
while ( ! (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain)
{
  Start-Sleep -s 5 
   $Count++
   "domain join check retry count - " + $count |  Out-File $logPath -Append
}
"---Computer is now domain joined. Run the extension of attaching Windows 2016 S2D shared storage..."|  Out-File $logPath -Append


$user = "domain\user"
$pass = "domain-password"
net localgroup Administrators /add $user

#add local user
#$userlocal = "appuser1"
#$passlocal = "root1234567!"
#net user /add $userlocal $passlocal
#net localgroup Administrators /add $userlocal

#add local user
$userlocal = "bflbotvmssstorage"
$passlocal = "8FGr14hsNK5ApN+Sro4k2A7q4sUhRoEOepL2ix5aa2PhjlzKsFxfzypyIv6olBQyPDpvBtn7L1lK5GYF05BU3w=="
net user /add $userlocal $passlocal /Y
Set-LocalUser -Name “bflbotvmssstorage” -PasswordNeverExpires 1
net localgroup Administrators /add $userlocal
net localgroup IIS_IUSRS /add $userlocal

$folderPath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension"
#$mapFileScriptPath = Get-ChildItem -Path $folderPath -Filter mapfile.ps1 -Recurse -ErrorAction SilentlyContinue -Force
$certificatePath = Get-ChildItem -Path $folderPath -Filter "Intermediate.cer" -Recurse -ErrorAction SilentlyContinue -Force
$certificatePathrootca = Get-ChildItem -Path $folderPath -Filter "Root CA.cer" -Recurse -ErrorAction SilentlyContinue -Force
$certificatePathbot = Get-ChildItem -Path $folderPath -Filter "bot.bajajfinserv.in.cer" -Recurse -ErrorAction SilentlyContinue -Force
$logPath = 'D:\Logs1\file.txt'

"execution started" | out-file $logpath -Append

Install-IntermediateCertificateFromUrl $certificatePath.FullName
Install-IntermediateCertificateFromUrl $certificatePathrootca.FullName
Install-IntermediateCertificateFromUrl $certificatePathbot.FullName

Import-Module WebAdministration
Set-ItemProperty 'IIS:\Sites\Chatbotapp\' -name physicalPath -value "\\bflbotvmssstorage.file.core.windows.net\bfl-sofs\data\ChatbotApp"
        #$iisSitePath = "IIS:\Sites\" + "ChatbotApp"
        #$website = get-item $iisSitePath
        #$website.virtualDirectoryDefaults.userName = $userlocal
        #$website.virtualDirectoryDefaults.password = $passlocal
        #$website | set-item
        set-webconfigurationproperty "system.applicationHost/sites/site[@name='ChatbotApp']/application[@path='/']/virtualDirectory[@path='/']" -name username -value $userlocal
        set-webconfigurationproperty "system.applicationHost/sites/site[@name='ChatbotApp']/application[@path='/']/virtualDirectory[@path='/']" -name password -value $passlocal

        #"website identity completed" | out-file $logpath -Append

        Set-ItemProperty  IIS:\AppPools\ChatbotApp  -name  processModel  -value  @{userName=$userlocal;password=$passlocal;identitytype=3}

        Start-WebAppPool -Name "ChatbotApp"
        "app pool restart and identity completed" | out-file $logpath -Append
        #"---web admin done" |  Out-File $logPath -Append
        #iisreset /restart
        #"---IIS restarted" |  Out-File $logPath -Append
    cd C:\Windows\Microsoft.NET\Framework64\v4.0.30319
   .\CasPol.exe -polchgprompt off
   .\CasPol.exe -m -force -ag 1 -url file://\\bflbotvmssstorage.file.core.windows.net\bfl-sofs\data\* FullTrust 


#If(!(Test-Path Z:))
#{
 #   try
  #  {
   #     cmdkey /add:bflbotvmssstorage.file.core.windows.net /user:AZURE\bflbotvmssstorage /pass:8FGr14hsNK5ApN+Sro4k2A7q4sUhRoEOepL2ix5aa2PhjlzKsFxfzypyIv6olBQyPDpvBtn7L1lK5GYF05BU3w==
    #    net use Z: \\bflbotvmssstorage.file.core.windows.net\bfl-sofs
     #   "net use completed" | out-file $logpath -Append 
    #}
    #Catch
    #{
    #    $ErrorMessage = $_.Exception.Message
     #   "---"+ $ErrorMessage | Out-File 'D:\Logs1\file.txt' -Append
    #}
#}

#$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $mapFileScriptPath.FullName
#The action of creating the CMDKEY;

#$trigger = new-ScheduledTaskTrigger -AtStartup 

#Register-ScheduledTask -Action $action -TaskName "cmdkey" -Description "Create cmdkey and map Azure File" -User $userlocal -Password $passlocal -Trigger $trigger
#Create the task, cmdkey, in Task Scheduler without Trigger option with the certification of the specific user. You can check that in the Task Scheduler;

#Start-ScheduledTask -TaskName "cmdkey"
#Use command to trigger the execution of the task, the cmdkey will be created under the specific user;
#"---Scheduled task creation completed" |  Out-File $logPath -Append