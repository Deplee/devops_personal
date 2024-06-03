<#
.SYNOPSIS
  Configure jenkins agent windows
    
.DESCRIPTION
  Configure jenkins agent windows
     
.OUTPUTS
  none
    
.NOTES
  Version:        1.3
  Author:         D. Kapitsev
  Creation Date:  12/09/2023
  Purpose/Change: -
#>
    
# Configuration
    
$logFile = "C:\\Temp\\config-log.txt"
$username = "user"
$port = 22 
$agentPath= "D:\\ssh-jenkins-agent"
  
Function Write-Log {
  param(
      [Parameter(Mandatory = $true)][string] $message,
      [Parameter(Mandatory = $false)]
      [ValidateSet("INFO","WARN","ERROR")]
      [string] $level = "INFO"
  )
  # Create timestamp
  $timestamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    
  # Append content to log file
  Add-Content -Path $logFile -Value "$timestamp [$level] - $message"
  Write-Host "$timestamp [$level] - $message"
}
    
Function ConfigureAgent {
    process {
      try {
       Write-log -message "Installing OpenSSH client & server" -level "INFO"
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
        Write-Log -message "$env:COMPUTERNAME - OpenSSH client & server installed" -level "INFO"
        Write-Log -message "#########"
        ConfiguringSSH
      }catch{
        Write-log -message "Script execution failed" -level "ERROR"
      }
    }
}
# Закоментил, т.к. при первом запуске файл $logFile еще не создан и сыпится ошибка.
# Write-Log -message "#########"
  
Function preparation{
    process {
        try {
            # Create dir for log file
            New-Item -Type Directory "C:\Temp" -ErrorAction SilentlyContinue
            # Create dir for agent workspace
            New-Item -Type Directory ${agentPath} -ErrorAction SilentlyContinue
            # Create ssh agent dir
            New-Item -Type Directory C:\Users\${username}\.ssh -ErrorAction SilentlyContinue
            Write-Host "Now authorized_keys to C:\Users\${username}\.ssh and  run script again,than choose 2 - for configure jenkins SSH windows build agent"
        } catch {
            Write-log -message "Step Preparaion failed" -level "ERROR"
        }
  
    }
}
  
  
Function ConfiguringSSH {
    process {
        try {
             # Start sshd service, automatic create ssh config files
            Write-Log -message "Starting sshd service"
            Start-Service -Name sshd, ssh-agent -Verbose
            Write-Log -message "Set automatic StartupType"
            # Copy sshd default config
            $services=gsv | ?{$_.Name -like '*ssh*'}
            foreach ($service in $services)
            {
                $service | Set-Service -StartupType Automatic | Start-Service
            }
            Write-Log -message "Configuring sshd"
            $content = Get-Content -Path "C:\ProgramData\ssh\sshd_config" ; `
            $content | ForEach-Object { $_ -replace '#PermitRootLogin.*','PermitRootLogin no' `
                                -replace '#PasswordAuthentication.*','PasswordAuthentication no' `
                                -replace '#PermitEmptyPasswords.*','PermitEmptyPasswords no' `
                                -replace '#PubkeyAuthentication.*','PubkeyAuthentication yes' `
                                -replace '#SyslogFacility.*','SyslogFacility LOCAL0' `
                                -replace '#LogLevel.*','LogLevel INFO' `
                                -replace "#Port.*","Port ${port}" `
                                -replace 'Match Group administrators','' `
                                #-replace '(\s*)AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys','' `
                        } | `
                 Set-Content -Path "C:\ProgramData\ssh\sshd_config" ; `
                 Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value 'ChallengeResponseAuthentication no' ;
# Агент не должен ходить по ssh поэтому ремим строки
#                 Write-Log -message "Adding ssh key by ssh-add"
#                 ssh-add  C:\Users\${username}\.ssh\id_rsa
    
    
                 # Firewall rule
                 Write-Log -message "Setting up firewall rule"
                 if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
                     Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
                     New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort ${port}
                 } else {
                     Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists. Change Port to ${port}"
                     Set-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -LocalPort ${port}
                 }
                     Write-Log -message "Restart sshd service"
                     Restart-Service -Name sshd
    } catch {
     Write-log -message "Starting sshd service failed" -level "ERROR"
    }
}
}
  
#ConfigureAgent
$step = Read-Host "Enter 1 or 2 for select step"
switch ($step)
    {
        1 { preparation }
        2 { ConfigureAgent }
        default { Write-Host "Choose 1 - for preparation or 2 - for configure agent (after prepartion step only)" }
    }
  
Write-Log -message "End of script"
