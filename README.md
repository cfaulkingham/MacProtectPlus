# MacProtectPlus

MacProtectPlus is a small macOS utility for creating password-protected DMG files from selected files and folders.

## Features

- Compress one or more files or folders into a DMG file.
- Prompt for password and password confirmation before creating the archive.
- Add a Finder right-click Service: **Services > Protect as DMG**.
- Provide a normal app window when launched directly.
- Provide a self-contained installer app that can Install, Reinstall, or Uninstall.

## Requirements

- macOS 13 or newer.
- Xcode command line tools or Xcode with SwiftPM support.

## Use

After installation:

1. Select one or more files or folders in Finder.
2. Right-click the selection.
3. Choose **Services > Protect as DMG**.
4. Enter and confirm the password.

The archive is written next to the selected item.

## Build

Build the app bundle locally:

```bash
./script/build_and_run.sh --build-only
```

The generated app bundle is written to:

```text
dist/MacProtectPlus.app
```

Run the app locally:

```bash
./script/build_and_run.sh
```

## Install For Local Development

Install the locally built app into `~/Applications` and register the Finder Service:

```bash
./script/install_local.sh
```

If the Finder menu does not refresh, run:

```bash
./script/register_services.sh
```

## Installer Build

Build the distributable installer manager:

```bash
./script/build_installer.sh
```

The build writes:

```text
dist/MacProtectPlus Installer.app
dist/MacProtectPlus-Installer-1.0.zip
```

Generated artifacts under `dist/` are intentionally ignored by Git.

Give end users the zip, not the loose `.app` folder. `MacProtectPlus Installer.app` embeds the app payload and asks the user whether to Install, Reinstall, or Uninstall. Install/Reinstall copies `MacProtectPlus.app` to the current user's `~/Applications` folder, registers the Finder Service, refreshes the macOS Services database, and restarts Finder. The normal install path does not require an administrator password.

Current installs use the app-owned Service only. Older builds installed a separate `MacProtectPlus.workflow`; Reinstall and Uninstall remove current-user legacy workflow copies to avoid duplicate Finder menu entries.

## Signing And Distribution

By default, local builds are ad-hoc signed. On another Mac, Gatekeeper may block first launch of an ad-hoc signed app that was downloaded, AirDropped, or copied through a cloud service. For internal testing, use Control-click > Open the first time.

For normal end-user distribution, build with a Developer ID Application certificate and notarize the zip:

```bash
MACPROTECTPLUS_CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./script/build_installer.sh
```

Notarization is not currently automated by this repository.

## Uninstall

Use the installer and choose **Uninstall**, or run:

```bash
./script/uninstall.sh
```

Uninstall removes `~/Applications/MacProtectPlus.app`, unregisters the Finder Service, refreshes the macOS Services database, restarts Finder, and removes current-user legacy workflow installs left by older builds.

## DMG Encryption Note

MacProtectPlus uses the system `/usr/bin/hdiutil` command to create a compressed HFS+ `UDZO` disk image encrypted with AES-256. The generated `.dmg` mounts after the password is entered in Finder.

The password is supplied to `hdiutil` through stdin rather than as a process argument.
