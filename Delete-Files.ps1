<#
.SYNOPSIS
  Script to remove files older than 30 days
.DESCRIPTION
  Script to remove files older than 30 days
.PARAMETER <Parameter_Name>
  NONE
.INPUTS
  NONE
.OUTPUTS Log File
 Log File
.NOTES
  Version:        1.0
  Author:         jduarte
  Creation Date:  Thu May 10 08:37:46 CDT 2018
  Purpose/Change: Initial Script
.EXAMPLE
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
    [Parameter(Mandatory=$True)] [string]$FileDirectory,
    [Parameter(Mandatory=$True)] [string]$DaysOld,
    [Parameter(Mandatory=$false)] [string]$FileName,
    [Parameter(mandatory=$false)] [Int]$LeaveNumberOfFiles,
    [Parameter(mandatory=$false)] [switch]$RunningLog
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
#Import Modules & Snap-ins

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Any Global Declarations go here
$computerName = $env:COMPUTERNAME
$ScriptRoot=$PSScriptRoot
$ScriptLogTime = Get-Date -format "yyyyMMddmmss"
$ScriptName = (Get-Item $PSCommandPath).Basename
$LogDirectory = $ScriptRoot
$PSVersionReturned=$PSVersionTable.PSVersion
$Date = Get-Date

if($RunningLog){
    $ScriptLog= "$ScriptRoot\$ScriptName`_$ScriptLogTime.log"
}else {
    $ScriptLog= "$ScriptRoot\$ScriptName.log"
}
#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Script_Information {
    param (
  )
    $Date.DateTime
    Write-Output "Computer Name: $computerName"
    Write-Output "PowerShell Version $PSVersionReturned"
    Write-Output "ScriptRoot: $ScriptRoot"
    Write-Output "ScriptName: $ScriptName"
    Write-output "ScriptLog: $ScriptLog"

}

Function Main{
    Begin {
        $StopWatch = [System.diagnostics.stopwatch]::StartNew()
        Write-Output "Attempting to delete files"
        Script_Information
    }
    Process{
        #Variables
        $limit = ((Get-date).AddDays(-$DaysOld)).date

        if ($FileName){
            $FilesToDelete = Get-ChildItem -Path $FileDirectory |  Where-Object {-not $_.PSIsContainer -and $_.LastWriteTime -lt $Limit -and $_.Name -like "$FileName"} | Select-Object -Property FullName,PSIsContainer,PSComputerName,LastWriteTime,CreationTime
        }else{
            Write-Output "No file name or pattern was passed. This will delete directories also"
            $FilesToDelete = Get-ChildItem -Path $FileDirectory |  Where-Object { $_.LastWriteTime -lt $Limit } | Select-Object -Property FullName,PSIsContainer,PSComputerName,LastWriteTime,CreationTime
        }

        $cnt=$FilesToDelete | Measure-Object | Select-Object -ExpandProperty count

        if(-not $LeaveNumberOfFiles){
            $LeaveNumberOfFiles = 0
        }else{
            Write-Output "Number of files specified to not delete: $leavenumberofFiles"
        }

        #Show Info
        Write-output "FileName: $FileName"
        Write-output "File Directoy Passed: $FileDirectory"
        Write-Output "Number of Files found to be deleted: $cnt`n"
        Write-Output "Age Limit: $DaysOld"
        Write-Output "Files older than $limit will be deleted"
        Write-Output "Found $cnt files to delete"

        If ( $cnt -gt $LeaveNumberOfFiles ) {

            ForEach ($File in $FilesToDelete) {

                # Add a default delete status of false.  This changes if Remove-Item is successful
                $DeletedStatus = $False
                Try {
                    write-output "Attempting to clean up files`n"
                    Remove-Item -Path $File.FullName -Recurse -Force -ErrorAction Stop
                    # This line will only run if Remove-Item doesn't error
                    $DeletedStatus = $True
                }
                Catch {
                    # So you could capture the actual error here and output it as another property below
                    # or just ignore it and count on figuring out why something didn't delete manually later
                    # The easy step here would be to just add the property right away:

                    $File | Add-Member -Name 'DeletedError' -MemberType NoteProperty -Value $PSItem.Exception.Message
                }

                # You can use Add-Member to add properties to an existing variable.  In this case
                # we add a 'Deleted' property with a value of True or False depending on the Try/Catch
                # above.
                $File | Add-Member -Name 'Deleted' -MemberType NoteProperty -Value $DeletedStatus
                $File
            }
        }
    }

    End{
        If ($?) {
            Write-output "Successfully attempted to clean up log files on all Viero servers older than $Limit in directory path $FileDirectory"
            $StopWatch.Stop()
            Write-Output "Elapsed Seconds $($StopWatch.Elapsed.TotalSeconds)"
        }
    }

}


#-----------------------------------------------------------[Execution]------------------------------------------------------------
#Script Execution goes here
Main *>&1 | Tee-Object $ScriptLog
