import SwiftUI

struct CompletionView: View {
    
    @EnvironmentObject var state: NextState
    
    var body: some View {
        
        VStack(spacing: 30) {
            
            Text("Nice.")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Text("That moved you forward.")
                .foregroundColor(.white)
            
            Button("Next Step") {
                state.showingCompletion = false
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
    }
}
