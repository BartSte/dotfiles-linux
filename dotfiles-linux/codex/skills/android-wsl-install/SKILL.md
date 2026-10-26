---
name: android-wsl-install
description: Build an Android APK in WSL and install or launch it through Windows ADB on a USB-connected phone. Use for Bart's personal cross-environment workflow, not native Windows builds or general emulator setup.
---

# Android installation from WSL through Windows

Keep this personal workflow outside shared repository documentation.
Build in WSL. Use Windows ADB for the phone connected to Windows.
Read the project instructions for the build task, APK path, application ID, activity, and signing requirements.
The commands below use Fleet Inspector GO Mobile as an example. Adapt these values for other projects.

## Build environment

Install the required debug keystore in the environment that runs Gradle.
WSL uses `~/.android/debug.keystore`. Windows uses `%USERPROFILE%\.android\debug.keystore`.
These locations are separate. Windows ADB does not change the APK signing certificate.

From the project root in WSL, build the APK:

```sh
./gradlew :androidApp:assembleDebug
```

## Windows device connection

Enable USB debugging on the phone and connect it to Windows with a USB data cable.
Use an existing Windows ADB installation. If ADB is missing, install it with Scoop in Windows PowerShell:

```powershell
scoop install adb
```

Use port `5038` consistently to keep this Windows ADB server separate from the default server on port `5037`:

```powershell
adb.exe -P 5038 devices -l
```

Accept **Allow USB debugging?** on the unlocked phone.
Repeat the command until the intended phone has state `device`.
If multiple devices are present, add `-s <serial>` to installation and launch commands.
If no devices appear, inspect the ADB driver in Windows Device Manager.
If the phone remains unavailable, report the blocker before installation.

## Transfer, install, and launch

Determine the Windows user directory. Do not assume that it matches the WSL username.
Copy the APK from WSL to Windows Downloads, replacing `<windows-user>`:

```sh
cp androidApp/build/outputs/apk/debug/androidApp-debug.apk \
  /mnt/c/Users/<windows-user>/Downloads/figo-debug.apk
```

In Windows PowerShell, install the APK:

```powershell
adb.exe -P 5038 install -r "$env:USERPROFILE\Downloads\figo-debug.apk"
```

After installation succeeds, start the app:

```powershell
adb.exe -P 5038 shell am start -n com.fleetrobotics.figo/.MainActivity
```

When commands run from WSL, use Windows executables for the Windows operations.
If installation fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, report the certificate mismatch.
Do not uninstall automatically. Uninstallation deletes local app data and requires explicit authorization.
