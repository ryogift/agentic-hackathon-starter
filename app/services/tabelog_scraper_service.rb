require "open-uri"
require "nokogiri"
require "net/http"

class TabelogScraperService
  TABELOG_URL = "https://tabelog.com/tokyo/A1307/A130704/R2744/rstLst/".freeze
  USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36".freeze
  MAX_RESTAURANTS = 20

  def fetch_nearby_restaurants
    html = fetch_html
    parse_restaurants(html)
  rescue OpenURI::HTTPError => e
    Rails.logger.error("Tabelog HTTP Error: #{e.message}")
    []
  rescue StandardError => e
    Rails.logger.error("Tabelog Scraper Error: #{e.message}")
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

      # 親要素からジャンル情報を取得
      genre = extract_genre(element)

      restaurants << {
        name: name,
        genre: genre
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
          genre: ""
        }
      end
    end

    restaurants.uniq { |r| r[:name] }
  end

  def extract_genre(element)
    # 親要素を辿ってジャンル情報を探す
    parent = element.ancestors(".list-rst").first
    return "" unless parent

    genre_element = parent.at_css(".list-rst__area-genre")
    return "" unless genre_element

    genre_text = genre_element.text.strip
    # "エリア/ジャンル" 形式から ジャンル部分を抽出
    genre_text.split("/").last&.strip || ""
  end
end
