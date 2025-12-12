require "test_helper"

class ShufflesControllerTest < ActionDispatch::IntegrationTest
  test "index ページが表示される" do
    get root_path
    assert_response :success
    assert_select "h1", "Shuffle Lunch"
  end

  test "index ページに参加者入力フォームがある" do
    get shuffles_path
    assert_response :success
    assert_select "textarea[name='members']"
    assert_select "textarea[name='restaurants']"
    assert_select "input[type='submit']"
  end

  test "index ページにデフォルトの店舗リストが表示される" do
    get shuffles_path
    assert_response :success
    assert_match "イタリアン トラットリア", response.body
    assert_match "定食屋 まんぷく", response.body
  end

  test "create で正常にシャッフルされる" do
    post shuffles_path, params: {
      members: "佐藤\n鈴木\n田中\n高橋\n伊藤\n渡辺\n山本"
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match "Team A", response.body
    assert_match "Team B", response.body
  end

  test "create で店舗も結果に含まれる" do
    post shuffles_path, params: {
      members: "佐藤\n鈴木\n田中\n高橋",
      restaurants: "テスト店舗A\nテスト店舗B"
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    # どちらかの店舗が含まれている
    assert response.body.include?("テスト店舗A") || response.body.include?("テスト店舗B")
  end

  test "create で参加者が3名未満の場合はエラーメッセージが表示される" do
    post shuffles_path, params: {
      members: "佐藤\n鈴木"
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match "参加者は3名以上必要です", response.body
  end

  test "create で空のメンバーリストの場合はエラーメッセージが表示される" do
    post shuffles_path, params: {
      members: ""
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match "参加者は3名以上必要です", response.body
  end

  test "create で空行が含まれていても正常に処理される" do
    post shuffles_path, params: {
      members: "佐藤\n\n鈴木\n\n田中\n\n高橋"
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match "Team A", response.body
  end

  test "create で重複名が除去される" do
    post shuffles_path, params: {
      members: "佐藤\n佐藤\n鈴木\n田中"
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    # 重複除去後は3名なので1グループ
    assert_match "Team A", response.body
    # Team Bは存在しない（1グループのみ）
    refute_match "Team B", response.body
  end

  test "create で店舗リストが空の場合はデフォルト店舗が使用される" do
    post shuffles_path, params: {
      members: "佐藤\n鈴木\n田中",
      restaurants: ""
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    # デフォルト店舗のいずれかが含まれている
    default_restaurants = ["イタリアン トラットリア", "定食屋 まんぷく", "中華料理 萬来", "カレーハウス スパイス", "蕎麦処 やぶ"]
    assert default_restaurants.any? { |r| response.body.include?(r) }
  end

  test "turbo_stream レスポンスが返される" do
    post shuffles_path, params: {
      members: "佐藤\n鈴木\n田中\n高橋"
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match "turbo-stream", response.body
    assert_match 'action="update"', response.body
    assert_match 'target="result-container"', response.body
  end
end
