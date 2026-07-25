import os
import json
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler

HOST = "0.0.0.0"
PORT = 8080

# アカウント保存用ファイル
ACCOUNTS_FILE = "accounts.json"

if not os.path.exists(ACCOUNTS_FILE):
    with open(ACCOUNTS_FILE, "w") as f:
        json.dump({}, f)

def load_accounts():
    with open(ACCOUNTS_FILE, "r") as f:
        return json.load(f)

def save_accounts(accounts):
    with open(ACCOUNTS_FILE, "w") as f:
        json.dump(accounts, f, indent=4)

# クライアント用コスメティックスのテンプレート生成関数（全スキン、エモート等を付与）
def generate_all_cosmetics():
    items = {}
    
    # 簡易的に代表的なコスメティクスをロード（CID:スキン, EID:エモート, BID:バックパック, GD:グライダー）
    # 大規模な一覧にするため代表的な人気アイテムを網羅
    prefixes = {
        "AthenaCharacter": [
            "cid_001_athena_facepaint", "cid_017_athena_facepaint_warrior", "cid_028_athena_facepaint_renegade",
            "cid_116_athena_facepaint_gold", "cid_141_athena_facepaint_leopard", "cid_313_athena_facepaint_cyber",
            "cid_029_athena_facepaint_halloween", "cid_030_athena_facepaint_halloweenscythe", "cid_380_athena_facepaint_galaxy"
        ],
        "AthenaDance": [
            "eid_dance_default", "eid_floss", "eid_worm", "eid_take_the_l", "eid_orange_justice",
            "eid_hype", "eid_robot", "eid_groove_jam", "eid_boogie_down", "eid_scenario"
        ],
        "AthenaBackpack": [
            "bid_001_blackshield", "bid_002_wings", "bid_138_galaxy", "bid_029_bunny", "bid_072_gold"
        ],
        "AthenaGlider": [
            "gd_prismatic", "gd_galaxy", "gd_royal", "gd_dragon", "gd_umbrella_default"
        ]
    }
    
    item_index = 0
    for category, list_items in prefixes.items():
        for item_name in list_items:
            item_index += 1
            item_id = f"item_id_{item_index}"
            items[item_id] = {
                "templateId": f"{category}:{item_name}",
                "attributes": {
                    "favorite": False,
                    "item_seen": True,
                    "level": 1,
                    "max_level_bonus": 0,
                    "rnd_max_level_bonus": 0,
                    "variants": [],
                    "xp": 0
                },
                "quantity": 1
            }
            
    return items

