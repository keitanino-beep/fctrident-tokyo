# FC TRIDENT TOKYO 公式サイト

FOOTBALL 7 SOCIETY LEAGUE 関東リーグ 4部C 所属、FC TRIDENT TOKYO の公式ホームページです。GitHub Pages で公開します。

## ページを直すとき

各ページの中身は `_parts/` にあります。ヘッダー・フッターは `build.ps1` にまとめてあります。`_parts/` を直したら、PowerShell で次を実行すると、公開用の HTML（`index.html` など）が作り直されます。

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
```

## Instagram の自動更新

`.github/workflows/instagram.yml` が6時間ごとに最新投稿を取得し、`instagram.json` と `instagram/` を更新します。`instagram-token.yml` が毎週アクセストークンを更新します。

リポジトリの Secrets に次の2つが必要です。

- `IG_TOKEN`：Instagram API（Instagram ログイン）の長期アクセストークン
- `GH_PAT`：このリポジトリの Secrets を書き換えられる GitHub のトークン
