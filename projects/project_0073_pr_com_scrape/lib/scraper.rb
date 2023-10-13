# frozen_string_literal: true

require_relative 'parser'

class Scraper < Hamster::Scraper
  PR_FOLDER = "scrape_pr"
  CATEGORY_FOLDER = "scrape_catagory"
  SUB_CATEGORY_FOLDER = "scrape_sub_catagory"

  HEADERS = {
    accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    accept_language:           'en-US,en;q=0.5',
    connection:                'keep-alive',
    upgrade_insecure_requests: '1'
  }

  SCRAPE_PAGES_COUNT = 10
  WEBSITE_URL = 'https://www.pr.com/news-by-country/1'

  def scrape_pr
    response = connect_to(url: WEBSITE_URL, headers: HEADERS)

    ########## Now we need to scrape only newest PR ##############
    # Calculate total count of pages with press releases
    # total_records_count = /Press Releases 1 - 50 of [0-9,]{1,}/.match(response.body)[0]
    #                         .gsub('Press Releases 1 - 50 of ', '').gsub(',', '').to_i
    # pages_count = (total_records_count / 50.to_f).ceil

    scrape_list_of_pr(response.body, 1)

    2.upto(SCRAPE_PAGES_COUNT) do |page|
      response = connect_to(url: "#{WEBSITE_URL}/+#{page}", headers: HEADERS)
      scrape_list_of_pr(response.body, page)
    end
  end

  def scrape_list_of_pr(page_body, page)
    parser = Parser.new
    article_list = parser.parse_pr_list(page_body)
    pr_data = []
    article_list.each do |article_data|
      pr_response = connect_to(url: "https://www.pr.com#{article_data[:pr_url]}", headers: HEADERS)
      logger.info ('PR_URL' * 10).colorize(:green)
      logger.info "https://www.pr.com#{article_data[:pr_url]}"
      data = parser.parse_single_pr(article_data, pr_response)
      pr_data << data
    end
    file_name = "#{page.to_s.parameterize}.json"
    peon.put content: pr_data.to_json, file: "#{file_name}", subfolder: PR_FOLDER
  end

  def scrape_categories_with_links
    response = connect_to(url: 'https://www.pr.com/news-by-category', headers: HEADERS)

    parser = Parser.new
    categories_with_links = parser.parse_categories_with_links(response.body)
    categories_with_links.each do |item|
      category_data_hash = {}
      category_article_data = []
      category_hash = parser.parse_category_with_url(item)
      category_data_hash[:category] = category_hash[:category]

      category_response = connect_to(url: "https://www.pr.com#{category_hash[:relative_category_url]}",
                                     headers: HEADERS)

      ########## Now we need to scrape only newest PR ##############
      # total_records_count = /Press Releases 1 - [0-9,]{1,} of [0-9,]{1,}/.match(category_response.body)[0]
      #                         .gsub(/Press Releases 1 - [0-9,]{1,} of /, '').gsub(',', '').to_i
      # pages_count = (total_records_count / 50.to_f).ceil

      category_articles = parser.parse_category_articles(category_response.body, category_hash)
      category_article_data += category_articles

      2.upto(SCRAPE_PAGES_COUNT) do |page|
        category_response = connect_to(url: "https://www.pr.com#{category_hash[:relative_category_url]}/+#{page}",
                                       headers: HEADERS)
        category_articles = parser.parse_category_articles(category_response.body, category_hash, page: page)
        category_article_data += category_articles
      end
      category_data_hash[:category_article] = category_article_data
      file_name = "#{category_hash[:category][:category].parameterize}.json"
      peon.put content: category_data_hash.to_json, file: "#{file_name}", subfolder: CATEGORY_FOLDER
    end
  end

  def scrape_subcategories_and_links
    response = connect_to(url: 'https://www.pr.com/news-by-category', headers: HEADERS)

    parser = Parser.new
    subcategories_and_links = parser.parse_subcategories_and_links(response.body)

    subcategories_and_links.each do |item|
      subcategory_data_hash = {}
      subcategory_article_data = []
      subcategory_hash = parser.parse_subcategory_with_url(item)
      subcategory_data_hash[:subcategory] = subcategory_hash[:subcategory]
      sub_category_response = connect_to(url: "https://www.pr.com#{subcategory_hash[:relative_subcategory_url]}",
                                         headers: HEADERS)

      ########## Now we need to scrape only newest PR ##############
      # total_records_count = /Press Releases 1 - [0-9,]{1,} of [0-9,]{1,}/.match(sub_category_response.body)[0]
      #                           .gsub(/Press Releases 1 - [0-9,]{1,} of /, '').gsub(',', '').to_i
      # pages_count = (total_records_count / 50.to_f).ceil

      subcategory_articles = parser.parse_subcategory_articles(sub_category_response.body, subcategory_hash)
      subcategory_article_data += subcategory_articles

      2.upto(SCRAPE_PAGES_COUNT) do |page|
        sub_category_response = connect_to(url: "https://www.pr.com#{subcategory_hash[:relative_subcategory_url]}/+#{page}",
                                           headers: HEADERS)
        subcategory_articles = parser.parse_subcategory_articles(sub_category_response.body, subcategory_hash, page: page)
        subcategory_article_data += subcategory_articles
      end
      subcategory_data_hash[:subcategory_article] = subcategory_article_data
      file_name = "#{subcategory_data_hash[:subcategory][:subcategory].parameterize}.json"
      peon.put content: subcategory_data_hash.to_json, file: "#{file_name}", subfolder: SUB_CATEGORY_FOLDER
    end
  end
end
