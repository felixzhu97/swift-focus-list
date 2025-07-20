import SwiftUI

@main
struct TestTextFieldApp: App {
    var body: some Scene {
        WindowGroup {
            TestTextFieldView()
        }
    }
}

struct TestTextFieldView: View {
    @State private var text1: String = ""
    @State private var text2: String = ""
    @FocusState private var isField1Focused: Bool
    @FocusState private var isField2Focused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("TextField 测试")
                .font(.title)
                .padding()
            
            Group {
                Text("测试1: 基础TextField")
                TextField("请输入文本", text: $text1)
                    .textFieldStyle(.roundedBorder)
                    .focused($isField1Focused)
                Text("输入内容: '\(text1)'")
                    .foregroundColor(.blue)
            }
            
            Divider()
            
            Group {
                Text("测试2: 带Form的TextField")
                Form {
                    Section("表单输入") {
                        TextField("请输入文本", text: $text2)
                            .textFieldStyle(.roundedBorder)
                            .focused($isField2Focused)
                    }
                }
                .frame(height: 100)
                Text("输入内容: '\(text2)'")
                    .foregroundColor(.green)
            }
            
            HStack {
                Button("聚焦字段1") {
                    isField1Focused = true
                }
                Button("聚焦字段2") {
                    isField2Focused = true
                }
                Button("清空") {
                    text1 = ""
                    text2 = ""
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isField1Focused = true
            }
        }
    }
}