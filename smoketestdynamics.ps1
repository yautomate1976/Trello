Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$global:user_profile_path = $null
$global:script_dir = $null
$global:root_location = $null
$global:clone_project = $null
$global:collection = $null
$global:environment = $null
$global:report_name = $null
$global:ssh_file = $null

<# Set Environment()#>
Function set_environment()
{
    try {
        $Global:user_profile_path = $env:USERPROFILE  <# GLOBAL #>
        $Global:script_dir = Split-Path $script:MyInvocation.MyCommand.Path  <# GLOBAL #>        
        $Global:root_location = Get-Location  <# GLOBAL #>
        $script_path = $root_location.ToString() + "\Test"<# RETURN #>
        return $script_path
    }
    catch {
        $ErrorMessage = $._Exception.Message
        Write-Warning -Message "set_environment(): " + $ErrorMessage
    }
}

Function log_file()
{
    try {
        $log_file_name = Get-Date -Format "MM_dd_yyyy"
        $time_name = Get-Date -Format "HHmmss"
        $log_file = ".\" + $log_file_name + ".log"        
    }
    catch {
        $ErrorMessage = $._Exception.Message
        Write-Warning -Message "log_file(): " + $ErrorMessage
    }
}

<# Set INI Variables#>
Function set_ini_variables()
{
    try {
        $ini_file_content = Get-Content -Path ".\gitlab.ini"
        $global:remote_url = $ini_file_content[0].Split("=").Get(1)
        $global:clone_project = "& git clone " + $remote_url + " 2>&1"
        $global:collection = $ini_file_content[3].Split("=").Get(1)
        $global:environment = $ini_file_content[4].Split("=").Get(1)
        $global:report_name = $ini_file_content[5].Split("=").Get(1)        
        $global:ssh_file = $ini_file_content[6].Split("=").Get(1)
        return $ini_file_content
    }
    catch 
    {
        $e = $_.Exception
        Write-Host "get_ini_variables(): " $e.Message        
    }

}

Function verify_ssh()
{
    try {        
        $ssh_file_location = $user_profile_path + $ssh_file
    }
    catch { 
        $e = $_.Exception
        Write-Host "Verify_ssh(): " $e.Message        
    }
}

<# Generate Run Report #>
Function generate_run_report()
{
    try {
        $report_suffix = Get-Date -Format "_MM_dd_yyyy" 
        $report_results = $report_name + $report_suffix + "_" + $time_name + ".xml"
        $run_postman_test = "newman run -r junit --reporter-junit-export " + $report_results + " " + $collection + " -e " + $environment
        $report_dir = ".\Reports"
    }
    catch {        
        $ErrorMessage = $._Exception.Message
        Write-Warning -Message "verify_ssh(): " + $ErrorMessage
    }
}

Function get_branch()
{
    $get_branch = "&git rev-parse --abbrev-ref HEAD"
    return $get_branch
}

$iniContent = set_ini_variables
verify_ssh
$script_path = set_environment
Set-Location $script_dir


if (Test-Path $ssh_file_location -PathType leaf)
{
    if (!(Test-Path -Path $script_path))
    {        
        New-Item -ItemType Directory -Force -Path $script_path      
        Set-Location -Path $script_path         
        $clone_results = Invoke-Expression $clone_project
        Write-Host $clone_results.TargetObject
        Get-ChildItem -Path . -Name | Out-File $log_file -Append
        Write-Host "Executing Collection: " + $collection
        Invoke-Expression $run_postman_test        
        Write-Host "Completed Execution: " + $collection
        Write-host "Generated Report: " $report_results
        Write-host "Relocate Report..."
        Move-Item -Path $report_results -Destination $root_location -Force
        Set-Location $script_dir        
        Write-Host "Pushing Report: " + $report_results
        New-Item -ItemType Directory -Force -Path $report_dir
        Move-Item -Path $report_results -Destination $report_dir -Force 
        $branch = Invoke-Expression $get_branch        
        Invoke-Expression "&git config core.autocrlf false"
        $name_of_report = $report_results -split '.\\', 2
        $report = $report_dir + "\" + $name_of_report
        $report = $report.Replace(' ', '')        
        Invoke-Expression "&git add ."  -ErrorVariable bad_add -OutVariable succOut 2>&1 >$null
        Invoke-Expression "&git commit -m 'this is a test'" -ErrorVariable bad_commit -OutVariable succOut 2>&1 >$null
        Invoke-Expression "&git push" -ErrorVariable bad_push -OutVariable succOut 2>&1 >$null
        Write-Host "Pushed Report "                                        
    }    
    else {
        Write-Host "DIRECTORY EXIST: " $script_path
    }
}

<# Push Report #>
<# Delete Test #>