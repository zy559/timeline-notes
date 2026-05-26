import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineFeedView()
                .tabItem {
                    Label("时间线", systemImage: "clock.arrow.circlepath")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(2)
        }
    }
}
