import SwiftUI

@main
struct FruitClipApp: App {
    @NSApplicationDelegateAdaptor(AppCoordinator.self) var coordinator

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
