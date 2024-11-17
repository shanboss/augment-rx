//
//  ProcessStep.swift
//  Augmented Rx
//
//  Created by Manu Shanbhog  on 11/17/24.
//

import Foundation

// Represents a single step in the process
struct ProcessStep: Identifiable {
    let id: Int
    let title: String
    let description: String
    var isCompleted: Bool = false
    var animation: String

}

// Represents the entire process
struct Process {
    let name: String
    var steps: [ProcessStep]

    // Retrieve the next step
    func nextStep() -> ProcessStep? {
        return steps.first(where: { !$0.isCompleted })
    }

    // Mark a step as completed by ID
    mutating func completeStep(id: Int) {
        if let index = steps.firstIndex(where: { $0.id == id }) {
            steps[index].isCompleted = true
        }
    }

    // Check if the process is complete
    func isComplete() -> Bool {
        return steps.allSatisfy { $0.isCompleted }
    }
}

// Sample process for testing
extension Process {
    static func sampleProcess() -> Process {
        return Process(
            name: "Compounding Medication",
            steps: [
                ProcessStep(id: 1, title: "Step 1", description: "Prepare the materials.",animation: ""),
                ProcessStep(id: 2, title: "Step 2", description: "Mix the solution.", animation:"animateCap"),
                ProcessStep(id: 3, title: "Step 3", description: "Fill the IV bag.", animation: "word"),
                ProcessStep(id: 4, title: "Step 4", description: "Seal and label the bag.",animation: "word")
            ]
        )
    }
}
