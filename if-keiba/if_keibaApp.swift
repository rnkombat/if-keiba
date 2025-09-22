// if-keiba/if-keiba/if_keibaApp.swift
import SwiftUI
import SwiftData   // ← 追加

@main
struct IfKeibaApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Profile.self, Race.self, Ticket.self]) // OK
    }
}
