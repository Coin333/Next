import SwiftUI

@main
struct NextApp: App {
    
    @StateObject var state = NextState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
        }
    }
}