class FortniteMockServer(BaseHTTPRequestHandler):
    def _send_html(self, html_content, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(html_content.encode("utf-8"))

    def _send_json(self, data, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode("utf-8"))

    def do_GET(self):
        # 新規登録・ログインのWeb画面
        if self.path == "/register" or self.path == "/login":
            html = """
            <!DOCTYPE html>
            <html lang="ja">
            <head>
                <meta charset="UTF-8">
                <title>Fortnite Private Server Portal</title>
                <style>
                    body { font-family: Arial, sans-serif; background-color: #121212; color: white; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
                    .card { background-color: #1e1e1e; padding: 30px; border-radius: 10px; box-shadow: 0 4px 10px rgba(0,0,0,0.5); width: 350px; text-align: center; }
                    input[type="text"], input[type="password"] { width: 100%; padding: 10px; margin: 10px 0; border: none; border-radius: 5px; box-sizing: border-box; }
                    input[type="submit"] { width: 100%; padding: 10px; background-color: #0070f3; color: white; border: none; border-radius: 5px; cursor: pointer; font-weight: bold; }
                    input[type="submit"]:hover { background-color: #0051a2; }
                    a { color: #0070f3; text-decoration: none; font-size: 14px; }
                </style>
            </head>
            <body>
                <div class="card">
                    <h2>Fortnite Private Server</h2>
                    <form action="/api/register" method="POST">
                        <input type="text" name="username" placeholder="ユーザー名" required><br>
                        <input type="password" name="password" placeholder="パスワード" required><br>
                        <input type="submit" value="アカウント登録 / ログイン">
                    </form>
                    <p style="font-size:12px; color:#888;">登録したアカウントでゲームにログイン可能になります。</p>
                </div>
            </body>
            </html>
            """
            self._send_html(html)
            return

        # バージョンチェック
        if "/fortnite/api/v2/versioncheck" in self.path:
            self._send_json({
                "type": "NO_UPDATE",
                "patchVersion": "",
                "title": "Fortnite",
                "message": "Client is up to date."
            })
            return

        # ライトスイッチ
        if "/lightswitch/api/service/bulk/status" in self.path:
            self._send_json([{
                "serviceInstanceId": "fortnite",
                "status": "UP",
                "message": "Servers are operational",
                "maintenanceUri": None,
                "overrideCatalogIds": [],
                "allowedActions": ["PLAY", "DOWNLOAD"],
                "banned": False
            }])
            return

        self._send_json({"status": "OK"})

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length).decode('utf-8')

        # Webからの新規登録
        if self.path == "/api/register":
            params = urllib.parse.parse_qs(post_data)
            username = params.get('username', [''])[0]
            password = params.get('password', [''])[0]
            
            if username and password:
                accounts = load_accounts()
                accounts[username] = password
                save_accounts(accounts)
                
                html_success = f"""
                <html>
                <body style="background-color: #121212; color: white; font-family: Arial; text-align: center; margin-top: 50px;">
                    <h2>アカウント「{username}」の登録/更新が成功しました！</h2>
                    <p>これでゲームを起動してログインできます。</p>
                    <a href="/register" style="color: #0070f3;">戻る</a>
                </body>
                </html>
                """
                self._send_html(html_success)
            else:
                self._send_html("入力項目が不正です", status=400)
            return

        # OAuthログイン
        if "/account/api/oauth/token" in self.path:
            params = urllib.parse.parse_qs(post_data)
            username = params.get('username', ['Player'])[0]
            
            self._send_json({
                "access_token": f"token_{username}",
                "expires_in": 28800,
                "token_type": "bearer",
                "account_id": username,
                "client_id": "mock_client_id",
                "displayName": username
            })
            return

        # プロファイル/QueryProfile (全スキン開放の主要ロジック)
        if "/api/game/v2/profile" in self.path:
            # URLからプロファイルID（athenaやcommon_core）を判定
            profile_id = "athena"
            if "profileId=common_core" in self.path:
                profile_id = "common_core"

            # 全スキン・エモートを解放したプロフィールを構築して返却
            profile_changes = []
            if profile_id == "athena":
                items = generate_all_cosmetics()
            else:
                items = {}

            response_payload = {
                "profileRevision": 1,
                "profileId": profile_id,
                "profileChangesBaseRevision": 1,
                "profileChanges": [
                    {
                        "changeType": "fullProfileUpdate",
                        "profile": {
                            "created": "2026-07-25T10:00:00.000Z",
                            "updated": "2026-07-25T10:00:00.000Z",
                            "rvn": 1,
                            "wipeNumber": 1,
                            "accountId": "Player",
                            "profileId": profile_id,
                            "version": "season_x",
                            "items": items,
                            "stats": {
                                "attributes": {
                                    "past_seasons": [],
                                    "season_match_boost": 0,
                                    "loadouts": [
                                        "sandbox_loadout"
                                    ],
                                    "mfa_enabled": True
                                }
                            },
                            "commandRevision": 1
                        }
                    }
                ],
                "serverTime": "2026-07-25T10:00:00.000Z",
                "responseVersion": 1
            }
            self._send_json(response_payload)
            return

        self._send_json({"status": "Success"})

def run():
    server_address = (HOST, PORT)
    httpd = HTTPServer(server_address, FortniteMockServer)
    print(f"エミュレーションWeb＆APIサーバー起動中... http://localhost:{PORT}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nサーバーを停止します。")
        httpd.server_close()

if __name__ == "__main__":
    run()
