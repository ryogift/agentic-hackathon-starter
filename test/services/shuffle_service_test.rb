require "test_helper"

class ShuffleServiceTest < ActiveSupport::TestCase
  def setup
    @restaurants = [ "店舗A", "店舗B", "店舗C" ]
  end

  test "3名の場合は1グループ（3名）になる" do
    members = [ "佐藤", "鈴木", "田中" ]
    result = ShuffleService.new(members, @restaurants).call

    assert_equal 1, result.length
    assert_equal 3, result[0][:members].length
    assert_equal "Team A", result[0][:group_name]
  end

  test "4名の場合は1グループ（4名）になる" do
    members = [ "佐藤", "鈴木", "田中", "高橋" ]
    result = ShuffleService.new(members, @restaurants).call

    assert_equal 1, result.length
    assert_equal 4, result[0][:members].length
  end

  test "5名の場合は1グループ（5名）になる（特例）" do
    members = [ "佐藤", "鈴木", "田中", "高橋", "伊藤" ]
    result = ShuffleService.new(members, @restaurants).call

    assert_equal 1, result.length
    assert_equal 5, result[0][:members].length
  end

  test "6名の場合は2グループ（3+3）になる" do
    members = (1..6).map { |i| "メンバー#{i}" }
    result = ShuffleService.new(members, @restaurants).call

    assert_equal 2, result.length
    group_sizes = result.map { |g| g[:members].length }.sort
    assert_equal [ 3, 3 ], group_sizes
  end

  test "7名の場合は2グループ（4+3）になる" do
    members = (1..7).map { |i| "メンバー#{i}" }
    result = ShuffleService.new(members, @restaurants).call

    assert_equal 2, result.length
    group_sizes = result.map { |g| g[:members].length }.sort
    assert_equal [ 3, 4 ], group_sizes
  end

  test "8名の場合は2グループ（4+4）になる" do
    members = (1..8).map { |i| "メンバー#{i}" }
    result = ShuffleService.new(members, @restaurants).call

    assert_equal 2, result.length
    group_sizes = result.map { |g| g[:members].length }.sort
    assert_equal [ 4, 4 ], group_sizes
  end

  test "9名の場合は3グループ（3+3+3）になる" do
    members = (1..9).map { |i| "メンバー#{i}" }
    result = ShuffleService.new(members, @restaurants).call

    assert_equal 3, result.length
    group_sizes = result.map { |g| g[:members].length }.sort
    assert_equal [ 3, 3, 3 ], group_sizes
  end

  test "10名の場合は3グループ（4+3+3）になる" do
    members = (1..10).map { |i| "メンバー#{i}" }
    result = ShuffleService.new(members, @restaurants).call

    assert_equal 3, result.length
    group_sizes = result.map { |g| g[:members].length }.sort
    assert_equal [ 3, 3, 4 ], group_sizes
  end

  test "11名の場合は3グループ（4+4+3）になる" do
    members = (1..11).map { |i| "メンバー#{i}" }
    result = ShuffleService.new(members, @restaurants).call

    assert_equal 3, result.length
    group_sizes = result.map { |g| g[:members].length }.sort
    assert_equal [ 3, 4, 4 ], group_sizes
  end

  test "12名の場合は3グループ（4+4+4）になる" do
    members = (1..12).map { |i| "メンバー#{i}" }
    result = ShuffleService.new(members, @restaurants).call

    assert_equal 3, result.length
    group_sizes = result.map { |g| g[:members].length }.sort
    assert_equal [ 4, 4, 4 ], group_sizes
  end

  test "全メンバーがグループに含まれる" do
    members = (1..10).map { |i| "メンバー#{i}" }
    result = ShuffleService.new(members, @restaurants).call

    all_members = result.flat_map { |g| g[:members] }
    assert_equal members.sort, all_members.sort
  end

  test "各グループに店舗が割り当てられる" do
    members = (1..7).map { |i| "メンバー#{i}" }
    result = ShuffleService.new(members, @restaurants).call

    result.each do |group|
      assert_includes @restaurants, group[:restaurant]
    end
  end

  test "グループ名がTeam A, Team B...の形式で付けられる" do
    members = (1..10).map { |i| "メンバー#{i}" }
    result = ShuffleService.new(members, @restaurants).call

    expected_names = [ "Team A", "Team B", "Team C" ]
    actual_names = result.map { |g| g[:group_name] }
    assert_equal expected_names, actual_names
  end

  test "メンバーがシャッフルされる（複数回実行で異なる結果が出る可能性がある）" do
    members = (1..10).map { |i| "メンバー#{i}" }

    results = 10.times.map do
      ShuffleService.new(members, @restaurants).call
    end

    first_group_members = results.map { |r| r[0][:members] }
    # 10回中少なくとも1回は異なる結果が出るはず（確率的テスト）
    assert first_group_members.uniq.length > 1, "シャッフルが行われていない可能性があります"
  end

  test "2名以下の場合は空配列を返す" do
    members = [ "佐藤", "鈴木" ]
    result = ShuffleService.new(members, @restaurants).call

    assert_equal [], result
  end

  test "空のメンバーリストの場合は空配列を返す" do
    members = []
    result = ShuffleService.new(members, @restaurants).call

    assert_equal [], result
  end

  test "大人数（20名）でも正しくグループ分けされる" do
    members = (1..20).map { |i| "メンバー#{i}" }
    result = ShuffleService.new(members, @restaurants).call

    # 全員が含まれている
    all_members = result.flat_map { |g| g[:members] }
    assert_equal 20, all_members.length

    # 各グループは3〜5名（端数調整により5名グループができる場合がある）
    result.each do |group|
      assert group[:members].length >= 3, "グループが3名未満: #{group[:members].length}名"
      assert group[:members].length <= 5, "グループが5名超: #{group[:members].length}名"
    end
  end
end
