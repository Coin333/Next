import Foundation
import SwiftUI

class NextState: ObservableObject {
    
    @Published var currentTask = Task(
        title: "Study chemistry",
        smallerStep: "Open your chemistry notes"
    )
    
    @Published var showingCompletion = false
    
    func completeTask() {
        showingCompletion = true
    }
    
    func postponeTask() {
        currentTask.title = currentTask.smallerStep
    }
}
