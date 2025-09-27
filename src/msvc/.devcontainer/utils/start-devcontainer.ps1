param(
    [ValidateRange(1,65535)]
    [int]$SshPort = 22
)

. "$PSScriptRoot/common.ps1"

try {
    Push-Location -Path $workDirectory

    Start-Process -Wait -NoNewWindow `
        -FilePath 'docker' `
        -ArgumentList `
            'compose', ($devcontainerSettings.dockerComposeFile.ForEach{ "--file $PSItem" } -join ' '), `
            "run --build --publish ${SshPort}:22", $devcontainerSettings.service
}
finally {
    Pop-Location
}
