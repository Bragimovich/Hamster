require_relative '../lib/old_parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'
require 'pry'

class Manager < Hamster::Scraper

  SUB_FOLDER = 'pressRelease'
  BASE_URL = "https://energycommerce.house.gov"
  # categories page
  CATEGORIES_URL = 'https://energycommerce.house.gov/about-ec/issues'

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @category_lookup = {}
    @all_categories = UsDeptEnergyAndCommerceCategories.all
    @all_categories.map{|x| @category_lookup[x.category] = x.id }
  end

  def download
    # download categories page
    response ,status = @scraper.get_request(CATEGORIES_URL)
    save_file(response,"categories_page") if status == 200
    page_count = 0
    while true
      url = BASE_URL + "/newsroom/press-releases?page=#{page_count}"
      response ,status = @scraper.get_request(url)
      break if status == 404

      rows = @parser.get_table_rows(response.body)
      rows.each do |row|
        relative_uri = @parser.get_url_from_row(row)
        file_name = Digest::MD5.hexdigest(relative_uri)
        inner_response ,status = @scraper.get_request(BASE_URL + relative_uri)
        next if status != 200
        save_file(inner_response,file_name)
      end
      save_file(response, "page#{page_count}")
      page_count += 1
      # break if results are not found on page
      break if rows.length == 0
    end
  end

  def store
    begin
      process_each_file
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  private

  def process_each_file
    # store categories
    categories_page = peon.give(subfolder: SUB_FOLDER, file: "categories_page")
    categories = @parser.parse_categories(categories_page)
    @keeper.store_categories(categories)

    # parse pages and its inner links
    @all_files = peon.give_list(subfolder: SUB_FOLDER)
    @all_files = @all_files.select {|x| x.include?("page")}
    @all_files.each do |file_name|
      puts "Parsing file #{file_name}".yellow
      file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
      rows = @parser.get_table_rows(file_content)
      rows.each do |row|
        relative_uri = @parser.get_url_from_row(row)
        file_name = Digest::MD5.hexdigest(relative_uri)
        puts "Processing Inner link #{relative_uri}".blue
        inner_file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
        hash = @parser.get_info_from_details_page(inner_file_content)
        categories = @parser.get_article_categories(inner_file_content)
        categories.each do |x|
          temp_hash = {article_link: BASE_URL + relative_uri, category_id: @category_lookup[x] }
          @keeper.store_article_link_and_its_categories(temp_hash)
        end
        hash['link'] = BASE_URL + relative_uri
        @keeper.store(hash)
      end
    end
    @keeper.finish
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end
end