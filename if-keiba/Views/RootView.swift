import SwiftUI

struct RootView: View {
    enum Tab: Hashable { case home, races, reports, settings }
    @State private var selection: Tab = .home

    var body: some View {
        TabView(selection: $selection) {
            // Home
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(Tab.home)

            // Races
            NavigationStack {
                RacesListView()   // ← プロジェクトにある一覧画面を使用
            }
            .tabItem { Label("Races", systemImage: "flag.checkered") }
            .tag(Tab.races)

            // Reports
            NavigationStack {
                ReportsView()
            }
            .tabItem { Label("Reports", systemImage: "chart.bar") }
            .tag(Tab.reports)

            // Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(Tab.settings)
        }
    }
}

#Preview {
    RootView()
}
