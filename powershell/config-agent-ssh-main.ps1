<#
.SYNOPSIS
  Configure jenkins agent windows
 
.DESCRIPTION  
  Configure jenkins agent windows
  
.OUTPUTS
  none
 
.NOTES
  Version:        1.2
  Author:         D. Kapitsev
  Creation Date:  31 july 2023
  Purpose/Change: -
#>
 
# Configuration
 
$logFile = "C:\\Temp\\config-log.txt"
 
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
}
 
Function ConfigureAgent {
    process {
      try {
        Write-Log -message "$env:COMPUTERNAME - Setting up sshd & sshagent services startup type & firewall rules"
        Write-Log -message "#########"
        ConfiguringSSH
      }catch{
        Write-log -message "Script execution failed" -level "ERROR"
      }
    }   
}
 
Write-Log -message "#########"
 
Function ConfiguringSSH {
    process {
        try {
            # Create dir for log file
            New-Item -Type Directory "C:\Temp" -ErrorAction SilentlyContinue
             # Start sshd service
            Write-Log -message "Starting sshd service"
            Start-Service -Name sshd, ssh-agent -Verbose
            Write-Log -message "Set automatic StartupType"
            # Copy sshd default config
            $services=gsv | ?{$_.Name -like '*ssh*'}
            foreach ($service in $services)
            {
                $service | Start-Service | Set-Service -StartupType Automatic
            }
            Write-Log -message "Configuring sshd"
            $content = Get-Content -Path "C:\ProgramData\ssh\sshd_config" ; `
            $content | ForEach-Object { $_ -replace '#PermitRootLogin.*','PermitRootLogin no' `
                                -replace '#PasswordAuthentication.*','PasswordAuthentication no' `
                                -replace '#PermitEmptyPasswords.*','PermitEmptyPasswords no' `
                                -replace '#PubkeyAuthentication.*','PubkeyAuthentication yes' `
                                -replace '#SyslogFacility.*','SyslogFacility LOCAL0' `
                                -replace '#LogLevel.*','LogLevel INFO' `
                                -replace 'Match Group administrators','' `
                                #-replace '(\s*)AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys','' `
                        } | `
                 Set-Content -Path "C:\ProgramData\ssh\sshd_config" ; `
                 Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value 'ChallengeResponseAuthentication no' ;
                 Write-Log -message "Adding ssh key by ssh-add"
                 ssh-add  C:\Users\powershellrunner\.ssh\id_rsa
 
 
# Firewall rule
Write-Log -message "Setting up firewall rule"
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22`
} else {
    Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
}
    Write-Log -message "Restart sshd service"
    Restart-Service -Name sshd
    } catch {
     Write-log -message "Starting sshd service failed" -level "ERROR"
    }
}
}
ConfigureAgent
Write-Log -message "End of script"
