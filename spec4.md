# 機能追加仕様書: 食べログスクレイピングによるお店リスト自動取得

## 概要

食べログ（Tabelog）から神谷町駅周辺のランチ情報をスクレイピングし、お店リストに反映する機能を追加する。

## 要件

### 機能概要

1. **「周辺のお店を取得」ボタン**を追加
2. ボタン押下で食べログから神谷町駅周辺のランチ店舗情報を取得
3. 取得した店舗名をお店リストのテキストエリアに反映

### スクレイピング対象

- **URL**: `https://tabelog.com/tokyo/A1307/A130704/R2744/rstLst/`
  - エリア: 神谷町駅（東京メトロ日比谷線）
  - 条件: ランチ営業あり
- **取得件数**: 上位10〜20件程度

### 取得する情報

| 項目 | 用途 |
|------|------|
| 店舗名 | お店リストに表示 |
| ジャンル（任意） | 店舗名の後ろに付加（例: 「イタリアン トラットリア（イタリアン）」） |

## UI設計

### お店リストセクションの変更

```
+------------------------------------------+
| お店リスト（1行に1店舗）          ▼      |
+------------------------------------------+
| [周辺のお店を取得]  ← 新規追加ボタン     |
|                                          |
| テキストエリア                           |
| ・店舗A                                  |
| ・店舗B                                  |
| ・...                                    |
+------------------------------------------+
```

### ボタン仕様

- **ラベル**: 「周辺のお店を取得」
- **位置**: アコーディオン内、テキストエリアの上
- **状態**:
  - 通常: クリック可能
  - 取得中: 「取得中...」＋スピナー表示、クリック不可
  - エラー時: エラーメッセージ表示

### 動作フロー

1. ユーザーがお店リストのアコーディオンを開く
2. 「周辺のお店を取得」ボタンをクリック
3. ローディング表示
4. バックエンドAPIでスクレイピング実行
5. 取得した店舗名をテキストエリアに**上書き**
6. ユーザーは必要に応じて編集可能

## 技術設計

### バックエンドAPI

**エンドポイント**: `GET /api/restaurants/nearby`

**レスポンス例**:
```json
{
  "restaurants": [
    { "name": "イタリアン トラットリア", "genre": "イタリアン" },
    { "name": "麺処 さくら", "genre": "ラーメン" },
    { "name": "和食 花月", "genre": "和食" }
  ]
}
```

### Railsコントローラー

```ruby
# app/controllers/api/restaurants_controller.rb
class Api::RestaurantsController < ApplicationController
  def nearby
    restaurants = TabelogScraperService.new.fetch_nearby_restaurants
    render json: { restaurants: restaurants }
  end
end
```

### スクレイピングサービス

```ruby
# app/services/tabelog_scraper_service.rb
class TabelogScraperService
  TABELOG_URL = "https://tabelog.com/tokyo/A1307/A130704/R2744/rstLst/"

  def fetch_nearby_restaurants
    # Nokogiriでスクレイピング実装
    # User-Agentを適切に設定
    # レート制限を考慮
  end
end
```

### フロントエンド

```typescript
// $lib/api.ts に追加
export const restaurantService = {
  fetchNearby: async (): Promise<Restaurant[]> => {
    const response = await fetch('/api/restaurants/nearby');
    return response.json();
  }
};
```

## 実装ファイル

| ファイル | 操作 | 内容 |
|----------|------|------|
| `config/routes.rb` | 編集 | `/api/restaurants/nearby` 追加 |
| `app/controllers/api/restaurants_controller.rb` | 新規 | nearby アクション |
| `app/services/tabelog_scraper_service.rb` | 新規 | スクレイピングロジック |
| `frontend/src/lib/api.ts` | 編集 | restaurantService 追加 |
| `frontend/src/routes/+page.svelte` | 編集 | 取得ボタン追加 |
| `Gemfile` | 編集 | nokogiri gem 追加（未導入の場合） |

## 注意事項

### スクレイピングに関する配慮

1. **User-Agent**: 適切なUser-Agentヘッダーを設定
2. **リクエスト間隔**: 連続アクセスを避ける（最低1秒間隔）
3. **キャッシュ**: 取得結果を一定時間キャッシュ（推奨: 1時間）
4. **エラーハンドリング**: サイト構造変更時のフォールバック

### robots.txt 確認

食べログの `robots.txt` を確認し、スクレイピング可能なパスであることを確認する。

### 利用規約

本機能は社内利用・学習目的に限定。商用利用時は食べログAPIの利用を検討。

## テスト観点

- [ ] ボタンクリックでAPIが呼び出されること
- [ ] 取得中はローディング表示されること
- [ ] 取得成功時にテキストエリアが更新されること
- [ ] API エラー時にエラーメッセージが表示されること
- [ ] 取得後もテキストエリアは編集可能であること

## 将来拡張（スコープ外）

- エリア選択機能（神谷町駅以外も対応）
- 予算フィルター
- 評価順ソート
- お気に入り店舗の保存
