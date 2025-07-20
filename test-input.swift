import SwiftUI

struct TestInputView: View {
    @State private var testText: String = ""
    
    var body: some View {
        VStack {
            Text("Test Input Field")
                .font(.title)
            
            TextField("Enter text here", text: $testText)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Text("Current text: \(testText)")
                .padding()
            
            Button("Clear") {
                testText = ""
            }
            .padding()
        }
        .padding()
    }
}

@main
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            TestInputView()
        }
    }
}