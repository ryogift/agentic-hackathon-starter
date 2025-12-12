# Agentic Hackathon Starter

ハッカソン用のスターターテンプレート。複数の言語・フレームワークに対応したDevcontainer環境を提供します。

## 対応フレームワーク

### TypeScript/JavaScript (Hono)

```bash
npm install
npm run dev
```

http://localhost:3000 でサーバーが起動します。

### Ruby (Rails 8.0)

```bash
bundle install
rails new . --force --skip-bundle
rails server
```

http://localhost:3000 でサーバーが起動します。

### Python

```bash
pip install -r requirements.txt
python <filename>.py
```

### Go (Gin)

```bash
go mod init myapp
go get -u github.com/gin-gonic/gin
cd go
go run main.go
```

http://localhost:8080 でサーバーが起動します。

## 開発環境

```sh
# Railsサービスを起動
docker compose up rails-api svelte-frontend

# バックグラウンドで起動
docker compose up -d rails

# Rails コンソールにアクセス
docker compose exec rails bin/rails console

# 依存関係の追加後
docker compose exec rails bundle install
```

VS Code Dev Containersを使用しています。

### 事前準備

- Docker Desktop
- VS Code + Dev Containers拡張機能

### 起動方法

1. VS Codeでプロジェクトを開く
2. コマンドパレット → "Dev Containers: Reopen in Container"

### PostgreSQLを使用する場合

デフォルトの `docker-compose.yml` にPostgreSQLが含まれているため、そのまま使用できます。

### MySQLを使用する場合

`docker-compose.mysql.yml` を `docker-compose.yml` にリネームしてからコンテナを起動してください。

```bash
mv docker-compose.yml docker-compose.base.yml 
mv docker-compose.mysql.yml docker-compose.yml
```

### 公開ポート

| ポート | 用途 |
|--------|------|
| 3000 | Rails / Node.js / Hono |
| 5000 | Flask |
| 8000 | Django / FastAPI |
| 8080 | Java / Go |

## プロジェクト構成

```
.
├── .devcontainer/     # Devcontainer設定
├── src/               # TypeScript/Honoソースコード
│   └── index.ts
├── Gemfile            # Ruby/Rails依存関係
├── package.json       # Node.js依存関係
├── tsconfig.json      # TypeScript設定
└── README.md
```

## ライセンス

MIT
