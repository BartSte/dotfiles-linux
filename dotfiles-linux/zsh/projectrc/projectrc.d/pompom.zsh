POMPOM_ROOT="/home/barts/code/personal/pompom"
POMPOM_DOTNET_WINDOWS='C:\Users\BartSteensma\scoop\apps\dotnet-sdk\current\dotnet.exe'
POMPOM_CMD="/mnt/c/Windows/System32/cmd.exe"
POMPOM_POWERSHELL="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
POMPOM_WINDOWS_ROOT='\\wsl.localhost\Arch\home\barts\code\personal\pompom'

pompom_build() (
    cd /mnt/c || return
    "$POMPOM_CMD" /d /c \
        "pushd $POMPOM_WINDOWS_ROOT && $POMPOM_DOTNET_WINDOWS build Pompom.sln --nologo"
)

pompom_run() (
    pompom_build || return
    cd /mnt/c || return
    "$POMPOM_CMD" /d /c \
        "pushd $POMPOM_WINDOWS_ROOT && $POMPOM_DOTNET_WINDOWS run --project src\Pompom\Pompom.csproj --no-build"
)

pompom_test() (
    pompom_build || return
    cd /mnt/c || return
    "$POMPOM_CMD" /d /c \
        "pushd $POMPOM_WINDOWS_ROOT && $POMPOM_DOTNET_WINDOWS tests\Pompom.Tests\bin\Debug\net10.0-windows10.0.17763.0\win-x64\Pompom.Tests.dll"
)

pompom_publish() (
    local pompom_root_win
    pompom_root_win=$(wslpath -w "$POMPOM_ROOT") || return
    cd /mnt/c || return

    "$POMPOM_POWERSHELL" -NoProfile -ExecutionPolicy Bypass \
        -Command "Set-Location -LiteralPath '$pompom_root_win'; & .\\scripts\\publish.ps1"
)

alias pbuild='pompom_build'
alias prun='pompom_run'
alias ptest='pompom_test'
alias ppublish='pompom_publish'
