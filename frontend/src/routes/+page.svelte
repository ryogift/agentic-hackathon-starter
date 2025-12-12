<script lang="ts">
  import { shuffleService, type ShuffleGroup } from '$lib/api';

  let participants = '';
  let restaurants = '中華料理店\nイタリアン\n和食レストラン\nカフェ\nファミレス';
  let groups: ShuffleGroup[] = [];
  let isLoading = false;
  let error = '';

  async function handleShuffle() {
    const participantList = participants.trim().split('\n').filter(p => p.trim());
    const restaurantList = restaurants.trim().split('\n').filter(r => r.trim());

    if (participantList.length < 3) {
      error = '参加者は3名以上で入力してください';
      return;
    }

    if (restaurantList.length === 0) {
      error = '店舗を1つ以上入力してください';
      return;
    }

    error = '';
    isLoading = true;

    try {
      const result = await shuffleService.createShuffle(participantList, restaurantList);
      groups = result.groups;
    } catch (err) {
      error = 'シャッフル処理でエラーが発生しました';
      console.error(err);
    } finally {
      isLoading = false;
    }
  }

  function copyToClipboard() {
    const slackText = groups.map(group => 
      `【グループ${group.id}】 ${group.restaurant}\n${group.members.join(', ')}`
    ).join('\n\n');

    navigator.clipboard.writeText(slackText);
  }
</script>

<div class="container">
  <h1>シャッフルランチアプリ</h1>
  
  <div class="main-content">
    <!-- 左カラム：入力エリア -->
    <div class="left-column">
      <div class="input-section">
        <h2>参加者リスト</h2>
        <textarea
          bind:value={participants}
          placeholder="参加者名を改行区切りで入力&#10;例：&#10;田中太郎&#10;佐藤花子&#10;鈴木次郎"
          rows="8"
        ></textarea>
      </div>

      <div class="input-section">
        <h2>店舗リスト</h2>
        <textarea
          bind:value={restaurants}
          placeholder="店舗名を改行区切りで入力"
          rows="6"
        ></textarea>
      </div>

      <button 
        on:click={handleShuffle} 
        disabled={isLoading}
        class="shuffle-btn"
      >
        {isLoading ? 'シャッフル中...' : 'シャッフル実行'}
      </button>

      {#if error}
        <div class="error">{error}</div>
      {/if}
    </div>

    <!-- 右カラム：結果表示 -->
    <div class="right-column">
      {#if groups.length > 0}
        <div class="results-header">
          <h2>グループ分け結果</h2>
          <button on:click={copyToClipboard} class="copy-btn">
            Slack用にコピー
          </button>
        </div>

        <div class="groups-grid">
          {#each groups as group}
            <div class="group-card">
              <h3>グループ {group.id}</h3>
              <div class="restaurant">{group.restaurant}</div>
              <div class="members">
                {#each group.members as member}
                  <span class="member">{member}</span>
                {/each}
              </div>
            </div>
          {/each}
        </div>
      {:else}
        <div class="placeholder">
          <p>シャッフル結果がここに表示されます</p>
        </div>
      {/if}
    </div>
  </div>
</div>

<style>
  :global(body) {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    margin: 0;
    padding: 0;
    background-color: #f5f5f5;
  }

  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
  }

  h1 {
    text-align: center;
    color: #333;
    margin-bottom: 30px;
  }

  .main-content {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 30px;
    min-height: 600px;
  }

  .left-column {
    background: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  }

  .right-column {
    background: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  }

  .input-section {
    margin-bottom: 20px;
  }

  h2 {
    color: #333;
    margin-bottom: 10px;
    font-size: 18px;
  }

  textarea {
    width: 100%;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-family: inherit;
    resize: vertical;
    box-sizing: border-box;
  }

  .shuffle-btn {
    width: 100%;
    padding: 12px;
    background-color: #007bff;
    color: white;
    border: none;
    border-radius: 4px;
    font-size: 16px;
    cursor: pointer;
    margin-top: 10px;
  }

  .shuffle-btn:hover:not(:disabled) {
    background-color: #0056b3;
  }

  .shuffle-btn:disabled {
    background-color: #6c757d;
    cursor: not-allowed;
  }

  .error {
    color: #dc3545;
    margin-top: 10px;
    padding: 10px;
    background-color: #f8d7da;
    border-radius: 4px;
  }

  .results-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
  }

  .copy-btn {
    padding: 8px 16px;
    background-color: #28a745;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
  }

  .copy-btn:hover {
    background-color: #218838;
  }

  .groups-grid {
    display: grid;
    gap: 16px;
  }

  .group-card {
    border: 1px solid #dee2e6;
    border-radius: 8px;
    padding: 16px;
    background-color: #f8f9fa;
  }

  .group-card h3 {
    margin: 0 0 8px 0;
    color: #495057;
    font-size: 16px;
  }

  .restaurant {
    font-weight: bold;
    color: #007bff;
    margin-bottom: 8px;
    font-size: 14px;
  }

  .members {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
  }

  .member {
    background-color: #e9ecef;
    padding: 4px 8px;
    border-radius: 12px;
    font-size: 12px;
    color: #495057;
  }

  .placeholder {
    display: flex;
    align-items: center;
    justify-content: center;
    height: 200px;
    color: #6c757d;
    text-align: center;
  }

  @media (max-width: 768px) {
    .main-content {
      grid-template-columns: 1fr;
    }
  }
</style>