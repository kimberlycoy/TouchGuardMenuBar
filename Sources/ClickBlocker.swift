//
//  ClickBlocker.swift
//  TouchGuard Menu Bar
//  Copyright (C) 2026 Kimberly Coy
//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  Watches the keyboard and drops mouse clicks that arrive within a short
//  window after a key press, so a palm brushing the trackpad while typing
//  can't move the text cursor.
//

import AppKit
import ApplicationServices

final class ClickBlocker: ObservableObject {

    /// Number of clicks dropped since the app launched.
    @Published private(set) var blockedCount = 0

    /// True while the event tap is installed and active.
    @Published private(set) var isActive = false

    /// How long (seconds) clicks are blocked after each key press or release.
    var blockInterval: TimeInterval = 0.2

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // Time of the most recent key down/up, in system uptime seconds.
    private var lastKeyTime: TimeInterval = 0

    // Mouse buttons whose "down" was dropped. The matching "up" is dropped too,
    // and an "up" whose "down" was let through is never dropped, so a drag
    // can't get stuck.
    private var suppressedLeft = false
    private var suppressedRight = false

    /// Whether macOS has granted this app Accessibility permission.
    static func hasPermission(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Installs the event tap. Returns false if macOS refuses (usually
    /// because Accessibility permission hasn't been granted yet).
    @discardableResult
    func start() -> Bool {
        if eventTap != nil {
            return true
        }

        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.rightMouseUp.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                let blocker = Unmanaged<ClickBlocker>.fromOpaque(refcon!).takeUnretainedValue()
                return blocker.handle(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        isActive = true
        return true
    }

    func stop() {
        guard let tap = eventTap else {
            return
        }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        CFMachPortInvalidate(tap)
        eventTap = nil
        runLoopSource = nil
        suppressedLeft = false
        suppressedRight = false
        isActive = false
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let now = ProcessInfo.processInfo.systemUptime

        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // macOS switches taps off if they're slow or on certain user
            // input; turn it straight back on.
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }

        case .keyDown, .keyUp:
            lastKeyTime = now

        case .leftMouseDown, .rightMouseDown:
            if now - lastKeyTime < blockInterval {
                if type == .leftMouseDown {
                    suppressedLeft = true
                } else {
                    suppressedRight = true
                }
                blockedCount += 1
                return nil
            }

        case .leftMouseUp:
            if suppressedLeft {
                suppressedLeft = false
                return nil
            }

        case .rightMouseUp:
            if suppressedRight {
                suppressedRight = false
                return nil
            }

        default:
            break
        }

        return Unmanaged.passUnretained(event)
    }
}
