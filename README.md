# TouchGuard Menu Bar

A small macOS menu bar app that stops accidental trackpad taps while you type.

If your palm brushes the trackpad mid-sentence, macOS can treat it as a click and move your text cursor, so you end up typing in the wrong place. TouchGuard Menu Bar briefly ignores clicks right after each key press (200 ms by default), which is long enough to catch accidental taps but short enough that you won't notice it when you click on purpose.

## Features

- Lives in the menu bar (no Dock icon)
- Enable/disable with one click
- Adjustable block time: 100 ms to 1 s
- Launch at Login (appears in **System Settings → General → Login Items**)
- Live count of blocked clicks, so you can see it working
- No `sudo`, no Terminal: uses the standard macOS Accessibility permission

## Requirements

macOS 13 (Ventura) or later, Apple Silicon or Intel.

## Install

### From the installer

Installing takes three parts: download, get past the macOS security check, then allow Accessibility access.

#### 1. Download

Download `TouchGuardMenuBar-<version>.pkg` from the [latest release](https://github.com/kimberlycoy/TouchGuardMenuBar/releases/latest).

#### 2. Open the installer ("Open Anyway")

The installer isn't signed with a paid Apple Developer ID, so the first time you open it macOS blocks it with a message like *"TouchGuardMenuBar-1.1.pkg" Not Opened*. That's expected. To allow it:

1. Double-click the `.pkg` file. When macOS says it can't be opened, click **Done** (not Move to Trash).
2. Open **System Settings** (Apple menu → System Settings…) and click **Privacy & Security** in the sidebar.
3. Scroll **all the way down** the right-hand side to the **Security** section. You'll see a line saying the TouchGuardMenuBar `.pkg` "was blocked to protect your Mac", with an **Open Anyway** button next to it.
4. Click **Open Anyway**. macOS asks you to confirm (click **Open Anyway** again) and to enter your password or use Touch ID. The installer then opens.

The **Open Anyway** button only appears for about an hour after you try to open the file. If you don't see it, double-click the `.pkg` again and go back to step 2.

Older macOS versions (before macOS 15 Sequoia) also let you Control-click the file and choose **Open**. That shortcut no longer works on current macOS.

#### 3. Install and allow Accessibility access

1. Follow the installer. It puts **TouchGuard Menu Bar** in Applications and starts it. A hand icon appears in the menu bar.
2. macOS shows a prompt saying TouchGuard Menu Bar "would like to control this computer using accessibility features." Click **Open System Settings**. (If you missed the prompt, choose **Open Accessibility Settings…** from the menu bar icon.)
3. In **Privacy & Security → Accessibility**, find **TouchGuard Menu Bar** in the list and turn its switch **on**. Enter your password or use Touch ID if asked.
4. If it isn't in the list, click **+** below the list, choose **Applications → TouchGuard Menu Bar**, click **Open**, then turn its switch on.
5. Within a couple of seconds the menu bar icon becomes a solid hand.

Optional: choose **Launch at Login** from the menu bar icon so it starts automatically.

### Build from source

Requires Xcode or the Xcode Command Line Tools.

```bash
./build.sh            # build into build/
./build.sh install    # build and copy to ~/Applications
./build.sh package    # build and create build/TouchGuardMenuBar-<version>.pkg
```

Builds are signed ad hoc, so macOS may ask you to allow Accessibility access again after each rebuild.

## Usage

Click the hand icon in the menu bar:

| Item | What it does |
|---|---|
| Status | On, Paused, or "Needs Accessibility permission" |
| Clicks blocked | Clicks ignored since the app started |
| Enabled | Turn blocking on or off |
| Block Time | How long clicks are ignored after each key press |
| Launch at Login | Start automatically when you log in |
| Quit | Exit the app |

The icon is a solid hand when blocking is active and a crossed-out hand when paused or missing permission.

**Tuning:** if your cursor still jumps, increase the block time. If clicks right after typing feel ignored, decrease it.

## How it works

The app installs a macOS event tap that watches key presses and mouse clicks. A click (left or right button) that arrives within the block time after a key press is dropped. If a click's press is dropped, its release is dropped too, and a click whose press got through is never cut short, so drags can't get stuck. If macOS turns the event tap off, the app turns it straight back on.

Note: it can't tell the built-in trackpad from an external mouse, so clicks from either are ignored during the short block time.

## Uninstall

1. Choose **Quit TouchGuard Menu Bar** from the menu.
2. Move **TouchGuard Menu Bar** from Applications to the Trash.
3. Optional: remove it from **System Settings → Privacy & Security → Accessibility**.

## Credits

Based on the idea behind [TouchGuard](https://github.com/thesyntaxinator/TouchGuard) by SyntaxSoft (thesyntaxinator), a command-line tool that blocks clicks briefly after key presses. TouchGuard Menu Bar is a new implementation in Swift and doesn't include the original code.

Built with the help of [Claude Code](https://claude.com/claude-code), Anthropic's AI coding assistant. I came up with the idea, directed the design, and made the final decisions.

## License

Copyright (C) 2026 Kimberly Coy

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. See [LICENSE](LICENSE) for the full text.
