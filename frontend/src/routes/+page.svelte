<script lang="ts">
  import { shuffleService, type ShuffleGroup } from '$lib/api';

  let participants = '';
  let restaurants = '中華料理店\nイタリアン\n和食レストラン\nカフェ\nファミレス';
  let groups: ShuffleGroup[] = [];
  let isLoading = false;
  let error = '';
  let isRestaurantOpen = false;

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
      `[${group.groupName}] ${group.members.join(', ')} @ ${group.restaurant}`
    ).join('\n');

    navigator.clipboard.writeText(slackText);
  }

  function toggleRestaurant() {
    isRestaurantOpen = !isRestaurantOpen;
  }
</script>

<div class="container">
  <h1>Shuffle Lunch</h1>
  
  <div class="main-content">
    <!-- 左カラム：入力エリア -->
    <div class="left-column">
      <div class="input-section">
        <h2>参加者リスト（1行に1名）</h2>
        <textarea
          bind:value={participants}
          placeholder="名前を入力..."
          rows="8"
        ></textarea>
      </div>

      <div class="input-section accordion-section">
        <button class="accordion-header" on:click={toggleRestaurant}>
          <h2>お店リスト（1行に1店舗）</h2>
          <span class="accordion-icon" class:open={isRestaurantOpen}>▼</span>
        </button>
        {#if isRestaurantOpen}
          <textarea
            bind:value={restaurants}
            placeholder="店舗名を改行区切りで入力"
            rows="6"
          ></textarea>
        {/if}
      </div>

      <button 
        on:click={handleShuffle} 
        disabled={isLoading}
        class="shuffle-btn"
      >
        {isLoading ? 'シャッフル中...' : 'シャッフルする！'}
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
            結果をテキストでコピー
          </button>
        </div>

        <div class="groups-grid">
          {#each groups as group}
            <div class="group-card">
              <h3>{group.groupName}</h3>
              <div class="restaurant">@ {group.restaurant}</div>
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
          <p>メンバーを入力してシャッフルしてください</p>
        </div>
      {/if}
    </div>
  </div>
</div>

<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
  
  :global(body) {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    margin: 0;
    padding: 0;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    position: relative;
  }

  :global(body::before) {
    content: '';
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: 
      radial-gradient(circle at 20% 50%, rgba(120, 119, 198, 0.3) 0%, transparent 50%),
      radial-gradient(circle at 80% 20%, rgba(255, 119, 198, 0.3) 0%, transparent 50%),
      radial-gradient(circle at 40% 80%, rgba(120, 219, 255, 0.3) 0%, transparent 50%);
    pointer-events: none;
    z-index: -1;
  }

  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 24px;
    position: relative;
    z-index: 1;
  }

  h1 {
    text-align: center;
    color: white;
    margin-bottom: 40px;
    font-size: 2.5rem;
    font-weight: 700;
    text-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
    letter-spacing: -0.02em;
  }

  .main-content {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 32px;
    min-height: 600px;
  }

  .left-column, .right-column {
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    border: 1px solid rgba(255, 255, 255, 0.2);
    padding: 32px;
    border-radius: 24px;
    box-shadow: 
      0 20px 40px rgba(0, 0, 0, 0.1),
      inset 0 1px 0 rgba(255, 255, 255, 0.2);
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  }

  .left-column:hover, .right-column:hover {
    transform: translateY(-4px);
    box-shadow: 
      0 32px 64px rgba(0, 0, 0, 0.15),
      inset 0 1px 0 rgba(255, 255, 255, 0.3);
  }

  .input-section {
    margin-bottom: 28px;
  }

  h2 {
    color: white;
    margin-bottom: 16px;
    font-size: 20px;
    font-weight: 600;
    letter-spacing: -0.01em;
  }

  textarea {
    width: 100%;
    padding: 16px 20px;
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 16px;
    font-family: inherit;
    font-size: 14px;
    resize: vertical;
    box-sizing: border-box;
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    color: white;
    transition: all 0.3s ease;
  }

  textarea::placeholder {
    color: rgba(255, 255, 255, 0.6);
  }

  textarea:focus {
    outline: none;
    border-color: rgba(255, 255, 255, 0.4);
    background: rgba(255, 255, 255, 0.15);
    box-shadow: 0 0 0 4px rgba(255, 255, 255, 0.1);
  }

  .shuffle-btn {
    width: 100%;
    padding: 16px 24px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    border-radius: 16px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    margin-top: 16px;
    position: relative;
    overflow: hidden;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: 0 8px 32px rgba(102, 126, 234, 0.3);
  }

  .shuffle-btn:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 12px 40px rgba(102, 126, 234, 0.4);
  }

  .shuffle-btn:active:not(:disabled) {
    transform: translateY(0);
  }

  .shuffle-btn:disabled {
    background: rgba(255, 255, 255, 0.2);
    cursor: not-allowed;
    color: rgba(255, 255, 255, 0.5);
    box-shadow: none;
  }

  .error {
    color: #ff6b6b;
    margin-top: 16px;
    padding: 16px 20px;
    background: rgba(255, 107, 107, 0.1);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 107, 107, 0.2);
    border-radius: 12px;
    font-weight: 500;
  }

  .accordion-section {
    margin-bottom: 28px;
  }

  .accordion-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
    background: transparent;
    border: none;
    cursor: pointer;
    padding: 0;
    margin-bottom: 12px;
  }

  .accordion-header h2 {
    margin: 0;
  }

  .accordion-icon {
    color: white;
    font-size: 14px;
    transition: transform 0.3s ease;
  }

  .accordion-icon.open {
    transform: rotate(180deg);
  }

  .results-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
  }

  .copy-btn {
    padding: 12px 20px;
    background: linear-gradient(135deg, #56ab2f 0%, #a8e6cf 100%);
    color: white;
    border: none;
    border-radius: 12px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 600;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: 0 6px 24px rgba(86, 171, 47, 0.3);
  }

  .copy-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 32px rgba(86, 171, 47, 0.4);
  }

  .groups-grid {
    display: grid;
    gap: 20px;
  }

  .group-card {
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    -webkit-backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 20px;
    padding: 24px;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
    overflow: hidden;
  }

  .group-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
    border-color: rgba(255, 255, 255, 0.3);
  }

  .group-card::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, #667eea, #764ba2, #667eea);
    background-size: 200% 100%;
    animation: shimmer 3s ease-in-out infinite;
  }

  @keyframes shimmer {
    0%, 100% { background-position: 200% 0; }
    50% { background-position: -200% 0; }
  }

  .group-card h3 {
    margin: 0 0 12px 0;
    color: white;
    font-size: 18px;
    font-weight: 600;
    letter-spacing: -0.01em;
  }

  .restaurant {
    font-weight: 600;
    color: #ffd93d;
    margin-bottom: 16px;
    font-size: 16px;
    text-shadow: 0 2px 8px rgba(255, 217, 61, 0.3);
  }

  .members {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  .member {
    background: rgba(255, 255, 255, 0.2);
    backdrop-filter: blur(5px);
    padding: 6px 12px;
    border-radius: 20px;
    font-size: 13px;
    color: white;
    font-weight: 500;
    border: 1px solid rgba(255, 255, 255, 0.1);
    transition: all 0.2s ease;
  }

  .member:hover {
    background: rgba(255, 255, 255, 0.3);
    transform: translateY(-1px);
  }

  .placeholder {
    display: flex;
    align-items: center;
    justify-content: center;
    height: 200px;
    color: rgba(255, 255, 255, 0.7);
    text-align: center;
    font-size: 16px;
    font-weight: 500;
  }

  @media (max-width: 768px) {
    .main-content {
      grid-template-columns: 1fr;
    }
    
    h1 {
      font-size: 2rem;
    }
    
    .left-column, .right-column {
      padding: 24px;
    }
  }
</style>