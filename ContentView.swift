import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var serverAddress = "https://reboot.example.com"
    @State private var username = ""
    
    var body: some View {
        Group {
            if isLoggedIn {
                DashboardView(isLoggedIn: $isLoggedIn, username: username, serverAddress: serverAddress)
            } else {
                LoginView(isLoggedIn: $isLoggedIn, username: $username, serverAddress: $serverAddress)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
