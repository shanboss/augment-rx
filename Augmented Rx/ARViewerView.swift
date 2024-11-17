import SwiftUI
import RealityKit

struct ARViewerView: View {
    @Environment(\.presentationMode) var presentationMode
    var modelName: String
    var medication: String
    var process: Process
    
    @State private var arView: ARView? = nil
    @State private var isModelAdded = false
    @State private var buttonState: ButtonState = .start
    @State private var trackingLabel: String = ""
    @State private var currentStepIndex: Int = 0
    
    enum ButtonState {
        case start
        case compound
        case end
    }
    
    var body: some View {
        ZStack {
            // ARView in the background
            if let arView = arView {
                ARViewContainer(arView: arView, process: process)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("Initializing AR View...")
                    .foregroundColor(.gray)
            }
            
            // Overlay UI
            VStack {
                // Top label
                Text(medication)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .transition(.slide)
                    .animation(.easeInOut(duration: 0.5), value: trackingLabel)
                
                Spacer()
                
                // Bottom label
                Text(trackingLabel)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .transition(.slide)
                    .animation(.easeInOut(duration: 0.5), value: trackingLabel)
                
                // Buttons
                if buttonState == .start {
                    Button(action: {
                        setupAnchorAndModel()
                    }) {
                        Text("Start Compounding")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                } else if buttonState == .compound {
                    HStack {
                        Button(action: {
                            goBack()
                        }) {
                            Text("Go Back")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        Button(action: {
                            nextStep()
                            animateCap()
                        }) {
                            Text("Next Step")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                } else if buttonState == .end {
                    HStack {
                        Button(action: {
                            goBack()
                        }) {
                            Text("Start Over")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Back to Home")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .onAppear {
            initializeARView()
        }
    }
    
    private func initializeARView() {
        arView = ARView(frame: .zero)
    }
    
    private func setupAnchorAndModel() {
        guard let arView = arView else {
            print("ARView not initialized.")
            return
        }
        
        if isModelAdded {
            print("Model already added to the scene.")
            return
        }
        
        // Load the bottle and cap models
        guard let bottleEntity = try? Entity.loadModel(named: "bottle"),
              let capEntity = try? Entity.loadModel(named: "cap") else {
            print("Failed to load bottle or cap model")
            return
        }
        
        // Set up an anchor entity
        let anchorEntity = AnchorEntity(.plane(.horizontal, classification: .table, minimumBounds: [0.5, 0.5]))
        
        // Adjust bottle position and scale
        bottleEntity.position = SIMD3(x: 0, y: 0, z: 0)
        bottleEntity.scale = SIMD3<Float>(x: 0.02, y: 0.02, z: 0.02)
        anchorEntity.addChild(bottleEntity)
        
        // Adjust cap position and scale (relative to the bottle)
        capEntity.position = SIMD3(x: 0, y: 0, z: 0) // Positioned slightly above the bottle
        capEntity.scale = SIMD3<Float>(x: 0.02, y: 0.02, z: 0.02)
        anchorEntity.addChild(capEntity)
        
        // Add the anchor to the AR scene
        arView.scene.addAnchor(anchorEntity)
        isModelAdded = true
        
        // Store the cap entity in the ARView for animation
        self.arView = arView
        arView.scene.anchors.append(anchorEntity)
        
        // Update tracking label
        trackingLabel = process.steps.first?.title ?? "Preparing the Saline Solution."
        
        print("Bottle and cap models added to AR scene.")
        
        // Change button state
        buttonState = .compound
    }
    
    private func goBack() {
        print("Go Back pressed.")
        buttonState = .start
        isModelAdded = false
        currentStepIndex = 0
        
        // Remove all anchors from the scene
        arView?.scene.anchors.removeAll()
        
        // Clear tracking label
        trackingLabel = ""
    }
    
    private func nextStep() {
        if currentStepIndex < process.steps.count - 1 {
            currentStepIndex += 1
            let nextStep = process.steps[currentStepIndex]
            trackingLabel = "Next: \(nextStep.title) - \(nextStep.description)"
        } else {
            trackingLabel = "All steps completed!"
            buttonState = .end
        }
    }
    private func animateCap() {
        guard let arView = arView else {
            print("ARView not initialized.")
            return
        }
        
        // Find the cap entity in the scene
        let capEntity = arView.scene.anchors
            .flatMap { $0.children.compactMap { $0 as? ModelEntity } }
            .first { $0.name == "cap" }
        
        guard let capEntity = capEntity else {
            print("Cap entity not found in the scene.")
            return
        }
        
        // Define the animation
        let moveUpTransform = Transform(
            scale: capEntity.scale,
            rotation: capEntity.orientation,
            translation: capEntity.position + SIMD3<Float>(0, 0.1, 0) // Move 0.1m up
        )
        
        // Animate the cap
        capEntity.move(to: moveUpTransform, relativeTo: capEntity.parent, duration: 2.0) // Animate over 2 seconds
        print("Cap animation started.")
    }
}
    
    
    struct ARViewContainer: UIViewRepresentable {
        let arView: ARView
        var process: Process
        
        func makeUIView(context: Context) -> ARView {
            // Initialize ARView and add steps
            DispatchQueue.main.async {
                addStepsToARView()
            }
            return arView
        }
        
        func updateUIView(_ uiView: ARView, context: Context) {
            // Update UI dynamically if needed
        }
        
        private func addStepsToARView() {
            for step in process.steps {
                addStepToARView(step: step)
            }
        }
        
        
        private func addStepToARView(step: ProcessStep) {
            // Create text for the step
            let textEntity = ModelEntity(mesh: .generateText(
                "\(step.id): \(step.title)",
                extrusionDepth: 0.02, // Better depth
                font: .systemFont(ofSize: 1.0), // Adjust font size
                containerFrame: CGRect.zero,
                alignment: .center,
                lineBreakMode: .byWordWrapping
            ))
            
            // Create an anchor entity
            let anchorEntity = AnchorEntity(plane: .horizontal)
            anchorEntity.addChild(textEntity)
            
            // Adjust position for clarity
            textEntity.position = SIMD3(
                x: Float(step.id) * 0.5, // Horizontal spacing
                y: 0.1,                 // Slight elevation
                z: -Float(step.id) * 0.2 // Depth adjustment
            )
            
            // Add the anchor to the ARView
            arView.scene.addAnchor(anchorEntity)
        }
        
    }

