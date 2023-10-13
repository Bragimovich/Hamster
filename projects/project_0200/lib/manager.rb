require_relative '../lib/scraper'
require_relative '../lib/keeper'

class Manager < Hamster::Scraper

  SUB_FOLDER = 'graphqlPressRelease'
  BASE_URL = "https://energycommerce.house.gov/graphql"

  def initialize
    super
    @scraper = Scraper.new
    @keeper = Keeper.new
  end

  def download_and_store
    response, _ = @scraper.post_to_graphql(BASE_URL, 10, 1)
    json_response = JSON.parse(response.body)
    total_posts = json_response["data"]["posts"]["meta"]["pagination"]["total"]
    offset = 0
    while true
      if offset > total_posts
        break
      end
      total_response, _ = @scraper.post_to_graphql(BASE_URL, 500, offset)
      json_response = JSON.parse(total_response.body)
      list_of_posts = json_response['data']['posts']['data']
      store(list_of_posts)
      offset += 500
    end
    @keeper.finish
  end

  def store(list_of_posts)
    list_of_posts.each do |post|
      hash = parse_one_json_post(post)
      categories = parse_categories(post)
      @keeper.store_categories(categories)
      @keeper.store(hash)
      categories.each do |x|
        category_id = @keeper.get_category_id(x)
        temp_hash = {article_link: hash['link'], category_id: category_id}
        @keeper.store_article_link_and_its_categories(temp_hash)
      end
    end
  end

  private

  def parse_one_json_post(post)
    to_store = {}
    to_store['title'] = post['attributes']['title']
    article_content = post['attributes']['content']
    to_store['article'] = article_content
    unless article_content.present?
      to_store['dirty_news'] = 1
    end
    teaser = TeaserCorrector.new(Nokogiri::HTML(article_content).text).correct
    to_store['teaser'] = teaser
    unless teaser.present?
      to_store['dirty_news'] = 1
    end
    to_store['link'] = "https://energycommerce.house.gov/posts/" + post['attributes']['slug']
    to_store['date'] = post['attributes']['published']
    to_store['data_source_url'] = "https://energycommerce.house.gov/news/press-release"
    to_store
  end

  def parse_categories(post)
    article_link = "https://energycommerce.house.gov/posts/" + post['attributes']['slug']
    categories = []
    post['attributes']['categories']['data'].each do |category|
      categories << category['attributes']['title']
    end
    categories
  end

end