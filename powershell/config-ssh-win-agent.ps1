<#
.SYNOPSIS
  Configure jenkins agent windows
 
.DESCRIPTION   Configure jenkins agent windows
  
.OUTPUTS
  none
 
.NOTES
  Version:        1.2
  Author:         D. Kapitsev
  Creation Date:  31 july 2023
  Purpose/Change: -
#>

# Configuration
# $username = "jenkins"   # UserName
# #$fullName = "jenkins Test User" # Full name
# #$logFile = "\\server\folder\log.txt"
$logFile = "C:\\Temp\\user-log.txt"
# $password = Read-Host -AsSecureString

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

# Function CreateLocalUser {
#     process {
#       try {
#         New-Item -Type Directory "C:\Temp" -ErrorAction SilentlyContinue
#         New-LocalUser "$username" -Password $password -FullName "$fullname" -Description "jenkins local user" #-ErrorAction stop
#         Write-Log -message "$username jenkins local user created"

#         # Add new user to administrator group
#         Add-LocalGroupMember -Group "Users" -Member "$username" -ErrorAction stop
#       } catch {
#         Write-log -message "Creating jenkins local account failed" -level "ERROR"
#       }
#     }
# }
Function ConfigureAgent {
    process {
      try {
        # CreateLocalUser
        # Write-Log -message "$username added to the local users group"
        # Write-Log -message "#########"
        Write-Log -message "$env:COMPUTERNAME - Setting up sshd & sshagent services startup type & firewall rules"
        Write-Log -message "#########"
        ConfiguringSSH
        # Write-Log -message "#########"
        # Write-Log -message "$env:COMPUTERNAME - Changing jenkins user home directory ACL"
        # Write-Log -message "#########"
        # ChangeDirACL
      }catch{
        Write-log -message "Script execution failed" -level "ERROR"
      }
    }    
}

# Enter the password
#Write-Host "Enter the password for the local user account" -ForegroundColor Cyan
#$password = Read-Host -AsSecureString

Write-Log -message "#########"
#Write-Log -message "$env:COMPUTERNAME - Create jenkins local user account"
Write-Log -message "#########"


Function ConfiguringSSH {
    process {
        try {
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
                # Write-Log -message "Copying keys"
                # $EncFileKey = "$file"
                # $DestFileKey = "C:\Users\powershellrunner\.ssh\id_rsa"
                # $EncFileAuth = "$pwd\file-auth"
                # $DestFileAuth = "C:\Users\powershellrunner\.ssh\authorized_keys"
                # Copy-Item -Path "C:\ProgramData\ssh\ssh_host_dsa_key" -Destination $DestFileKey
                # Copy-Item -Path "C:\ProgramData\ssh\ssh_host_dsa_key" -Destination $DestFileAuth
                # Write-Log -message "Decoding file"
                # function encode{
                # [convert]::ToBase64String((Get-Content -path $def_file -Encoding byte)) | Out-File $encoded_file
                # }
                # encode
                # [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String((Get-Content -path $EncFileKey ))) | Out-File $DestFileKey
                # [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String((Get-Content -path $EncFileAuth ))) | Out-File $DestFileAuth
                # Write-Log -message "Adding ssh key by ssh-add"
                ssh-add  C:\Users\powershellrunner\.ssh\id_rsa
                #Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value 'HostKeyAgent \\.\pipe\openssh-ssh-agent' ; `
                #Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value ('Match User {0}' -f $username) ; `
                #Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value ('       AuthorizedKeysFile C:/Users/{0}/.ssh/authorized_keys' -f $username) ; `

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

# # Changing ACL for jenkins user
# Function ChangeDirACL {
#     process {
#         try {
#             #считываем текущий список ACL папки
#             $acl = Get-Acl "C:\Users\powershellrunner\.ssh"
#             #Cоздаем переменную с указанием пользователя, прав доступа и типа разрешения
#             $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule ("jenkins","FullControl","ContainerInherit,ObjectInherit","None","Allow")
#             #Передаем переменную в класс FileSystemAccessRule для создания объекта
#             $acl.SetAccessRule($AccessRule);
#             #Применяем разрешения к папке
#             $acl | Set-Acl C:\Users\powershellrunner\.ssh;
#             Write-Log -message "Changing jenkins home directory ACL complete"
#         } catch {
#             Write-log -message "Changing ACL failed" -level "ERROR"
#         }
#     }
# }

#ChangeDirACL
ConfigureAgent
Write-Log -message "End of script"
