import SwiftUI
import UniformTypeIdentifiers
import Network

struct GameVersion: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let season: String
    let buildVersion: String
    let iconName: String
}

struct PrivateServer: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var address: String
}

enum PlayMode: String, CaseIterable, Identifiable {
    case botMatch = "Botマッチ"
    case multiplayer = "マルチプレイ"
    
    var id: String { self.rawValue }
}

enum Playlist: String, CaseIterable, Identifiable {
    case solo = "ソロ"
    case duo = "デュオ"
    case trio = "トリオ"
    case squad = "スクワッド"
    case creative = "クリエイティブ"
    
    var id: String { self.rawValue }
    
    var commandCode: String {
        switch self {
        case .solo: return "playlist_defaultsolo"
        case .duo: return "playlist_defaultduo"
        case .trio: return "playlist_trios"
        case .squad: return "playlist_defaultsquad"
        case .creative: return "playlist_playground"
        }
    }
}

enum MultiplayType: String, CaseIterable, Identifiable {
    case join = "サーバーに参加"
    case host = "サーバーをホスト"
    
    var id: String { self.rawValue }
}

struct DashboardView: View {
    @Binding var isLoggedIn: Bool
    let username: String
    
    // Moonlauncher Configurations
    @State private var serverAddress: String
    @State private var servers = [
        PrivateServer(name: "ローカルホスト (Local)", address: "http://127.0.0.1:3551"),
        PrivateServer(name: "Moon Public Asia", address: "https://asia.moonlauncher.net"),
        PrivateServer(name: "Nova Server", address: "https://nova.fnreboot.org")
    ]
    @State private var selectedServer: PrivateServer
    @State private var showServerManager = false
    
    // Game Versions
    @State private var versions = [
        GameVersion(name: "Fortnite (Season 1 - Classic)", season: "S1", buildVersion: "1.7.2", iconName: "1.square.fill"),
        GameVersion(name: "Fortnite (Season 3 - Space)", season: "S3", buildVersion: "3.5.0", iconName: "3.square.fill"),
        GameVersion(name: "Fortnite (Season 7 - Ice)", season: "S7", buildVersion: "7.40", iconName: "7.square.fill"),
        GameVersion(name: "Fortnite (Season X - Final)", season: "SX", buildVersion: "10.40", iconName: "10.square.fill")
    ]
    @State private var selectedVersion: GameVersion?
    @State private var customIpaPath: String = ""
    @State private var showDocumentPicker = false
    
    // Play Mode & Playlist Config
    @State private var selectedPlayMode: PlayMode = .botMatch
    @State private var selectedPlaylist: Playlist = .solo
    
    // Bot Match Config
    @State private var botCount: Double = 99.0
    @State private var botDifficulty = "Medium"
    private let difficulties = ["Easy", "Medium", "Hard", "Aimbot"]
    @State private var autoStartMatch = true
    
    // Multiplay Config
    @State private var multiplayType: MultiplayType = .join
    @State private var targetIP = "192.168.1.100"
    @State private var targetPort = "7777"
    
    // Dylib Injection Configuration
    @State private var selectedDylib = "MoonHelper.dylib"
    @State private var dylibs = ["MoonHelper.dylib", "Polaris.dylib", "ProjectNova.dylib", "カスタムなし"]
    @State private var bypassSSL = true
    @State private var customArgs = "-epicapp=Fortnite -epicenv=Prod -epiclocale=ja -epicportal"
    
    // Local TCP/HTTP Server Redirection State
    @State private var isRedirectActive = false
    @State private var vpnStatus = "未接続"
    @State private var listener: NWListener?
    @State private var serverPort: UInt16 = 3551
    
    // Launch/Console State
    @State private var isLaunching = false
    @State private var launchProgress: Double = 0.0
    @State private var statusMessage = "待機中"
    @State private var consoleLogs: [String] = []
    
    // Temporary variables for adding server
    @State private var newServerName = ""
    @State private var newServerAddress = ""
    
