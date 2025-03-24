# adbpackage - Android Package Management Utility

A bash script for managing Android packages via ADB, particularly useful for backup/restore operations after factory resets.

## Features

- List all installed packages with timestamped output file
- Batch install packages from a text file
- Basic ADB availability checks

## Installation

```bash
chmod +x adbpackage
```

## Usage

```bash
./adbpackage list  # Generates packages_YYYYMMDD_HHMMSS.txt
./adbpackage install packages.txt  # Installs all packages listed in file
```

## Requirements

- ADB (Android Debug Bridge) installed
- USB debugging enabled on device
- Android device connected via USB

## Notes

- Install command requires APK paths in the text file
- Preserves package list with timestamps for versioning
- Handles Windows-style line endings in package files

## Example Output

```
Captured 142 packages to packages_20231025_153422.txt
```
