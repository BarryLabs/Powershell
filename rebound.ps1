<#Requires -RunAsAdministrator#>

$description = 'Rebound Restore-Point'

[bool]$isElevated = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isElevated)
{
  $rRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
  $rRegEntry = 'SystemRestorePointCreationFrequency'
  if ( Test-Path -Path $rRegKey )
  {
    if ( Get-ItemProperty -Path $rRegKey -Name $rRegEntry -ErrorAction SilentlyContinue )
    {
      $rRegValue = Get-ItemProperty -Path $rRegKey | Select-Object -ExpandProperty $rRegEntry
      if ( $rRegValue -eq 0 )
      {
        Write-Warning 'Unlimited Restore-Points are currently enabled.'
        Write-Host "`n"
        Write-Warning 'This is not an issue if you use this script as it will also handle your Restore-Points however be wary when not using this script. Your consumed storage due to Restore-Points could get out of hand.'
        Write-Host "`n"
        Write-Warning 'A benefit would be that you could manually set more than one Restore-Point within a day by default...but remember it would be outside of this script as well.'
        Write-Host "`n"
        Write-Warning 'If you choose to keep this disabled, you will be required to delete previous Restore-Points in order to create a new one.'
        Write-Host "`n"
        $regChoice = Read-Host 'Would you like to disable Unlimited Restore-Points or keep it enabled? (d/k)'
        if ( $regChoice -match "^d|D" )
        {
          REG DELETE "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /V "SystemRestorePointCreationFrequency" /F
          vssadmin.exe delete shadows /for=C: /all
          Checkpoint-Computer -Description $description
        }
        elseif ( $regChoice -match "^k|K" ) {
          Checkpoint-Computer -Description $description
        }
      }
    }
    else {
      Write-Warning 'Unlimited Restore-Points are currently disabled.'
      Write-Host "`n"
      Write-Warning 'If you choose to keep this disabled, you will be required to delete previous Restore-Points in order to create a new one.'
      Write-Host "`n"
      $regChoice = Read-Host 'Would you like to enable Unlimited Restore-Points or keep it disabled? (e/k)'
      if ( $regChoice -match "^e|E" )
      {
        Write-Warning 'You are now able to store multiple Restore-Points.'
        REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /V "SystemRestorePointCreationFrequency" /T REG_DWORD /D 0 /F
        Checkpoint-Computer -Description $description
      }
      elseif ( $regChoice -match "^k|K" )
      {
        vssadmin.exe delete shadows /for=C: /all
        Checkpoint-Computer -Description $description
      }
    }
  }
}
else
{
  Write-Warning 'Session is not elevated!'
  $eInput = Read-Host -Prompt 'Would you like to self-elevate? (y/n)'
  if ( $eInput -match "^y|Y")
  {
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}"' -f $MyInvocation.MyCommand.Path)
    exit
  }
  else
  {
    exit
  }
}
