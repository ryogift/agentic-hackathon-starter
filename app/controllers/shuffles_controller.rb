class ShufflesController < ApplicationController
  DEFAULT_RESTAURANTS = [
    "イタリアン トラットリア",
    "定食屋 まんぷく",
    "中華料理 萬来",
    "カレーハウス スパイス",
    "蕎麦処 やぶ"
  ].freeze

  def index
    @default_restaurants = DEFAULT_RESTAURANTS.join("\n")
  end

  def create
    members = parse_members(params[:members])
    restaurants = parse_restaurants(params[:restaurants])

    if members.length < 3
      @error = "参加者は3名以上必要です"
      @groups = []
    else
      @groups = ShuffleService.new(members, restaurants).call
      @error = nil
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to shuffles_path }
    end
  end

  private

  def parse_members(text)
    return [] if text.blank?

    text.split(/\r?\n/)
        .map(&:strip)
        .reject(&:blank?)
        .uniq
  end

  def parse_restaurants(text)
    return DEFAULT_RESTAURANTS if text.blank?

    parsed = text.split(/\r?\n/)
                 .map(&:strip)
                 .reject(&:blank?)

    parsed.empty? ? DEFAULT_RESTAURANTS : parsed
  end
end
