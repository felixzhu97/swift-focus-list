import SwiftUI

struct SimpleInputTest: View {
    @State private var text: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("简单输入测试")
                .font(.title)
            
            TextField("请输入文本", text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .padding()
            
            Text("当前输入: \(text)")
                .padding()
            
            Button("清空") {
                text = ""
            }
            .padding()
            
            Button("聚焦输入框") {
                isTextFieldFocused = true
            }
            .padding()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

struct SimpleInputTest_Previews: PreviewProvider {
    static var previews: some View {
        SimpleInputTest()
    }
}