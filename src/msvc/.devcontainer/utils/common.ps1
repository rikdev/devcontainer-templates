#Requires -Version 5.1

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$workDirectory = Split-Path -Path $PSScriptRoot -Parent
$devcontainerSettings = Get-Content -Path "$workDirectory/devcontainer.json" -Raw | ConvertFrom-Json
