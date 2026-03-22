#if os(watchOS)
import SwiftUI

@main
struct SquatchSportsWatchOSCompanionApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView()
                        .background(Color.white)
                        .environment(\.colorScheme, .light)
                        .transition(.opacity)
                        .task {
                            try? await Task.sleep(for: .seconds(2.8))
                            await MainActor.run {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showSplash = false
                                }
                            }
                        }
                } else {
                    ContentView()
                        .environmentObject(WorkoutConnectivity.shared)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showSplash)
        }
    }
}
#endif

