FROM mcr.microsoft.com/windows/servercore:ltsc2025

ARG USER_NAME=User

SHELL ["powershell", "-Command", \
    "Set-StrictMode -Version 3.0; \
    $ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; \
    function Download-File($Uri, $OutFile, $Hash) { \
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile; \
        if (($null -ne $Hash) -and ((Get-FileHash -Path $OutFile -Algorithm SHA256).Hash -ne $Hash)) { \
            Write-Error \\\"Invalid hash for file '$OutFile'\\\" \
        }; \
    };"]

# SSH server for remote development tools
RUN \
    Write-Host 'Configuring SSH server...'; \
    Set-Service -Name 'sshd' -StartupType Automatic; \
    # SSH authentication is disabled for the ${USER_NAME} account,
    # so container access security must be enforced externally
    Add-Content \
        -Path \"$env:ProgramData/ssh/sshd_config\" \
        -Value ( \
            \"AllowUsers $env:USER_NAME`n\" + \
            \"AuthenticationMethods none`n\" + \
            \"PermitEmptyPasswords yes`n\"); \
\
    Write-Host 'Creating new user...'; \
    New-LocalUser -Name \"$env:USER_NAME\" -NoPassword; \
    Add-LocalGroupMember -Group 'Administrators' -Member \"$env:USER_NAME\"; \
    &{ \
        $user = [ADSI]\"WinNT://./$env:USER_NAME,User\"; \
        $user.PasswordExpired = 0; \
        $user.SetInfo(); \
    } \
    # Create home directory
    Start-Process -Wait -NoNewWindow \
        -FilePath 'powershell' \
        -ArgumentList '-NoLogo -NoProfile -NonInteractive -Command \"\"' \
        -Credential \
            (New-Object \
                -TypeName 'System.Management.Automation.PSCredential' \
                -ArgumentList \"$env:USER_NAME\", (New-Object System.Security.SecureString));
EXPOSE 22

RUN \
    Download-File \
        # https://learn.microsoft.com/en-us/visualstudio/releases/2026/release-history#release-dates-and-build-numbers
        -Uri 'https://download.visualstudio.microsoft.com/download/pr/e2958987-8ee9-4455-a511-38b57476c363/295f41e6627b8c6cb651d90fec24fa5718116cbe8a5511c35c84a7c356712d9f/vs_BuildTools.exe' \
        -OutFile 'vs_buildtools.exe' \
        -Hash '295f41e6627b8c6cb651d90fec24fa5718116cbe8a5511c35c84a7c356712d9f'; \
    Start-Process -Wait -NoNewWindow \
        -FilePath 'vs_buildtools.exe' \
        -ArgumentList \
            # https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools
            '--add Microsoft.VisualStudio.Component.VC.14.44.17.14.x86.x64', \
            '--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64', \
            '--add Microsoft.VisualStudio.Component.Windows11SDK.26100', \
            '--quiet', '--wait', '--norestart', '--nocache'; \
    Remove-Item -Path 'vs_buildtools.exe', \"$env:TEMP/*\" -Recurse -Force; \
    New-Item \
        -Path 'C:/BuildTools' \
        -ItemType SymbolicLink \
        -Value \"${env:ProgramFiles(x86)}/Microsoft Visual Studio/18/BuildTools\"

ENV CCACHE_DIR='C:\.ccache' \
    CCACHE_TEMPDIR='C:\ccache-tmp' \
    CONAN_HOME='C:\.conan2'

# Updating utilities should't change the mtime of the VC
RUN \
    Write-Host 'Installing CMake...'; \
    Download-File \
        -Uri 'https://github.com/Kitware/CMake/releases/download/v4.2.3/cmake-4.2.3-windows-x86_64.msi' \
        -OutFile 'cmake.msi' \
        -Hash 'aa84ae115fc962c6691ec972548c7f7435bd9e7696c9d0487c8bd3a285277ed6'; \
    Start-Process -Wait -NoNewWindow \
        -FilePath 'msiexec' \
        -ArgumentList '/quiet /norestart /package cmake.msi ADD_CMAKE_TO_PATH=System'; \
    Remove-Item -Path 'cmake.msi'; \
\
    Write-Host 'Installing Ninja...'; \
    Download-File \
        -Uri 'https://github.com/ninja-build/ninja/releases/download/v1.13.2/ninja-win.zip' \
        -OutFile 'ninja.zip' \
        -Hash '07fc8261b42b20e71d1720b39068c2e14ffcee6396b76fb7a795fb460b78dc65'; \
    Expand-Archive -Path 'ninja.zip' -DestinationPath \"$env:ProgramFiles/Ninja\"; \
    Remove-Item -Path 'ninja.zip'; \
    [Environment]::SetEnvironmentVariable( \
        'Path', \
        [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine) + \";$env:ProgramFiles\Ninja\", \
        [EnvironmentVariableTarget]::Machine); \
\
    Write-Host 'Installing ccache...'; \
    Download-File \
        -Uri 'https://github.com/ccache/ccache/releases/download/v4.13.1/ccache-4.13.1-windows-x86_64.zip' \
        -OutFile 'ccache.zip' \
        -Hash '1c78a0b816a3174d4b170b96294e016a21fb4a577dfd8361e7322f77f85c6348'; \
    Expand-Archive -Path 'ccache.zip' -DestinationPath \"$env:ProgramFiles\"; \
    Move-Item -Path \"$env:ProgramFiles/ccache-*\" -Destination \"$env:ProgramFiles/ccache\"; \
    Remove-Item -Path 'ccache.zip', \"$env:ProgramFiles/ccache/*\" -Exclude '*.exe' -Recurse -Force; \
    [Environment]::SetEnvironmentVariable( \
        'Path', \
        [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine) + \";$env:ProgramFiles\ccache\", \
        [EnvironmentVariableTarget]::Machine); \
\
    Write-Host 'Installing Git...'; \
    Download-File \
        -Uri 'https://github.com/git-for-windows/git/releases/download/v2.53.0.windows.2/Git-2.53.0.2-64-bit.tar.bz2' \
        -OutFile 'git.tar.bz2' \
        -Hash 'b17726d9b0041463a9e7b2bb98103cd6a18447d73b65e7b60c43e7d2fb5dea22'; \
    New-Item -Path \"$env:ProgramFiles\" -Name 'Git' -ItemType 'directory'; \
    Start-Process -Wait -NoNewWindow \
        -FilePath 'tar' \
        -ArgumentList \
            '--extract', \
            '--file=git.tar.bz2', \
            \"--directory=`\"$env:ProgramFiles/Git`\"\"; \
    Remove-Item -Path 'git.tar.bz2'; \
    Remove-Item -Path \"$env:ProgramFiles/Git/usr/bin/ssh*.exe\"; \
    Add-Content -Path \"$env:ProgramFiles/Git/etc/gitconfig\" -Value \"[safe]`n`tdirectory = *\"; \
    [Environment]::SetEnvironmentVariable( \
        'Path', \
        [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine) + \";$env:ProgramFiles\Git\bin\", \
        [EnvironmentVariableTarget]::Machine); \
\
    Write-Host 'Installing Python...'; \
    Download-File \
        -Uri 'https://www.python.org/ftp/python/3.13.12/python-3.13.12-amd64.exe' \
        -OutFile 'python-installer.exe' \
        -Hash '96159fcb523ae404b707186a75b4104ee23851e476a5e838e14584cf1e03f981'; \
    Start-Process -Wait -NoNewWindow \
        -FilePath 'python-installer.exe' \
        -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1 Shortcuts=0 Include_doc=0 Include_test=0'; \
    Remove-Item -Path 'python-installer.exe', \"$env:TEMP/*\" -Recurse -Force;

RUN \
    Write-Host 'Installing Conan...'; \
    Start-Process -Wait -NoNewWindow \
        -FilePath 'pip' \
        -ArgumentList 'install --no-cache-dir conan==2.26.2';

# console utilities
RUN \
    Write-Host 'Installing PowerShell...'; \
    Download-File \
        -Uri 'https://github.com/PowerShell/PowerShell/releases/download/v7.5.5/PowerShell-7.5.5-win-x64.msi' \
        -OutFile 'powershell.msi' \
        -Hash 'b2ac56b7639e2b259bb78bab077555d76f2a5eec6c516690d63de36bc1d6ca25'; \
    Start-Process -Wait -NoNewWindow \
        -FilePath 'msiexec' \
        -ArgumentList '/quiet /norestart /package powershell.msi'; \
    Remove-Item -Path 'powershell.msi'; \
\
    Write-Host 'Installing Microsoft Edit...'; \
    Download-File \
        -Uri 'https://github.com/microsoft/edit/releases/download/v1.2.1/edit-1.2.1-x86_64-windows.zip' \
        -OutFile 'edit.zip' \
        -Hash 'be3affb7e5e0cd856fc0fb9c8b2004e9fbbc364e69797f7c2e9d8fcc94bfc4ff'; \
    Expand-Archive -Path 'edit.zip' -DestinationPath \"$env:ProgramFiles\"; \
    Move-Item -Path \"$env:ProgramFiles/edit-*\" -Destination \"$env:ProgramFiles/Edit\"; \
    Remove-Item -Path 'Edit.zip', \"$env:ProgramFiles/Edit/*\" -Exclude '*.exe' -Recurse -Force; \
    [Environment]::SetEnvironmentVariable( \
        'Path', \
        [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine) + \";$env:ProgramFiles\Edit\", \
        [EnvironmentVariableTarget]::Machine);

ENTRYPOINT [ \
    "C:/Program Files (x86)/Microsoft Visual Studio/18/BuildTools/Common7/Tools/VsDevCmd.bat", "-host_arch=amd64", \
    "-arch=amd64", "&&", "pwsh.exe", "-NoLogo", "-ExecutionPolicy", "Bypass" \
]

USER ${USER_NAME}
