# SlackMenuBadge

[中文文档](./README.zh-CN.md)

`SlackMenuBadge` is a lightweight macOS menu bar app that mirrors Slack unread status into the system status bar.

It does not modify Slack itself. Instead, it reads the unread badge that Slack already shows in the Dock and projects that state into the macOS menu bar. The goal is simple: bring back the missing "menu bar unread indicator" experience that Slack's macOS client does not provide.

## What It Does

- Shows Slack status in the macOS menu bar.
- Polls Slack's Dock unread badge in real time.
- Displays the unread count when there are unread messages.
- Hides the count when unread is `0`.
- Keeps a menu bar entry even when Slack is not running.
- Shows `?` when required permissions are missing and provides a shortcut to System Settings.

The behavior is intentionally close to the way WeChat handles menu bar unread status on macOS, but implemented as a separate lightweight utility.

## How It Works

Slack does not expose a stable local API for third-party apps to read unread counts from the macOS client.

This project currently uses the following approach:

1. Detect whether Slack is running.
2. Use macOS Accessibility access to inspect the `Dock` process UI hierarchy.
3. Locate Slack's Dock item.
4. Read the item's `AXStatusLabel`.
5. Render that value in the menu bar.

That means the app depends on:

- macOS `Accessibility` permission
- Slack's current Dock badge behavior
- The current Dock accessibility hierarchy on macOS

This is not an official Slack API integration, but it is a lightweight and practical engineering solution for a personal desktop utility.

## Status Behavior

- Unread messages: shows `Slack icon + count`
- No unread messages: shows `Slack icon` only
- Missing permission: shows `Slack icon + ?`
- Slack not running: shows `Slack icon` only

## Requirements

- macOS 13 or later
- Swift 6 toolchain
- Slack for macOS installed

## Quick Start

### Run directly

```bash
swift run SlackMenuBadge
```

### Package as a `.app`

```bash
./scripts/package_app.sh
```

By default this generates:

```text
~/Downloads/SlackMenuBadge.app
```

## Usage

### First launch

1. Start Slack.
2. Start `SlackMenuBadge`.
3. Confirm that the Slack icon appears in the menu bar.

### Click behavior

The menu bar item has no menu. Clicking the icon opens Slack directly.

The unread count refreshes automatically every 5 seconds.

To quit the app, run `pkill SlackMenuBadge` or quit it from Activity Monitor.

## Permissions

This app requires `Accessibility` permission to read Slack's unread badge from the Dock.

### Granting permission

1. Open `System Settings`
2. Go to `Privacy & Security`
3. Open `Accessibility`
4. Enable `SlackMenuBadge`
5. Fully quit `SlackMenuBadge`
6. Launch `SlackMenuBadge` again

### How to tell whether permission is active

- If the menu bar shows a number, permission is active
- If the menu bar shows `?`, permission usually has not taken effect for the current process yet

### Common permission issue

If the app is already enabled in `Accessibility` but still shows `?`, this usually fixes it:

1. Quit `SlackMenuBadge`
2. Toggle its permission off and on again in `Accessibility`
3. Relaunch `SlackMenuBadge`
4. If needed, remove it from the list entirely and relaunch the app so macOS prompts again

## Project Structure

```text
.
├── AppResources/
│   ├── AppIcon.svg
│   ├── Info.plist
│   ├── slack-icon.png
│   ├── slack-icon.svg
│   └── slack.svg
├── scripts/
│   └── package_app.sh
├── Sources/
│   └── main.swift
├── Package.swift
├── README.md
└── README.zh-CN.md
```

## Development

### Local development

```bash
swift run
```

or explicitly:

```bash
swift run SlackMenuBadge
```

### Build

```bash
swift build
```

### Package

```bash
./scripts/package_app.sh
```

### Key files

- Menu bar app entry point: `Sources/main.swift`
- Unread badge provider: `SlackUnreadProvider`
- App packaging script: `scripts/package_app.sh`
- Finder app icon source: `AppResources/AppIcon.svg`
- Menu bar icon asset: `AppResources/slack-icon.png`

## How To Continue Developing

If you want to keep iterating on the project, these are the most useful next steps.

### 1. Improve unread detection robustness

The current implementation depends on AppleScript, `System Events`, and the Dock UI hierarchy.

Possible improvements:

- Use lower-level AX APIs instead of relying as much on AppleScript string output
- Distinguish between "permission missing" and "Dock data temporarily unavailable"
- Add compatibility handling for Slack process names, bundle IDs, and runtime states

### 2. Improve permission onboarding

Permission handling works, but it is still fairly technical.

Possible improvements:

- Detect permission state proactively on launch
- Show clearer guidance when permission is missing
- Prompt the user to restart the app after authorization changes

### 3. Refine the menu bar UI

The current UI is functional, but can still be polished:

- Make the unread presentation look more like a native badge or WeChat-style status item
- Fine-tune spacing between icon and count
- Improve tooltip and state copy

### 4. Add launch at login

This is the most natural next feature.

Potential direction:

- Use `SMAppService`
- Add a menu option to toggle launch at login

### 5. Provide a cleaner installation path

The current distribution flow is script-based packaging. Later you may want:

- Release artifacts
- Proper signing and notarization
- A Homebrew Cask or installer script

## Known Limitations

- Strongly depends on `Accessibility` permission
- Strongly depends on Slack's current Dock badge implementation
- May require updates if Slack or macOS changes the relevant UI structure
- Uses a 5-second polling interval rather than an event-driven model
- Currently targets the standard Slack macOS desktop client

## Icons And Assets

- The menu bar icon is derived from Slack visual assets
- The Finder app icon is a monochrome SVG variant stored in the repo and converted to `icns` during packaging

Reference:

- [Slack Media Kit](https://slack.com/media-kit)

## Recommended Next Steps

If you plan to maintain this project over time, the highest-value next items are:

1. Launch at login
2. More reliable permission detection
3. Replacing part of the AppleScript layer with native AX APIs
4. Proper signing and notarization

