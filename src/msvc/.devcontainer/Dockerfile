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

USER ${USER_NAME}

RUN \
    Download-File \
        -Uri 'https://aka.ms/vs/17/release/vs_buildtools.exe' \
        -OutFile 'vs_buildtools.exe'; \
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
        -Value \"${env:ProgramFiles(x86)}/Microsoft Visual Studio/2022/BuildTools\"

ENV CCACHE_DIR='C:\.ccache' \
    CCACHE_TEMPDIR='C:\ccache-tmp' \
    CONAN_HOME='C:\.conan2'

# Updating utilities should't change the mtime of the VC
RUN \
    Write-Host 'Installing CMake...'; \
    Download-File \
        -Uri 'https://github.com/Kitware/CMake/releases/download/v4.0.4/cmake-4.0.4-windows-x86_64.msi' \
        -OutFile 'cmake.msi' \
        -Hash 'fb2b269b7a52e6deff4d8e36f7ab8d1b13c52cdc0577693e3382858d0527f8ca'; \
    Start-Process -Wait -NoNewWindow \
        -FilePath 'msiexec' \
        -ArgumentList '/quiet /norestart /package cmake.msi ADD_CMAKE_TO_PATH=System'; \
    Remove-Item -Path 'cmake.msi'; \
\
    Write-Host 'Installing Ninja...'; \
    Download-File \
        -Uri 'https://github.com/ninja-build/ninja/releases/download/v1.13.1/ninja-win.zip' \
        -OutFile 'ninja.zip' \
        -Hash '26a40fa8595694dec2fad4911e62d29e10525d2133c9a4230b66397774ae25bf'; \
    Expand-Archive -Path 'ninja.zip' -DestinationPath \"$env:ProgramFiles/Ninja\"; \
    Remove-Item -Path 'ninja.zip'; \
    [Environment]::SetEnvironmentVariable( \
        'Path', \
        [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine) + \";$env:ProgramFiles\Ninja\", \
        [EnvironmentVariableTarget]::Machine); \
\
    Write-Host 'Installing ccache...'; \
    Download-File \
        -Uri 'https://github.com/ccache/ccache/releases/download/v4.12/ccache-4.12-windows-x86_64.zip' \
        -OutFile 'ccache.zip' \
        -Hash '85c963b154dcf5e38dc6839d660218433a3b0b86387c302675d236e17ae7220d'; \
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
        -Uri 'https://github.com/git-for-windows/git/releases/download/v2.51.0.windows.1/Git-2.51.0-64-bit.tar.bz2' \
        -OutFile 'git.tar.bz2' \
        -Hash '151bddf70e1115631e62bb05535b5e6726b3813e1f363953ad6b4e6697d96933'; \
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
        -Uri 'https://www.python.org/ftp/python/3.13.7/python-3.13.7-amd64.exe' \
        -OutFile 'python-installer.exe' \
        -Hash 'b12e2e82461ac8e51fc43289050bc8eb937a32d84ce4d242e2c88258c37cf2bb'; \
    Start-Process -Wait -NoNewWindow \
        -FilePath 'python-installer.exe' \
        -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1 Shortcuts=0 Include_doc=0 Include_test=0'; \
    Remove-Item -Path 'python-installer.exe', \"$env:TEMP/*\" -Recurse -Force;

RUN \
    Write-Host 'Installing Conan...'; \
    Start-Process -Wait -NoNewWindow \
        -FilePath 'pip' \
        -ArgumentList 'install --no-cache-dir conan==2.20.1';

# console utilities
RUN \
    Write-Host 'Installing PowerShell...'; \
    Download-File \
        -Uri 'https://github.com/PowerShell/PowerShell/releases/download/v7.5.3/PowerShell-7.5.3-win-x64.msi' \
        -OutFile 'powershell.msi' \
        -Hash '28e23a6e3a18662b73e6fb267855f31786fb95ec943111de9e9e1338844106b4'; \
    Start-Process -Wait -NoNewWindow \
        -FilePath 'msiexec' \
        -ArgumentList '/quiet /norestart /package powershell.msi'; \
    Remove-Item -Path 'powershell.msi';

ENTRYPOINT [ \
    "C:/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/Common7/Tools/VsDevCmd.bat", "-host_arch=amd64", \
    "-arch=amd64", "&&", "pwsh.exe", "-NoLogo", "-ExecutionPolicy", "Bypass" \
]
