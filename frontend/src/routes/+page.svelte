<script lang="ts">
  import { onMount } from 'svelte';
  import { shuffleService, restaurantService, type ShuffleGroup, type Restaurant } from '$lib/api';
  import GenreFilter from '$lib/GenreFilter.svelte';

  let participants = '佐藤\n鈴木\n高橋\n田中\n伊藤\n渡辺\n山本\n中村\n小林\n加藤\n吉田';
  let fetchedRestaurants: Restaurant[] = [];
  let filteredRestaurants: Restaurant[] = [];
  let selectedRestaurants: Set<string> = new Set();
  let groups: ShuffleGroup[] = [];
  let isLoading = false;
  let error = '';
  let isLoadingRestaurants = false;
  let restaurantError = '';
  
  // Genre filter state
  let availableGenres: string[] = [];
  let selectedGenre = '';
  let isLoadingGenres = false;

  // 初期表示時に自動で食べログから取得
  onMount(async () => {
    await loadGenres();
    await loadRestaurants();
  });

  async function loadGenres() {
    isLoadingGenres = true;
    try {
      availableGenres = await restaurantService.fetchGenres();
    } catch (err) {
      console.error('Failed to load genres:', err);
    } finally {
      isLoadingGenres = false;
    }
  }

  async function loadRestaurants() {
    isLoadingRestaurants = true;
    restaurantError = '';
    try {
      fetchedRestaurants = await restaurantService.fetchNearby(selectedGenre || undefined);
      applyGenreFilter();
      // 取得後は全店舗を選択状態にする
      selectedRestaurants = new Set(filteredRestaurants.map(r => r.name));
    } catch (err) {
      restaurantError = '店舗情報の取得に失敗しました';
      console.error(err);
    } finally {
      isLoadingRestaurants = false;
    }
  }

  function applyGenreFilter() {
    if (!selectedGenre) {
      filteredRestaurants = fetchedRestaurants;
    } else {
      filteredRestaurants = fetchedRestaurants.filter(r => r.genre.includes(selectedGenre));
    }
  }

  async function handleGenreChange(event: CustomEvent<{ genre: string }>) {
    selectedGenre = event.detail.genre;
    await loadRestaurants();
  }

  function toggleRestaurant(name: string) {
    if (selectedRestaurants.has(name)) {
      selectedRestaurants.delete(name);
    } else {
      selectedRestaurants.add(name);
    }
    selectedRestaurants = selectedRestaurants; // リアクティブ更新
  }

  function selectAll() {
    selectedRestaurants = new Set(filteredRestaurants.map(r => r.name));
  }

  function deselectAll() {
    selectedRestaurants = new Set();
  }

  async function handleShuffle() {
    const participantList = participants.trim().split('\n').filter(p => p.trim());
    const restaurantList = Array.from(selectedRestaurants);

    if (participantList.length < 3) {
      error = '参加者は3名以上で入力してください';
      return;
    }

    if (restaurantList.length === 0) {
      error = '店舗を1つ以上選択してください';
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
    const slackText = groups.map(group => {
      // Find the restaurant URL by matching the name
      const restaurant = filteredRestaurants.find(r => r.name === group.restaurant);
      const restaurantUrl = restaurant?.url || '';
      
      if (restaurantUrl) {
        return `[${group.groupName}] ${group.members.join(', ')} @ ${group.restaurant}\n${restaurantUrl}`;
      } else {
        return `[${group.groupName}] ${group.members.join(', ')} @ ${group.restaurant}`;
      }
    }).join('\n\n');

    navigator.clipboard.writeText(slackText);
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

      <div class="restaurant-section">
        <div class="restaurant-header">
          <h2>お店リスト</h2>
          <div class="restaurant-actions">
            <button class="action-btn" on:click={loadRestaurants} disabled={isLoadingRestaurants}>
              {isLoadingRestaurants ? '取得中...' : '再取得'}
            </button>
            <button class="action-btn" on:click={selectAll}>全選択</button>
            <button class="action-btn" on:click={deselectAll}>全解除</button>
          </div>
        </div>

        <GenreFilter 
          genres={availableGenres}
          selectedGenre={selectedGenre}
          isLoading={isLoadingGenres || isLoadingRestaurants}
          on:change={handleGenreChange}
        />

        {#if restaurantError}
          <div class="error restaurant-error">{restaurantError}</div>
        {/if}

        {#if isLoadingRestaurants}
          <div class="loading">店舗情報を取得中...</div>
        {:else if filteredRestaurants.length > 0}
          <div class="restaurant-scroll-container">
            {#each filteredRestaurants as restaurant}
              <button
                class="restaurant-card"
                class:selected={selectedRestaurants.has(restaurant.name)}
                on:click={() => toggleRestaurant(restaurant.name)}
              >
                {#if restaurant.imageUrl}
                  <img src={restaurant.imageUrl} alt={restaurant.name} loading="lazy" />
                {:else}
                  <div class="no-image">No Image</div>
                {/if}
                <div class="restaurant-info">
                  <h3>{restaurant.name}</h3>
                  {#if restaurant.genre}
                    <span class="genre">{restaurant.genre}</span>
                  {/if}
                  {#if restaurant.rating}
                    <span class="rating">★ {restaurant.rating.toFixed(2)}</span>
                  {/if}
                </div>
                <div class="checkbox">
                  {selectedRestaurants.has(restaurant.name) ? '✓' : ''}
                </div>
                {#if restaurant.url}
                  <a
                    href={restaurant.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    class="external-link"
                    on:click|stopPropagation
                  >
                    ↗
                  </a>
                {/if}
              </button>
            {/each}
          </div>
        {:else}
          <div class="placeholder-small">店舗情報を取得できませんでした</div>
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
    min-width: 0;
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

  .restaurant-error {
    margin-bottom: 12px;
  }

  /* Restaurant Card UI Styles */
  .restaurant-section {
    margin-bottom: 24px;
    overflow: hidden;
    min-width: 0;
  }

  .restaurant-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
    flex-wrap: wrap;
    gap: 8px;
  }

  .restaurant-header h2 {
    margin: 0;
  }

  .restaurant-actions {
    display: flex;
    gap: 8px;
  }

  .action-btn {
    padding: 8px 16px;
    background: rgba(255, 255, 255, 0.2);
    color: white;
    border: 1px solid rgba(255, 255, 255, 0.3);
    border-radius: 8px;
    font-size: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .action-btn:hover:not(:disabled) {
    background: rgba(255, 255, 255, 0.3);
  }

  .action-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .restaurant-scroll-container {
    display: flex;
    gap: 12px;
    overflow-x: auto;
    padding: 8px 0;
    scroll-behavior: smooth;
    -webkit-overflow-scrolling: touch;
    max-width: 100%;
    width: 100%;
  }

  .restaurant-scroll-container::-webkit-scrollbar {
    height: 8px;
  }

  .restaurant-scroll-container::-webkit-scrollbar-track {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 4px;
  }

  .restaurant-scroll-container::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.3);
    border-radius: 4px;
  }

  .restaurant-card {
    flex: 0 0 140px;
    background: rgba(255, 255, 255, 0.1);
    border: 2px solid transparent;
    border-radius: 12px;
    overflow: hidden;
    cursor: pointer;
    transition: all 0.2s ease;
    opacity: 0.5;
    padding: 0;
    text-align: left;
    position: relative;
  }

  .restaurant-card:hover {
    transform: scale(1.02);
    opacity: 0.7;
  }

  .restaurant-card.selected {
    opacity: 1;
    border: 2px solid #ffd93d;
    box-shadow: 0 4px 12px rgba(255, 217, 61, 0.3);
  }

  .restaurant-card img {
    width: 100%;
    aspect-ratio: 4/3;
    object-fit: cover;
    display: block;
  }

  .restaurant-card .no-image {
    width: 100%;
    aspect-ratio: 4/3;
    background: rgba(255, 255, 255, 0.1);
    display: flex;
    align-items: center;
    justify-content: center;
    color: rgba(255, 255, 255, 0.5);
    font-size: 10px;
  }

  .restaurant-info {
    padding: 8px;
    color: white;
  }

  .restaurant-info h3 {
    font-size: 11px;
    font-weight: 600;
    margin: 0 0 4px 0;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .genre {
    font-size: 10px;
    opacity: 0.7;
    display: block;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .rating {
    color: #ffd93d;
    font-size: 11px;
    font-weight: 600;
  }

  .checkbox {
    position: absolute;
    top: 8px;
    right: 8px;
    width: 20px;
    height: 20px;
    background: rgba(0, 0, 0, 0.5);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #ffd93d;
    font-size: 12px;
    font-weight: bold;
  }

  .external-link {
    position: absolute;
    bottom: 8px;
    right: 8px;
    width: 24px;
    height: 24px;
    background: rgba(102, 126, 234, 0.9);
    border-radius: 6px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 14px;
    text-decoration: none;
    transition: all 0.2s ease;
  }

  .external-link:hover {
    background: rgba(102, 126, 234, 1);
    transform: scale(1.1);
  }

  .loading {
    text-align: center;
    padding: 40px;
    color: rgba(255, 255, 255, 0.7);
  }

  .placeholder-small {
    text-align: center;
    padding: 20px;
    color: rgba(255, 255, 255, 0.5);
    font-size: 14px;
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