import SwiftUI

struct TaskView: View {
    
    @EnvironmentObject var state: NextState
    
    var body: some View {
        
        VStack(spacing: 40) {
            
            Text("Your Next Step")
                .font(.title)
                .foregroundColor(.white)
            
            Text(state.currentTask.title)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Button("Start") {
                state.completeTask()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            
            Button("Not Now") {
                state.postponeTask()
            }
            .padding()
            .background(Color.gray)
            .cornerRadius(10)
        }
        .padding()
    }
}
