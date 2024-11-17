import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default
    ) private var items: FetchedResults<Item>

    @State private var isPresentingScanner = false
    @State private var isLoading = true // State to show the loading screen
    @State private var errorMessage: String?
let saline = Process(name: "Saline Solution Dilution", steps: [
    ProcessStep(id: 1, title: "Step 1", description: "Prepare the materials.",animation: ""),
    ProcessStep(id: 2, title: "Step 2", description: "Mix the solution.", animation:"animateCap"),
    ProcessStep(id: 3, title: "Step 3", description: "Fill the IV bag.", animation: "word"),
    ProcessStep(id: 4, title: "Step 4", description: "Seal and label the bag.",animation: "word")
])
    var body: some View {
        ZStack {
            if isLoading {
                // Loading Screen
                VStack {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                    Text("Fetching data, please wait.")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
                .edgesIgnoringSafeArea(.all)
            } else {
                // Main App Content
                NavigationView {
                    VStack {
                        Text("Added Compounding Instructions").multilineTextAlignment(.leading)
                        if items.isEmpty {
                            Text("No items available.").multilineTextAlignment(.leading).foregroundColor(.secondary)
                        } else {
                            List {
                                ForEach(items) { item in
                                    NavigationLink(destination: ARViewerView(
                                        modelName:"bottle", 
                                        medication: item.name ?? "Unknown",
                                        process: saline // Replace with actual process
                                    )) {
                                        VStack(alignment: .leading) {
                                            Text("Name: \(item.name ?? "Unknown")")
                                            Text("Date added: \(item.timestamp ?? Date(), formatter: dateFormatter)")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .onDelete(perform: deleteItems)
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                isPresentingScanner = true
                            }) {
                                Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
                    }
                    .sheet(isPresented: $isPresentingScanner) {
                        QRScannerView { scannedCode in
                            addItem(qrCode: scannedCode)
                            isPresentingScanner = false
                        }
                    }
                }
            }
        }
        .onAppear {
            initializeApp()
        }
    }

    private func initializeApp() {
        // Simulate initialization or data fetching
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { // Adjust delay as needed
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }

    private func addItem(qrCode: String) {
        let newItem = Item(context: viewContext)
        newItem.id = Int64(items.count + 1)
        newItem.name = qrCode + " Instruction"
        newItem.qrCode = qrCode
        newItem.modelCid = "bottle" // Replace with actual CID if needed
        newItem.timestamp = Date()

        do {
            try viewContext.save()
        } catch {
            print("Failed to save item: \(error)")
        }
    }

    private func deleteItems(offsets: IndexSet) {
        offsets.map { items[$0] }.forEach(viewContext.delete)

        do {
            try viewContext.save()
        } catch {
            print("Failed to delete items: \(error)")
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

private func createSampleProcess() -> Process {
    // Example process to pass to ARViewerView
    Process(name: "Saline Solution Dilution", steps: [
        ProcessStep(id: 1, title: "Step 1", description: "Prepare the materials.",animation: ""),
        ProcessStep(id: 2, title: "Step 2", description: "Mix the solution.", animation:"animateCap"),
        ProcessStep(id: 3, title: "Step 3", description: "Fill the IV bag.", animation: "word"),
        ProcessStep(id: 4, title: "Step 4", description: "Seal and label the bag.",animation: "word")
    ])
}
