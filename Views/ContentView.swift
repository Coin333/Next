import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var state: NextState
    
    var body: some View {
        
        ZStack {
            
            Color(.darkGray)
                .ignoresSafeArea()
            
            if state.showingCompletion {
                CompletionView()
            } else {
                TaskView()
            }
        }
    }
}
