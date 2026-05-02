<center><img src="assets/icon.svg" height="128" /><center />

# <center>Nexus Client</center>

> [!WARNING]
> Nexus Client is still in development, and doesn't support everything needed for daily use.

## Description

A simple and user-friendly Matrix client made with Flutter and a Gomuks backend.

## Screenshots

|                                                                                  Dark Mode                                                                                   |                                    Light Mode                                    |
| :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------: |
| ![Screenshot of Nexus Client in dark mode, showing users talking, with a sidebar showing rooms and spaces, and another sidebar showing members](./assets/screenshotDark.png) | ![The same screenshot as above, but in light mode](./assets/screenshotLight.png) |

## Progress

- [ ] New logo
- [ ] Make context menus appear as bottom sheets on mobile
- [x] Move from the Dart SDK to the Gomuks Backend with Dart bindings: https://git.federated.nexus/Henry-Hiles/nexus/pulls/2
    - [ ] Allow using remote Gomuks over websocket
- [ ] Platform Support
    - [x] Linux
    - [ ] Windows (WIP)
    - [ ] MacOS
    - [x] Android
    - [ ] iOS
    - [ ] Web (may not be possible)
- [x] Login
    - [x] Username / password auth
    - [ ] OAuth / OIDC
    - [x] Improve initial sync experience
- [x] Rooms / Spaces
    - [x] Displaying and choosing
    - [x] Reading, showing unread
        - [x] Mark as read button on rooms and spaces
    - [ ] Searching
    - [ ] Creating (Rooms, Spaces, and DMs)
    - [x] Joining
        - [x] Parse vias
        - [x] Using a text/uri/link
            - [x] Plain text
            - [x] `matrix:` Uri
            - [x] Matrix.to link
        - [ ] From space
        - [ ] Exploring
    - [x] Leaving
    - [x] Subspaces
- [x] Messages
    - [x] Encryption
        - [x] Restoring crypto identity from a recovery passphrase/key
    - [x] Sending
        - [x] Plain text
        - [x] HTML/Markdown
        - [x] Replies
            - [x] Choose ping on/off
        - [ ] Per message profiles
        - [ ] Attachments
        - [ ] Commands with [MSC4391](https://github.com/matrix-org/matrix-spec-proposals/pull/4391)
        - [x] Mentions
            - [x] Users
            - [x] Rooms
            - [ ] Inline emoji picker (Putting this here since it'll be implemented the same way as mentions)
        - [ ] Custom emojis/stickers
        - [ ] GIFs using Gomuks' GIF proxies
    - [x] Receiving
        - [x] Plain text
        - [x] Per message profiles
        - [x] HTML
        - [x] URL Previews
        - [x] Replies
            - [x] Viewing
            - [ ] Jump to original message
                - [x] In loaded timeline
                - [ ] Out of loaded timeline
        - [x] Edits
        - [x] Attachments
            - [x] Unencrypted
            - [ ] Encrypted
            - [x] Blurhashing
            - [ ] Downloading attachments
            - [x] Opening attachments in their own view
        - [ ] Polls
        - [x] Mentions
            - [x] Users
                - [x] Clickable
            - [x] Rooms
                - [x] Clickable
                - [x] Matrix URIs
                - [x] Matrix.to links
            - [x] Events
                - [ ] Render more nicely
                - [ ] Clickable
        - [x] Custom emojis/stickers
        - [x] History loading
            - [x] Backwards
            - [ ] Forwards
    - [x] Editing
    - [x] Deleting
- [x] Reactions
- [ ] Pins
    - [ ] Displaying
    - [ ] Creating
- [ ] Threads
- [x] Profile popouts
    - [x] Working actions
- [x] Copy link to:
    - [x] Room
    - [x] Space
    - [x] Message
- [ ] Reporting
    - [x] Events
    - [ ] Rooms
- [ ] Notifications using UnifiedPush
- [ ] Group calls using [MSC4195](https://github.com/matrix-org/matrix-spec-proposals/pull/4195)
- [ ] Invites
- [ ] Settings
    - [ ] Matrix: URIs vs Matrix.to links
    - [ ] Light/Dark mode
    - [ ] SSD or CSD
    - [ ] Align your message bubbles to left or right
    - [ ] Show media by default
    - [ ] Dynamic Theming
    - [ ] Devices
        - [ ] Viewing devices
        - [ ] Verifying devices
    - [ ] URL preview: Server / Sending Client (Beeper spec) / None
    - [ ] Account changes
        - [ ] Display name
        - [ ] Profile picture
        - [ ] Timezone
        - [ ] Pronouns
        - [ ] Password
    - [ ] About
    - [x] Log Out

## Try it out

If you want to try out Nexus, grab one of the following artifacts from CI:

- [Android APK](https://nightly.link/Henry-Hiles/nexus/workflows/android/main/APK.zip)
- Windows
    - [Portable Build](https://nightly.link/Henry-Hiles/nexus/workflows/windows/main/windows-portable.zip)
    - [Installer](https://nightly.link/Henry-Hiles/nexus/workflows/windows/main/windows-installer.zip)
- Flatpak
    - [AArch64/Arm64](https://nightly.link/Henry-Hiles/nexus/workflows/flatpak/main/flatpak-aarch64.zip)
    - [x86_64/AMD64](https://nightly.link/Henry-Hiles/nexus/workflows/flatpak/main/flatpak-x86_64.zip)

Or, try the Nix package: `nix run git+https://git.federated.nexus/Henry-Hiles/nexus`

## Build it yourself

### Prerequisites

#### Linux

- With Nix: Either use direnv and `direnv allow`, or `nix flake develop`
- Without Nix: Install Flutter, Go, Git, Libclang, and Glibc. Do not use any Snap packages, they cause various compilation issues.

#### Windows

You will need:

- Flutter
- Android SDK + NDK
- Git
- Go
- Visual Studio 2022 (Desktop development with C++)
- [MSYS2/MinGW-w64 GCC](https://www.msys2.org/) (for CGO)
- [LLVM/Clang + libclang](https://clang.llvm.org/get_started.html) (for `ffigen`)

On Windows, make sure these are available in your shell `PATH`:

- `C:\msys64\ucrt64\bin` (or your MinGW bin path containing `x86_64-w64-mingw32-gcc.exe`)
- `C:\Program Files\LLVM\bin` (contains `clang.exe` and `libclang.dll`)

For `dart scripts/generate.dart`, you may also need:

```powershell
$env:CPATH = "C:\msys64\ucrt64\include"
```

#### MacOS

Similar prerequisites apply (Flutter, Git, Go, C toolchain, LLVM/libclang), but exact setup has not been fully documented yet.

### Clone repo

First, clone and open the repo:

```sh
git clone --recurse-submodules https://git.federated.nexus/Henry-Hiles/nexus
cd nexus
```

### Set up Flutter

Get dependencies:

```sh
flutter pub get
```

Generate Gomuks bindings:

```sh
dart scripts/generate.dart
```

Build generated files, and watch for new changes:

```sh
flutter pub run build_runner watch --delete-conflicting-outputs
```

Run the app:

```sh
flutter run
```

## Community

Join the [Nexus Client Matrix Room](https://matrix.to/#/#nexus:federated.nexus) for questions or help with developing or using Nexus Client.

# Credits

Thank you Hylke Bons (https://planetpeanut.studio) for making the amazing icon for Nexus!
Thank you Tulir Asokan for making [Gomuks](https://github.com/gomuks/gomuks), and helping us integrate it into Nexus!
