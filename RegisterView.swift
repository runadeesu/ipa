import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var serverAddress: String
    
    @State private var registerUsername = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var statusMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.1, green: 0.05, blue: 0.2), Color(red: 0.02, green: 0.02, blue: 0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("アカウント新規作成")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("対象サーバー: \(serverAddress)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    // Username Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ユーザー名")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .fontWeight(.bold)
                        
                        TextField("英数字で入力", text: $registerUsername)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("メールアドレス")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .fontWeight(.bold)
                        
                        TextField("example@reboot.com", text: $email)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("パスワード")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .fontWeight(.bold)
                        
                        SecureField("パスワードを設定", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("パスワード（確認用）")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .fontWeight(.bold)
                        
                        SecureField("もう一度パスワードを入力", text: $confirmPassword)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.03))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)
                
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundColor(isSuccess ? .green : .red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Button(action: performRegistration) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("アカウントを作成")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.3), radius: 8, y: 4)
                }
                .disabled(isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
    }
    
    private func performRegistration() {
        guard !registerUsername.isEmpty && !email.isEmpty && !password.isEmpty else {
            statusMessage = "すべての項目を入力してください。"
            isSuccess = false
            return
        }
        
        guard password == confirmPassword else {
            statusMessage = "パスワードが一致しません。"
            isSuccess = false
            return
        }
        
        isLoading = true
        statusMessage = ""
        
        // Simulating Registration Call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            isSuccess = true
            statusMessage = "アカウントが正常に作成されました！戻ってログインしてください。"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        }
    }
}
