. "$PSScriptRoot/common.ps1"

$customizations = $devcontainerSettings.customizations.vscode

if ($customizations.extensions) {
    Write-Host 'Installing extensions: ' $customizations.extensions.ForEach{ "`n  - $PSItem" }
    Start-Process -Wait -NoNewWindow `
        -FilePath 'code' `
        -ArgumentList $customizations.extensions.ForEach{ "--install-extension $PSItem" }
}

& {
    $vscodeSettingsPath = "$env:USERPROFILE/.vscode-server/data/Machine/settings.json"
    $vscodeSettings = [PSCustomObject]@{}
    if (Test-Path $vscodeSettingsPath -PathType Leaf) {
        $vscodeSettings = Get-Content -Path $vscodeSettingsPath -Raw | ConvertFrom-Json
    }
    Write-Host "Applying settings:`n" ($customizations.settings | ConvertTo-Json)
    foreach ($member in $customizations.settings | Get-Member -MemberType NoteProperty) {
        $name  = $member.Name
        $value = $customizations.settings.$name
        $vscodeSettings | Add-Member -Force -NotePropertyName $name -NotePropertyValue $value
    }

    $vscodeSettings | ConvertTo-Json | Set-Content -Path $vscodeSettingsPath
}
