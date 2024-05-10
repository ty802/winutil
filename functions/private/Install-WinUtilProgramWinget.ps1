Function Install-WinUtilProgramWinget {

    <#
    .SYNOPSIS
        Manages the provided programs using Winget

    .PARAMETER ProgramsToInstall
        A list of programs to manage

    .PARAMETER manage
        The action to perform on the programs, can be either 'Installing' or 'Uninstalling'

    .NOTES
        The triple quotes are required any time you need a " in a normal script block.
    #>

    param(
        $ProgramsToInstall,
        $manage = "Installing"
    )
    
    $x = 0
    $count = $ProgramsToInstall.Count

    Write-Progress -Activity "$manage Applications" -Status "Starting" -PercentComplete 0

    Foreach ($Program in $ProgramsToInstall){
        $failedPackages = @()
        Write-Progress -Activity "$manage Applications" -Status "$manage $($Program.winget) $($x + 1) of $count" -PercentComplete $($x/$count*100)
        if($manage -eq "Installing"){
            # Install package via ID, if it fails try again with different scope and then with an unelevated prompt. 
            # Since Install-WinGetPackage might not be directly available, we use winget install command as a workaround.
            # Winget, not all installers honor any of the following: System-wide, User Installs, or Unelevated Prompt OR Silent Install Mode.
            # This is up to the individual package maintainers to enable these options. Aka. not as clean as Linux Package Managers.
            try {
                $status = $(Start-Process -FilePath "winget" -ArgumentList "install --id $($Program.winget) --silent --accept-source-agreements --accept-package-agreements" -Wait -PassThru).ExitCode
                if($status -eq 0){
                    Write-Host "$($Program.winget) installed successfully."
                    continue
                }
                Write-Host "Attempt with User scope"
                $status = $(Start-Process -FilePath "winget" -ArgumentList "install --id $($Program.winget) --scope user --silent --accept-source-agreements --accept-package-agreements" -Wait -PassThru).ExitCode
                if($status -eq 0){
                    Write-Host "$($Program.winget) installed successfully with User scope."
                    continue
                }
                <# Write-Host "Attempt with Unelevated prompt"
                $process = Start-Process -FilePath "powershell" -ArgumentList "-Command Start-Process winget -ArgumentList 'install --id $($Program.winget) --silent --accept-source-agreements --accept-package-agreements' -Verb runAsUser" -Wait -PassThru
                if($process.ExitCode -eq 0){
                    Write-Host "$($Program.winget) installed successfully with Unelevated prompt."
                    continue
                } #>
                Write-Host "Failed to install $($Program.winget). With winget"
                $failedPackages += $($Program.winget)
            } catch {
                Write-Host "Failed to install $($Program.winget) due to an error: $_"
                $failedPackages += $($Program.winget)
                }
        }
        if($manage -eq "Uninstalling"){
            # Uninstall package via ID using winget directly.
            try {
                $status = $(Start-Process -FilePath "winget" -ArgumentList "uninstall --id $($Program.winget) --silent" -Wait -PassThru).ExitCode
                if($status -ne 0){
                    Write-Host "Failed to uninstall $($Program.winget)."
                } else {
                    Write-Host "$($Program.winget) uninstalled successfully."
                    $failedPackages += $($Program.winget)
                }
            } catch {
                Write-Host "Failed to uninstall $($Program.winget) due to an error: $_"
                $failedPackages += $($Program.winget)
            }
        }
        $X++
    }
    Write-Progress -Activity "$manage Applications" -Status "Finished" -Completed
    return $failedPackages;
}
