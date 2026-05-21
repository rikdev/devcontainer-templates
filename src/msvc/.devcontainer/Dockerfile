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
        # Build Number 11819.183
        -Uri 'https://download.visualstudio.microsoft.com/download/pr/3cfffe1b-b712-451e-9a6a-536ff231eb4b/72d390c5828fb0d8c2f4f16b253230e9016509a5a65f03faab903547012c3875/vs_BuildTools.exe' \
        -OutFile 'vs_buildtools.exe' \
        -Hash '72d390c5828fb0d8c2f4f16b253230e9016509a5a65f03faab903547012c3875'; \
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
        -Uri 'https://github.com/Kitware/CMake/releases/download/v4.3.2/cmake-4.3.2-windows-x86_64.msi' \
        -OutFile 'cmake.msi' \
        -Hash '6915813bedf3a8a698b72fc858e0c2a99761be981745c3c3c99bd30e1477e142'; \
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
        -Uri 'https://github.com/ccache/ccache/releases/download/v4.13.6/ccache-4.13.6-windows-x86_64.zip' \
        -OutFile 'ccache.zip' \
        -Hash '3d7cebb05850ad704e197b3f1d3f0f924ab6c9fdfc561578e146184fe9d89380'; \
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
        -Uri 'https://github.com/git-for-windows/git/releases/download/v2.54.0.windows.1/Git-2.54.0-64-bit.tar.bz2' \
        -OutFile 'git.tar.bz2' \
        -Hash 'e1819cee60d09793dde322cdb1170e03663c41cd9265cf45246219fc5e6aeecd'; \
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
        -Uri 'https://www.python.org/ftp/python/3.14.5/python-3.14.5-amd64.exe' \
        -OutFile 'python-installer.exe' \
        -Hash 'f9c09f5ed6f796fd1a8bc5ddfa41715a494b453c4781f0e35d5077cf9fa58f6d'; \
    Start-Process -Wait -NoNewWindow \
        -FilePath 'python-installer.exe' \
        -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1 Shortcuts=0 Include_doc=0 Include_test=0'; \
    Remove-Item -Path 'python-installer.exe', \"$env:TEMP/*\" -Recurse -Force;

RUN \
    Write-Host 'Installing Conan...'; \
    Start-Process -Wait -NoNewWindow \
        -FilePath 'pip' \
        -ArgumentList 'install --no-cache-dir conan==2.28.1';

# console utilities
RUN \
    Write-Host 'Installing PowerShell...'; \
    Download-File \
        -Uri 'https://github.com/PowerShell/PowerShell/releases/download/v7.6.1/PowerShell-7.6.1-win-x64.msi' \
        -OutFile 'powershell.msi' \
        -Hash '6b2118eb35379db159aa190ee2eb6721fe6b0e881b611429041ed13e8d8bea7b'; \
    Start-Process -Wait -NoNewWindow \
        -FilePath 'msiexec' \
        -ArgumentList '/quiet /norestart /package powershell.msi'; \
    Remove-Item -Path 'powershell.msi'; \
\
    Write-Host 'Installing Microsoft Edit...'; \
    Download-File \
        -Uri 'https://github.com/microsoft/edit/releases/download/v2.0.0/edit-2.0.0-x86_64-windows.zip' \
        -OutFile 'edit.zip' \
        -Hash '97b8f2c667faea8f211af5f9c879602949164911d74d16f540bbe31ad46c14cb'; \
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
