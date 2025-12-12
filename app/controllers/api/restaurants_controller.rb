class Api::RestaurantsController < ApplicationController
  def nearby
    service = TabelogScraperService.new
    restaurants = service.fetch_nearby_restaurants

    render json: { restaurants: restaurants }
  rescue StandardError => e
    Rails.logger.error("Restaurant API Error: #{e.message}")
    render json: { error: "店舗情報の取得に失敗しました" }, status: :service_unavailable
  end
end
