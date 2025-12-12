class Api::ShufflesController < ApplicationController
  DEFAULT_RESTAURANTS = [
    "中華料理店",
    "イタリアン",
    "和食レストラン",
    "カフェ",
    "ファミレス"
  ].freeze

  def create
    participants = parse_participants(params[:participants])
    restaurants = parse_restaurants(params[:restaurants])

    if participants.length < 3
      render json: {
        error: "参加者は3名以上必要です"
      }, status: :unprocessable_entity
      return
    end

    groups = ShuffleService.new(participants, restaurants).call

    render json: {
      groups: groups.map.with_index(1) do |group, index|
        {
          id: index,
          members: group[:members],
          restaurant: group[:restaurant]
        }
      end
    }
  end

  private

  def parse_participants(participants_array)
    return [] if participants_array.blank?

    participants_array.map(&:strip)
                     .reject(&:blank?)
                     .uniq
  end

  def parse_restaurants(restaurants_array)
    return DEFAULT_RESTAURANTS if restaurants_array.blank?

    parsed = restaurants_array.map(&:strip)
                             .reject(&:blank?)

    parsed.empty? ? DEFAULT_RESTAURANTS : parsed
  end
end
