import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var username: String
    @Binding var serverAddress: String
    
    @State private var password = ""
    @State private var showRegister = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching gaming themes (dark space/purple neon vibes)
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.1, green: 0.05, blue: 0.2), Color(red: 0.02, green: 0.02, blue: 0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Logo Header
                    VStack(spacing: 8) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 0)
                        
                        Text("REBOOT LAUNCHER")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(.white)
                        
                        Text("昔のバージョンでプレイ")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Form Fields Card
                    VStack(spacing: 16) {
                        // Server Endpoint Config
                        VStack(alignment: .leading, spacing: 6) {
                            Text("サーバーアドレス")
                                .font(.caption)
                                .foregroundColor(.purple)
                                .fontWeight(.bold)
                            
                            TextField("https://", text: $serverAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding()
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        // Username Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ユーザー名")
                                .font(.caption)
                                .foregroundColor(.purple)
                                .fontWeight(.bold)
                            
                            TextField("ユーザー名を入力", text: $username)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
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
                            
                            SecureField("パスワードを入力", text: $password)
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
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: performLogin) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("ログイン")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .shadow(color: .purple.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(isLoading)
                        
                        Button(action: { showRegister = true }) {
                            Text("新規アカウントを作成")
                                .font(.subheadline)
                                .foregroundColor(.cyan)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView(serverAddress: $serverAddress)
            }
        }
    }
    
    private func performLogin() {
        guard !username.isEmpty && !password.isEmpty else {
            errorMessage = "ユーザー名とパスワードを入力してください。"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        // Simulating authentication response from backend server
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            isLoggedIn = true
        }
    }
}
