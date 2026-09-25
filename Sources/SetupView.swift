//
//  SetupView.swift
//  TouchGuard Menu Bar
//  Copyright (C) 2026 Kimberly Coy
//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  First-run window that walks through granting Accessibility access and
//  switches to a confirmation as soon as macOS grants it.
//

import SwiftUI

struct SetupView: View {

    @ObservedObject var model: AppModel
    let close: () -> Void

    var body: some View {
        // Both states are always laid out, with the inactive one hidden, so
        // the view (and window) stays the same size when access is granted.
        ZStack(alignment: .topLeading) {
            instructions
                .opacity(model.hasPermission ? 0 : 1)
                .allowsHitTesting(!model.hasPermission)
                .accessibilityHidden(model.hasPermission)
            granted
                .opacity(model.hasPermission ? 1 : 0)
                .allowsHitTesting(model.hasPermission)
                .accessibilityHidden(!model.hasPermission)
        }
        .padding(24)
        .frame(width: 460)
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.tint)
                Text("Allow Accessibility Access")
                    .font(.title2.bold())
            }

            Text("TouchGuard Menu Bar needs Accessibility access to notice when you type and ignore accidental clicks. It never reads or records what you type.")
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                Step(number: 1, text: "Click **Open Accessibility Settings** below. (If macOS showed its own prompt, clicking **Open System Settings** there does the same thing.)")
                Step(number: 2, text: "In the list, find **TouchGuard Menu Bar** and turn its switch **on**. Enter your password or use Touch ID if asked.")
                Step(number: 3, text: "If it isn't in the list, click **+** below the list, choose **Applications → TouchGuard Menu Bar**, click **Open**, then turn its switch on.")
            }

            Text("Waiting for access… this window updates automatically.")
                .foregroundStyle(.secondary)

            HStack {
                Button("Later") {
                    close()
                }
                Spacer()
                Button("Open Accessibility Settings") {
                    model.openAccessibilitySettings()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var granted: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
                Text("You're All Set")
                    .font(.title2.bold())
            }

            Text("TouchGuard Menu Bar is running. Look for the hand icon in the menu bar to pause it, change the block time, or turn on **Launch at Login**.")
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Done") {
                    close()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        // Fill the height set by the (taller) instructions so Done sits at the bottom.
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct Step: View {

    let number: Int
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(number).")
                .bold()
                .frame(width: 18, alignment: .trailing)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
