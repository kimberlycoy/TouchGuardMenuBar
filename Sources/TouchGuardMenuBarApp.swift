//
//  TouchGuardMenuBarApp.swift
//  TouchGuard Menu Bar
//  Copyright (C) 2026 Kimberly Coy
//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  Menu bar app: enable/disable click blocking, pick the block time, and
//  turn Launch at Login on or off (shown in System Settings > General >
//  Login Items).
//

import SwiftUI
import ServiceManagement

final class AppModel: ObservableObject {

    let blocker = ClickBlocker()

    @Published var enabled: Bool {
        didSet {
            UserDefaults.standard.set(enabled, forKey: "enabled")
            apply()
        }
    }

    @Published var blockInterval: Double {
        didSet {
            UserDefaults.standard.set(blockInterval, forKey: "blockInterval")
            blocker.blockInterval = blockInterval
        }
    }

    @Published private(set) var hasPermission = false
    @Published private(set) var launchAtLogin = false

    static let intervals: [Double] = [0.1, 0.15, 0.2, 0.3, 0.5, 0.75, 1.0]

    private var permissionTimer: Timer?
    private var setupWindow: NSWindow?

    init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: ["enabled": true, "blockInterval": 0.2])
        enabled = defaults.bool(forKey: "enabled")
        blockInterval = defaults.double(forKey: "blockInterval")
        blocker.blockInterval = blockInterval
        launchAtLogin = SMAppService.mainApp.status == .enabled

        // Ask for Accessibility permission on first launch. macOS shows its
        // own prompt (which also adds the app to the Accessibility list); the
        // setup window explains what to do. Keep checking until it's granted.
        hasPermission = ClickBlocker.hasPermission(prompt: true)
        apply()
        if !hasPermission {
            startPermissionPolling()
            // Wait for the app to finish launching before opening a window.
            DispatchQueue.main.async { [weak self] in
                self?.showSetup()
            }
        }
    }

    func showSetup() {
        if setupWindow == nil {
            let window = NSWindow(
                contentRect: .zero,
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "TouchGuard Menu Bar Setup"
            window.isReleasedWhenClosed = false
            let controller = NSHostingController(rootView: SetupView(model: self) { [weak self] in
                self?.setupWindow?.close()
            })
            // Resize the window when the view switches to "You're All Set".
            controller.sizingOptions = [.preferredContentSize]
            window.contentViewController = controller
            window.center()
            setupWindow = window
        }
        // Menu bar apps aren't frontmost by default; bring the window forward.
        NSApp.activate(ignoringOtherApps: true)
        setupWindow?.makeKeyAndOrderFront(nil)
    }

    private func apply() {
        if enabled && hasPermission {
            if !blocker.start() {
                // Permission can be listed but not yet effective; retry.
                startPermissionPolling()
            }
        } else {
            blocker.stop()
        }
        objectWillChange.send()
    }

    private func startPermissionPolling() {
        guard permissionTimer == nil else {
            return
        }
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            self.hasPermission = ClickBlocker.hasPermission(prompt: false)
            if self.hasPermission && (!self.enabled || self.blocker.start()) {
                timer.invalidate()
                self.permissionTimer = nil
                self.apply()
            }
        }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("TouchGuard Menu Bar: couldn't change Launch at Login: \(error.localizedDescription)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    var statusText: String {
        if !hasPermission {
            return "Needs Accessibility permission"
        }
        if !enabled {
            return "Paused"
        }
        if !blocker.isActive {
            return "Starting…"
        }
        return "On: blocking clicks for \(Self.format(blockInterval)) after typing"
    }

    static func format(_ seconds: Double) -> String {
        let ms = Int((seconds * 1000).rounded())
        return ms % 1000 == 0 ? "\(ms / 1000) s" : "\(ms) ms"
    }
}

@main
struct TouchGuardMenuBarApp: App {

    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model, blocker: model.blocker)
        } label: {
            Image(systemName: model.enabled && model.hasPermission ? "hand.raised.fill" : "hand.raised.slash")
        }
    }
}

struct MenuContent: View {

    @ObservedObject var model: AppModel
    @ObservedObject var blocker: ClickBlocker

    var body: some View {
        Text(model.statusText)
        Text("Clicks blocked: \(blocker.blockedCount)")

        Divider()

        if !model.hasPermission {
            Button("Set Up Accessibility Access…") {
                model.showSetup()
            }
            Divider()
        }

        Toggle("Enabled", isOn: $model.enabled)

        Picker("Block Time", selection: $model.blockInterval) {
            ForEach(AppModel.intervals, id: \.self) { interval in
                Text(AppModel.format(interval)).tag(interval)
            }
        }

        Toggle("Launch at Login", isOn: Binding(
            get: { model.launchAtLogin },
            set: { model.setLaunchAtLogin($0) }
        ))

        Divider()

        Button("Quit TouchGuard Menu Bar") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
