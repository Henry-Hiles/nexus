# Nexus Client

> [!WARNING]
> Nexus Client is still heavily in development, and is not ready for use!

## Description

A simple and user-friendly Matrix client made with Flutter and the Matrix Dart SDK.

## Screenshots

|                                                                                  Dark Mode                                                                                   |                                    Light Mode                                    |
| :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------: |
| ![Screenshot of Nexus Client in dark mode, showing users talking, with a sidebar showing rooms and spaces, and another sidebar showing members](./assets/screenshotDark.png) | ![The same screenshot as above, but in light mode](./assets/screenshotLight.png) |

## Progress

-   [ ] Platform Support
    -   [x] Linux
    -   [x] Windows (untested, if you are interested in helping to test, open an issue)
    -   [ ] MacOS
    -   [ ] Android
    -   [ ] iOS
    -   [ ] Web (may not be possible)
-   [x] Login
    -   [x] Username / password auth
    -   [ ] OAuth / OIDC
-   [x] Rooms / Spaces
    -   [x] Displaying and choosing
    -   [x] Reading, showing unread
        -   [ ] Mark as read button on rooms and spaces
    -   [ ] Searching
    -   [ ] Creating (Rooms, Spaces, and DMs)
    -   [ ] Joining
        -   [ ] Using alias
        -   [ ] From space
        -   [ ] Exploring
    -   [x] Leaving
    -   [x] Subspaces
-   [x] Messages
    -   [x] Sending
        -   [x] Plain text
        -   [x] HTML/Markdown
        -   [x] Replies
        -   [ ] Attachments
        -   [ ] Mentions
            -   [ ] Users
            -   [ ] Rooms
        -   [ ] Custom emojis/stickers
        -   [ ] GIFs, maybe through Tenor or something
        -   [ ] Encrypted messages
    -   [x] Recieving
        -   [x] Plain text
        -   [x] HTML
        -   [x] Replies
            -   [x] Viewing
            -   [ ] Jump to original message
        -   [x] Edits
        -   [x] Attachments
            -   [ ] Downloading attachments
            -   [ ] Opening attachments in their own view
        -   [x] Mentions
            -   [x] Users
            -   [x] Rooms
                -   [ ] Plain text
                -   [ ] Matrix URIs
                -   [x] Matrix.to links
        -   [x] Custom emojis/stickers
        -   [ ] Encrypted messages
        -   [x] History loading
            -   [x] Backwards
            -   [ ] Forwards
    -   [x] Editing
    -   [x] Deleting
-   [ ] Reactions: Waiting on https://github.com/flyerhq/flutter_chat_ui/pull/838
-   [ ] Pins
    -   [ ] Displaying
    -   [ ] Creating
-   [ ] Threads
-   [ ] Profile popouts
-   [x] Copy link to [room, space]
-   [ ] Reporting
-   [ ] Notifications using UnifiedPush
-   [ ] Group calls using [MSC4195](https://github.com/matrix-org/matrix-spec-proposals/pull/4195)
-   [ ] Invites
    -   [ ] Viewing / accepting
    -   [ ] Spam filtering
-   [ ] Devices
    -   [ ] Viewing devices
    -   [ ] Verifying devices
-   [ ] Settings
    -   [ ] Light/Dark mode
    -   [ ] Dynamic Theming
    -   [ ] URL preview: Server / Client / None
    -   [ ] Account changes
        -   [ ] Display name
        -   [ ] Profile picture
        -   [ ] Timezone
        -   [ ] Pronouns
        -   [ ] Password
    -   [ ] About
    -   [x] Log Out

## Development

Fork and clone the project, then:

-   With Nix: Either use direnv, or `nix flake develop`
-   Without Nix: Install Flutter, Rust, the libsecret dev package for your distro (must be in `PKG_CONFIG_PATH`), and sqlite (must be in `LD_LIBRARY_PATH`).

Build generated files, and watch for new changes:

```sh
flutter pub run build_runner watch --delete-conflicting-outputs
```

Run `flutter run` to run the app.

## Community

Come chat in the [Federated Nexus Community](https://matrix.to/#/#space:federated.nexus) for questions or help with developing or using Nexus Client.
