require "open-uri"
require "nokogiri"
require "net/http"

class TabelogScraperService
  TABELOG_URL = "https://tabelog.com/tokyo/A1307/A130704/R2744/rstLst/".freeze
  USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36".freeze
  MAX_RESTAURANTS = 20

  def fetch_nearby_restaurants(genre_filter: nil)
    html = fetch_html
    restaurants = parse_restaurants(html)

    # Apply genre filter if specified
    if genre_filter.present?
      restaurants.select { |restaurant| restaurant[:genre]&.include?(genre_filter) }
    else
      restaurants
    end
  rescue OpenURI::HTTPError => e
    Rails.logger.error("Tabelog HTTP Error: #{e.message}")
    []
  rescue StandardError => e
    Rails.logger.error("Tabelog Scraper Error: #{e.message}")
    []
  end

  def fetch_available_genres
    html = fetch_html
    restaurants = parse_restaurants(html)

    # Extract unique genres and sort them
    genres = restaurants.map { |r| r[:genre] }
                      .reject(&:blank?)
                      .uniq
                      .sort

    genres
  rescue OpenURI::HTTPError => e
    Rails.logger.error("Tabelog HTTP Error: #{e.message}")
    []
  rescue StandardError => e
    Rails.logger.error("Tabelog Genres Error: #{e.message}")
    []
  end

  private

  def fetch_html
    uri = URI.parse(TABELOG_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE # 開発環境用

    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = USER_AGENT

    response = http.request(request)
    response.body
  end

  def parse_restaurants(html)
    doc = Nokogiri::HTML(html)
    restaurants = []

    # 食べログの店舗リストを取得
    doc.css(".list-rst__rst-name-target, .rstlist-info .list-rst__rst-name a").each do |element|
      break if restaurants.size >= MAX_RESTAURANTS

      name = element.text.strip
      next if name.empty?

      # 親要素から各種情報を取得
      parent = element.ancestors(".list-rst").first
      genre = extract_genre(parent)
      image_url = extract_image_url(parent)
      rating = extract_rating(parent)
      url = extract_url(element)

      restaurants << {
        name: name,
        genre: genre,
        image_url: image_url,
        rating: rating,
        url: url
      }
    end

    # フォールバック: 上記セレクタで取れない場合、別のセレクタを試す
    if restaurants.empty?
      doc.css("a[href*='/tokyo/A']").each do |element|
        break if restaurants.size >= MAX_RESTAURANTS

        href = element["href"]
        next unless href&.match?(%r{/tokyo/A\d+/A\d+/\d+/?$})

        name = element.text.strip
        next if name.empty? || name.length > 50

        restaurants << {
          name: name,
          genre: "",
          image_url: "",
          rating: nil,
          url: href
        }
      end
    end

    restaurants.uniq { |r| r[:name] }
  end

  def extract_genre(parent)
    return "" unless parent

    genre_element = parent.at_css(".list-rst__area-genre")
    return "" unless genre_element

    genre_text = genre_element.text.strip
    # "エリア/ジャンル" 形式から ジャンル部分を抽出
    genre_part = genre_text.split("/").last&.strip || ""

    # ジャンル部分から最初のカテゴリーのみを取得（複数ジャンルの場合）
    # 「・」「,」「、」などの区切り文字で分割して最初の部分を使用
    genre_part.split(/[・,、]/).first&.strip || ""
  end

  def extract_image_url(parent)
    return "" unless parent

    # 店舗画像を取得（複数のセレクタを試す）
    img = parent.at_css(".list-rst__rst-photo-target img, .list-rst__rst-photo img, .list-rst__photo img")

    if img
      # 様々なlazy loading属性を試す
      url = img["data-original"] || img["data-src"] || img["data-lazy"] || img["data-lazy-src"]

      # base64プレースホルダーでない実際のURLがあれば使用
      if url && !url.start_with?("data:")
        return url
      end

      # srcがbase64でなければ使用
      src = img["src"]
      if src && !src.start_with?("data:")
        return src
      end
    end

    # 背景画像として設定されている場合
    photo_div = parent.at_css(".list-rst__rst-photo-target, .list-rst__rst-photo")
    if photo_div
      style = photo_div["style"]
      if style
        match = style.match(/background-image:\s*url\(['"]?([^'")\s]+)['"]?\)/)
        return match[1] if match
      end

      # data属性に画像URLがある場合
      data_url = photo_div["data-original"] || photo_div["data-src"]
      return data_url if data_url && !data_url.start_with?("data:")
    end

    ""
  end

  def extract_rating(parent)
    return nil unless parent

    # 評価スコアを取得
    rating_element = parent.at_css(".list-rst__rating-val, .c-rating__val")
    return nil unless rating_element

    rating_text = rating_element.text.strip
    # 数値を抽出
    rating_text.to_f.positive? ? rating_text.to_f : nil
  end

  def extract_url(element)
    href = element["href"]
    return "" unless href

    # 相対URLの場合は絶対URLに変換
    if href.start_with?("/")
      "https://tabelog.com#{href}"
    else
      href
    end
  end
end
