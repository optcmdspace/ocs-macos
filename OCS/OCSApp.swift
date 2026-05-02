//
//  OCSApp.swift
//  OCS
//
//  Created by Rodrigo Costa on 2026-05-02.
//

import SwiftUI

@main
struct OCSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
