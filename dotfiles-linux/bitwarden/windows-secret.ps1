param(
    [Parameter(Mandatory)][ValidateSet('Read', 'Write', 'Delete', 'Status', 'SelfTest')][string]$Action,
    [Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{64}$')][string]$Id
)

$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
Add-Type -AssemblyName System.Security
$scope = [Security.Cryptography.DataProtectionScope]::CurrentUser
$directory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'rbw-windows-unlock'
$path = Join-Path $directory ($Id + '.dpapi')
$entropy = [Text.Encoding]::UTF8.GetBytes('rbw-windows-unlock/v1/' + $Id)

try {
    switch ($Action) {
        'Write' {
            # The secret arrives over stdin, never in an argument or environment variable.
            $value = [Console]::In.ReadToEnd()
            if ([string]::IsNullOrEmpty($value)) { throw 'Empty secret' }
            $bytes = [Text.Encoding]::UTF8.GetBytes($value)
            try {
                $encrypted = [Security.Cryptography.ProtectedData]::Protect($bytes, $entropy, $scope)
            } finally {
                [Array]::Clear($bytes, 0, $bytes.Length)
                $value = $null
            }
            [IO.Directory]::CreateDirectory($directory) | Out-Null
            # Change only the DACL. PowerShell Set-Acl also attempts ownership
            # changes on some Windows accounts and requires extra privileges.
            $acl = [Security.AccessControl.DirectorySecurity]::new()
            $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            $acl.SetSecurityDescriptorSddlForm('D:P(A;OICI;FA;;;' + $sid + ')',
                [Security.AccessControl.AccessControlSections]::Access)
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                [IO.FileSystemAclExtensions]::SetAccessControl([IO.DirectoryInfo]::new($directory), $acl)
            } else {
                [IO.Directory]::SetAccessControl($directory, $acl)
            }
            $temporary = $path + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
            try {
                [IO.File]::WriteAllBytes($temporary, $encrypted)
                Move-Item -LiteralPath $temporary -Destination $path -Force
            } finally {
                if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
            }
        }
        'Read' {
            $bytes = [Security.Cryptography.ProtectedData]::Unprotect(
                [IO.File]::ReadAllBytes($path), $entropy, $scope)
            try {
                [Console]::Write([Text.Encoding]::UTF8.GetString($bytes))
            } finally {
                [Array]::Clear($bytes, 0, $bytes.Length)
            }
        }
        'Delete' {
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
        }
        'Status' {
            if (!(Test-Path -LiteralPath $path)) { exit 1 }
        }
        'SelfTest' {
            $bytes = [Text.Encoding]::UTF8.GetBytes('synthetic DPAPI round trip')
            $encrypted = [Security.Cryptography.ProtectedData]::Protect($bytes, $entropy, $scope)
            $plain = [Security.Cryptography.ProtectedData]::Unprotect($encrypted, $entropy, $scope)
            if ([Text.Encoding]::UTF8.GetString($plain) -cne 'synthetic DPAPI round trip') {
                throw 'DPAPI round trip failed'
            }
            [Console]::WriteLine('Windows user DPAPI is available.')
        }
    }
} catch {
    # Do not include input, exception data, or decrypted values in diagnostics.
    [Console]::Error.WriteLine('Windows vault secret operation failed (' + $Action +
        ', ' + $_.Exception.GetType().Name + ', ' + $_.Exception.HResult + ').')
    exit 1
}