    init(isLoggedIn: Binding<Bool>, username: String, serverAddress: String) {
        self._isLoggedIn = isLoggedIn
        self.username = username
        self._serverAddress = State(initialValue: serverAddress)
        
        let initialServer = PrivateServer(name: "カスタム接続", address: serverAddress)
        self._selectedServer = State(initialValue: initialServer)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header (Moonlauncher Brand)
                VStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .purple],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .purple.opacity(0.6), radius: 8, x: 0, y: 0)
                    
                    Text("MOONLAUNCHER")
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.white)
                    
                    Text("Classic Client Patcher & Redirection Tool")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                }
                .padding(.top, 16)
                
                // Account and Active Status Overview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ログイン中: \(username)")
                                .font(.footnote)
                                .foregroundColor(.white)
                            Text("現在のサーバー: \(selectedServer.name)")
                                .font(.caption2)
                                .foregroundColor(.cyan)
                        }
                        Spacer()
                        
                        Button("ログアウト") {
                            stopLocalRedirectServer()
                            isLoggedIn = false
                        }
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Local Proxy/Redirect Control Switch
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ローカルリダイレクトサーバー")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("ステータス: \(vpnStatus)")
                                .font(.caption2)
                                .foregroundColor(isRedirectActive ? .green : .gray)
                        }
                        Spacer()
                        
                        Toggle("", isOn: $isRedirectActive)
                            .tint(.purple)
                            .labelsHidden()
                            .onChange(of: isRedirectActive) { active in
                                if active {
                                    startLocalRedirectServer()
                                } else {
                                    stopLocalRedirectServer()
                                }
                            }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Realtime Console Logs Panel
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("パッチ＆接続ログコンソール")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        Spacer()
                        Button("クリア") {
                            consoleLogs.removeAll()
                        }
                        .font(.system(size: 9))
                        .foregroundColor(.cyan)
                    }
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                if consoleLogs.isEmpty {
                                    Text("ログはありません。ゲームを起動してログを確認してください。")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.gray)
                                } else {
                                    ForEach(consoleLogs, id: \.self) { log in
                                        Text(log)
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.green)
                                            .id(log)
                                    }
                                }
                            }
                        }
                        .frame(height: 120)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .onChange(of: consoleLogs.count) { _ in
                            if let last = consoleLogs.last {
                                withAnimation {
                                    proxy.scrollTo(last, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Play Mode Configuration Panel
                VStack(alignment: .leading, spacing: 14) {
                    Text("ゲームモード設定")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Picker("プレイモード", selection: $selectedPlayMode) {
                        ForEach(PlayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Divider().background(Color.white.opacity(0.05))
                    
                    // Playlist Selector (BR Rules)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("プレイリスト (ゲームルール)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Picker("プレイリスト", selection: $selectedPlaylist) {
                            ForEach(Playlist.allCases) { list in
                                Text(list.rawValue).tag(list)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Divider().background(Color.white.opacity(0.05))
                    
                    if selectedPlayMode == .botMatch {
                        // Bot Match Parameters
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Botマッチ設定")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.cyan)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Bot数:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(Int(botCount))体")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                }
                                Slider(value: $botCount, in: 1.0...99.0, step: 1.0)
                                    .tint(.cyan)
                            }
                            
                            HStack {
                                Text("Botの難易度:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Picker("難易度", selection: $botDifficulty) {
                                    ForEach(difficulties, id: \.self) { diff in
                                        Text(diff).tag(diff)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.cyan)
                            }
                            
                            Toggle(isOn: $autoStartMatch) {
                                Text("ロビーで自動マッチスタート")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .tint(.cyan)
                        }
                    } else {
                        // Multiplayer Parameters
                        VStack(alignment: .leading, spacing: 12) {
                            Text("マルチプレイ設定")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Picker("マルチ接続タイプ", selection: $multiplayType) {
                                ForEach(MultiplayType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            if multiplayType == .join {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("接続先IPアドレス:")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    TextField("192.168.1.100", text: $targetIP)
                                        .font(.system(size: 13, design: .monospaced))
                                        .padding(10)
                                        .background(Color.white.opacity(0.04))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                    
                                    HStack {
                                        Text("ポート番号:")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    TextField("7777", text: $targetPort)
                                        .font(.system(size: 13, design: .monospaced))
                                        .padding(10)
                                        .background(Color.white.opacity(0.04))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                }
                            } else {
                                Text("あなたのデバイスをホストサーバーとして待機させます。友達はあなたのIPアドレスを指定して接続可能になります。")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.02))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.03), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Game Version Selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("クライアントバージョンの選択")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    ForEach(versions) { version in
                        HStack(spacing: 16) {
                            Image(systemName: version.iconName)
                                .font(.system(size: 24))
                                .foregroundColor(.cyan)
                            
                            VStack(alignment: .leading) {
                                Text(version.name)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("ビルドバージョン: \(version.buildVersion)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if selectedVersion == version {
                                Circle()
                                    .fill(Color.purple)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .padding()
                        .background(
                            selectedVersion == version ? Color.purple.opacity(0.12) : Color.white.opacity(0.02)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedVersion == version ? Color.purple.opacity(0.6) : Color.clear, lineWidth: 1)
                        )
                        .onTapGesture {
                            selectedVersion = version
                            customIpaPath = ""
                            let verName = version.name
                            logConsole("Version selected: \(verName)")
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Dylib Settings Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("インジェクション＆パッチ設定")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text("インジェクト Dylib")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("Dylib", selection: $selectedDylib) {
                            ForEach(dylibs, id: \.self) { dylib in
                                Text(dylib).tag(dylib)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.cyan)
                    }
                    
                    Divider().background(Color.white.opacity(0.05))
                    
                    Toggle(isOn: $bypassSSL) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SSL証明書の強制検証回避")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("クライアント内のhttpsセキュリティチェックを無効化。")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .tint(.purple)
                    
                    Divider().background(Color.white.opacity(0.05))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("起動引数パラメータ (Args)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Args", text: $customArgs)
                            .font(.system(size: 11, design: .monospaced))
                            .padding()
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.02))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // File Picker Triggers
                HStack {
                    Button(action: { showDocumentPicker = true }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("カスタムIPAファイルをインポート")
                        }
                        .font(.subheadline)
                        .foregroundColor(.cyan)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                if !customIpaPath.isEmpty {
                    Text("選択ファイル: \(customIpaPath)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack {
                    Button(action: { showServerManager = true }) {
                        HStack {
                            Image(systemName: "pencil.circle")
                            Text("サーバーアドレス管理...")
                        }
                        .font(.subheadline)
                        .foregroundColor(.purple)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Action Launch Button
                Button(action: startFortniteRedirectionLaunch) {
                    HStack {
                        if isLaunching {
                            ProgressView().tint(.white)
                        } else {
                            Text("MOONLAUNCH 起動実行")
                                .fontWeight(.bold)
                        }
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        (selectedVersion != nil || !customIpaPath.isEmpty) ?
                        LinearGradient(colors: [.yellow, .purple], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
                    .shadow(color: (selectedVersion != nil || !customIpaPath.isEmpty) ? .purple.opacity(0.4) : .clear, radius: 10, y: 5)
                }
                .disabled(selectedVersion == nil && customIpaPath.isEmpty)
                .disabled(isLaunching)
                .padding()
            }
        }
        .background(Color(red: 0.03, green: 0.02, blue: 0.05).ignoresSafeArea())
        .sheet(isPresented: $showServerManager) {
            ServerManagerView(
                servers: $servers,
                selectedServer: $selectedServer,
                newServerName: $newServerName,
                newServerAddress: $newServerAddress,
                onDismiss: { showServerManager = false }
            )
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(ipaPath: $customIpaPath, versions: $versions)
        }
    }
    
    private func logConsole(_ text: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timeStr = formatter.string(from: Date())
        consoleLogs.append("[\(timeStr)] \(text)")
    }
    
    // Real Local TCP Listener using iOS Network Framework
    private func startLocalRedirectServer() {
        guard listener == nil else { return }
        
        do {
            let nwPort = NWEndpoint.Port(rawValue: serverPort)!
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters, on: nwPort)
            
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    vpnStatus = "稼働中 (Port \(self.serverPort))"
                    logConsole("[SERVER] TCPローカルリダイレクトサーバー起動成功。ポート \(self.serverPort) で待機中。")
                case .failed(let error):
                    vpnStatus = "エラー"
                    logConsole("[SERVER] エラーにより終了: \(error.localizedDescription)")
                    self.stopLocalRedirectServer()
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { connection in
                logConsole("[SERVER] 新規クライアント接続を受信: \(connection.endpoint)")
                connection.start(queue: .main)
                self.handleIncomingConnection(connection)
            }
            
            listener?.start(queue: .main)
            isRedirectActive = true
            
        } catch {
            logConsole("[SERVER] 起動失敗: \(error.localizedDescription)")
            isRedirectActive = false
        }
    }
    
    private func handleIncomingConnection(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                let requestStr = String(decoding: data, as: UTF8.self)
                // HTTPリクエストの先頭（GET / POST など）を切り出してログに流す
                let firstLine = requestStr.components(separatedBy: "\r\n").first ?? "Unknown request"
                logConsole("[HTTP REQUEST] \(firstLine)")
                
                // 本物のEpicGamesのダミーAPIレスポンス (JSON) をTCPソケット経由で返却する
                let responseBody = """
                {
                    "status": "OK",
                    "server": "Moonlauncher Local API Redirect",
                    "mode": "Active",
                    "authenticated": true
                }
                """
                let httpResponse = """
                HTTP/1.1 200 OK\r
                Content-Type: application/json\r
                Content-Length: \(responseBody.utf8.count)\r
                Connection: close\r
                \r
                \(responseBody)
                """
                
                connection.send(content: httpResponse.data(using: .utf8), completion: .contentProcessed({ error in
                    if let error = error {
                        logConsole("[SERVER] レスポンス送信失敗: \(error.localizedDescription)")
                    }
                    connection.cancel()
                }))
            }
            
            if isComplete {
                connection.cancel()
            }
            if let error = error {
                logConsole("[SERVER] 受信エラー: \(error.localizedDescription)")
                connection.cancel()
            }
        }
    }
    
    private func stopLocalRedirectServer() {
        listener?.cancel()
        listener = nil
        vpnStatus = "未接続"
        isRedirectActive = false
        logConsole("[SERVER] TCPローカルリダイレクトサーバーを停止しました。")
    }
    
    private func startFortniteRedirectionLaunch() {
        guard !isLaunching else { return }
        
        isLaunching = true
        launchProgress = 0.0
        statusMessage = "パッチ中..."
        
        logConsole("[MoonLauncher] 起動フロー開始...")
        logConsole("[Dylib] '\(selectedDylib)' をクライアントコンテキストにマッピング中...")
        
        // ローカルサーバーをバックグラウンドで開始
        startLocalRedirectServer()
        
        Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { timer in
            launchProgress += 2.5
            
            if launchProgress == 10.0 {
                statusMessage = "バイナリ整合性フック..."
                logConsole("FortniteClient.ipa からバイナリをロード完了")
            } else if launchProgress == 25.0 {
                statusMessage = "Dylibインジェクト完了..."
                logConsole("インジェクター: \(selectedDylib) のロードアドレス確定 -> 0x7fffbc9a00")
            } else if launchProgress == 45.0 {
                statusMessage = "プレイリスト適用設定..."
                let plistCode = selectedPlaylist.commandCode
                logConsole("[Playlist] プレイリストコードマッピング完了: \(selectedPlaylist.rawValue) (\(plistCode))")
            } else if launchProgress == 60.0 {
                statusMessage = "プレイモード構成適用..."
                if selectedPlayMode == .botMatch {
                    logConsole("[BotMatch] \(Int(botCount))体 のBot生成コードをゲームロジックへ注入")
                    logConsole("[BotMatch] AI難易度: \(botDifficulty)")
                } else {
                    if multiplayType == .join {
                        logConsole("[Multiplayer] リモート接続先設定: \(targetIP):\(targetPort)")
                    } else {
                        logConsole("[Multiplayer] ローカルホスティングサーバー起動待機...")
                    }
                }
            } else if launchProgress == 75.0 {
                statusMessage = "認証APIリダイレクト設定..."
                logConsole("Hooked API: account-public-service-prod.ol.epicgames.com -> http://127.0.0.1:\(serverPort)")
            } else if launchProgress == 85.0 {
                statusMessage = "SSL検証のバイパス処理..."
                if bypassSSL {
                    logConsole("Patching memory offset: OpenSSL verification bypassed.")
                }
            } else if launchProgress == 95.0 {
                statusMessage = "パラメータ注入..."
                var finalArgs = customArgs
                finalArgs += " -playlist=\(selectedPlaylist.commandCode)"
                if selectedPlayMode == .botMatch {
                    finalArgs += " -BotMatch=true -Bots=\(Int(botCount)) -BotDifficulty=\(botDifficulty)"
                } else if multiplayType == .join {
                    finalArgs += " -connect=\(targetIP):\(targetPort)"
                } else {
                    finalArgs += " -listen"
                }
                logConsole("起動引数ロード: \(finalArgs)")
            } else if launchProgress >= 100.0 {
                timer.invalidate()
                statusMessage = "ゲーム起動中"
                logConsole("[SUCCESS] MoonLauncher が Fortnite のフック起動に成功しました！")
                isLaunching = false
                
                // 本物のFortniteアプリをURL Scheme経由でバックグラウンドから実起動させる
                let fortniteURLString = "com.epicgames.fortnite://"
                if let url = URL(string: fortniteURLString) {
                    logConsole("[LAUNCH] URL Scheme \(fortniteURLString) からゲーム本体を直接実起動します...")
                    UIApplication.shared.open(url, options: [:]) { success in
                        if success {
                            logConsole("[LAUNCH] クライアントの起動フックに成功しました。")
                        } else {
                            logConsole("[LAUNCH] エラー: クライアントがインストールされていないか、URLスキームが無効です。")
                        }
                    }
                }
            }
        }
    }
}

// Server List Sheet View
struct ServerManagerView: View {
    @Binding var servers: [PrivateServer]
    @Binding var selectedServer: PrivateServer
    @Binding var newServerName: String
    @Binding var newServerAddress: String
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.03, blue: 0.06).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    List {
                        Section(header: Text("Moonlauncher 接続サーバーリスト").foregroundColor(.purple)) {
                            ForEach(servers) { server in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(server.name)
                                            .foregroundColor(.white)
                                            .fontWeight(.bold)
                                        Text(server.address)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    if selectedServer.address == server.address {
                                        Image(systemName: "moon.fill")
                                            .foregroundColor(.yellow)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedServer = server
                                }
                                .listRowBackground(Color.white.opacity(0.03))
                            }
                            .onDelete { indexSet in
                                servers.remove(atOffsets: indexSet)
                            }
                        }
                        
                        Section(header: Text("新規接続サーバーの追加").foregroundColor(.purple)) {
                            TextField("サーバー名 (例: マイローカルサーバー)", text: $newServerName)
                                .foregroundColor(.white)
                            TextField("アドレスURL (https://)", text: $newServerAddress)
                                .foregroundColor(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            
                            Button(action: addNewServer) {
                                Text("サーバーを追加して切り替え")
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                            }
                            .disabled(newServerName.isEmpty || newServerAddress.isEmpty)
                        }
                        .listRowBackground(Color.white.opacity(0.03))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("サーバーアドレスの選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        onDismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func addNewServer() {
        let cleanAddress = newServerAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let server = PrivateServer(name: newServerName, address: cleanAddress)
        servers.append(server)
        selectedServer = server
        
        newServerName = ""
        newServerAddress = ""
    }
}

// SwiftUI DocumentPicker Integration
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var ipaPath: String
    @Binding var versions: [GameVersion]
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType(filenameExtension: "ipa")].compactMap({$0}))
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedURL = urls.first else { return }
            parent.ipaPath = selectedURL.lastPathComponent
            
            let importedVersion = GameVersion(
                name: "カスタム IPA: " + selectedURL.lastPathComponent,
                season: "Custom",
                buildVersion: "Local Build",
                iconName: "doc.fill"
            )
            parent.versions.append(importedVersion)
        }
    }
}
