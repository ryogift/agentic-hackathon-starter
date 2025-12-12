require "test_helper"

class Api::ShufflesControllerTest < ActionDispatch::IntegrationTest
  test "正常系: 3名以上でシャッフルが成功する" do
    post api_shuffles_path, params: {
      participants: ["佐藤", "鈴木", "田中"],
      restaurants: ["店舗A", "店舗B"]
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?("groups")
    assert_equal 1, json["groups"].length
  end

  test "正常系: レスポンスに groupName が含まれる" do
    post api_shuffles_path, params: {
      participants: ["佐藤", "鈴木", "田中", "高橋", "伊藤", "渡辺", "山本"],
      restaurants: ["店舗A", "店舗B"]
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    json["groups"].each_with_index do |group, index|
      expected_name = "Team #{('A'.ord + index).chr}"
      assert_equal expected_name, group["groupName"]
    end
  end

  test "正常系: レスポンスに必要なフィールドが含まれる" do
    post api_shuffles_path, params: {
      participants: ["佐藤", "鈴木", "田中"],
      restaurants: ["店舗A"]
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    group = json["groups"].first

    assert group.key?("id")
    assert group.key?("groupName")
    assert group.key?("members")
    assert group.key?("restaurant")
  end

  test "正常系: 7名の場合は2グループ（4+3）に分かれる" do
    post api_shuffles_path, params: {
      participants: (1..7).map { |i| "メンバー#{i}" },
      restaurants: ["店舗A", "店舗B"]
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal 2, json["groups"].length
    group_sizes = json["groups"].map { |g| g["members"].length }.sort
    assert_equal [3, 4], group_sizes
  end

  test "異常系: 3名未満でエラーが返される" do
    post api_shuffles_path, params: {
      participants: ["佐藤", "鈴木"],
      restaurants: ["店舗A"]
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "参加者は3名以上必要です", json["error"]
  end

  test "異常系: 空の参加者リストでエラーが返される" do
    post api_shuffles_path, params: {
      participants: [],
      restaurants: ["店舗A"]
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "参加者は3名以上必要です", json["error"]
  end

  test "異常系: 参加者パラメータがない場合はエラーが返される" do
    post api_shuffles_path, params: {
      restaurants: ["店舗A"]
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "参加者は3名以上必要です", json["error"]
  end

  test "正常系: 店舗リストが空の場合はデフォルト店舗が使用される" do
    post api_shuffles_path, params: {
      participants: ["佐藤", "鈴木", "田中"],
      restaurants: []
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    default_restaurants = ["中華料理店", "イタリアン", "和食レストラン", "カフェ", "ファミレス"]
    restaurant = json["groups"].first["restaurant"]
    assert_includes default_restaurants, restaurant
  end

  test "正常系: 店舗パラメータがない場合はデフォルト店舗が使用される" do
    post api_shuffles_path, params: {
      participants: ["佐藤", "鈴木", "田中"]
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    default_restaurants = ["中華料理店", "イタリアン", "和食レストラン", "カフェ", "ファミレス"]
    restaurant = json["groups"].first["restaurant"]
    assert_includes default_restaurants, restaurant
  end

  test "正常系: 空白のみの参加者名は除外される" do
    post api_shuffles_path, params: {
      participants: ["佐藤", "  ", "鈴木", "", "田中"],
      restaurants: ["店舗A"]
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    all_members = json["groups"].flat_map { |g| g["members"] }
    assert_equal 3, all_members.length
    assert_equal ["佐藤", "鈴木", "田中"].sort, all_members.sort
  end

  test "正常系: 重複した参加者名は除外される" do
    post api_shuffles_path, params: {
      participants: ["佐藤", "佐藤", "鈴木", "田中"],
      restaurants: ["店舗A"]
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    all_members = json["groups"].flat_map { |g| g["members"] }
    assert_equal 3, all_members.length
  end

  test "正常系: JSONレスポンスが返される" do
    post api_shuffles_path, params: {
      participants: ["佐藤", "鈴木", "田中"],
      restaurants: ["店舗A"]
    }, as: :json

    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
  end
end
