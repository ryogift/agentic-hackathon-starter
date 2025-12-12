# シャッフルランチアプリ - 技術スタック変更手順（ERB → Svelte）

## 変更概要

**Before**: Ruby on Rails（ERB + Hotwire/Turbo）  
**After**: Rails API + Svelte（フロントエンド分離）

## アーキテクチャ変更

### 現在の構成
- Rails MVC（ERB テンプレート）
- Hotwire/Turbo（SPA的な動作）
- SQLite
- ポート: 3000

### 変更後の構成
- Rails API（JSONレスポンスのみ）
- Svelte（独立したフロントエンド）
- SQLite（そのまま）
- ポート: Rails API (3000), Svelte (5173)

## 変更手順

### 1. Rails側の変更

#### 1.1 Gemfileの修正
```ruby
# 削除対象
# gem "propshaft"     # アセットパイプライン不要
# gem "importmap-rails"
# gem "turbo-rails"
# gem "stimulus-rails"

# 追加
gem "rack-cors"      # CORS対応
```

#### 1.2 Rails APIモード化
```bash
# 新しいRails APIアプリケーションを生成
rails new . --api --force --database=sqlite3

# 既存プロジェクトをAPI化する場合
# config/application.rbを修正
config.api_only = true
```

#### 1.3 CORS設定
```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:5173'  # Svelteの開発サーバー
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```

#### 1.4 コントローラーの変更
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  # CSRFトークン無効化（API専用）
end

# app/controllers/shuffle_controller.rb
class ShuffleController < ApplicationController
  def create
    # JSON形式でレスポンス
    render json: { groups: groups, restaurants: restaurants }
  end
end
```

### 2. Svelte側の構築

#### 2.1 Svelteプロジェクト作成
```bash
# フロントエンドディレクトリ作成
mkdir frontend
cd frontend

# Svelteプロジェクト初期化
npm create svelte@latest .
npm install
```

#### 2.2 必要な依存関係追加
```bash
# APIクライアント
npm install axios

# UIライブラリ（オプション）
npm install @tailwindcss/forms tailwindcss
```

#### 2.3 API通信の実装
```javascript
// src/lib/api.js
import axios from 'axios';

const API_BASE = 'http://localhost:3000';

export const shuffleService = {
  async createShuffle(participants, restaurants) {
    const response = await axios.post(`${API_BASE}/shuffle`, {
      participants,
      restaurants
    });
    return response.data;
  }
};
```

### 3. Docker Compose設定の変更

#### 3.1 docker-compose.ymlの更新
```yaml
version: '3.8'

services:
  # Rails API
  rails-api:
    build:
      context: .
      dockerfile: Dockerfile.rails
    volumes:
      - .:/app:cached
      - rails_bundle:/usr/local/bundle
    working_dir: /app
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=development
      - BUNDLE_PATH=/usr/local/bundle
    command: bash -c "bundle install && bin/rails server -b 0.0.0.0"

  # Svelte フロントエンド
  svelte-frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    volumes:
      - ./frontend:/app:cached
      - frontend_node_modules:/app/node_modules
    working_dir: /app
    ports:
      - "5173:5173"
    command: npm run dev -- --host
    depends_on:
      - rails-api

volumes:
  rails_bundle:
  frontend_node_modules:
```

#### 3.2 Svelte用Dockerfileの作成
```dockerfile
# frontend/Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

EXPOSE 5173

CMD ["npm", "run", "dev", "--", "--host"]
```

### 4. 開発フロー

#### 4.1 起動手順
```bash
# 両サービスを同時起動
docker-compose up

# または個別起動
docker-compose up rails-api    # バックエンド: http://localhost:3000
docker-compose up svelte-frontend  # フロントエンド: http://localhost:5173
```

#### 4.2 開発時の確認ポイント
- Rails API: `http://localhost:3000/api/shuffle`（JSONレスポンス）
- Svelte: `http://localhost:5173`（UIアプリケーション）
- CORS設定が正常に動作するか確認

### 5. フォルダ構成（変更後）

```
/
├── app/              # Rails API
│   ├── controllers/
│   └── models/
├── frontend/         # Svelte アプリケーション
│   ├── src/
│   │   ├── routes/
│   │   ├── lib/
│   │   └── app.html
│   ├── static/
│   └── package.json
├── config/
├── docker-compose.yml
├── Dockerfile.rails
└── Gemfile
```

## メリット

### 技術的メリット
- **スケーラビリティ**: フロントエンドとバックエンドの独立デプロイ
- **開発体験**: Viteの高速ビルド、Hot Module Replacement
- **モダンな開発**: TypeScript対応、コンポーネント指向

### 運用メリット
- **チーム開発**: フロントエンド・バックエンドの並行開発
- **技術選択の自由度**: 将来的な技術スタック変更が容易

## 注意事項

1. **CORS設定**: 本番環境では適切なオリジン設定が必要
2. **認証**: セッション認証からJWT等への変更検討
3. **SEO**: SPAのため、必要に応じてSSR（SvelteKit）を検討
4. **デプロイ**: フロントエンドとバックエンドの個別デプロイ戦略が必要