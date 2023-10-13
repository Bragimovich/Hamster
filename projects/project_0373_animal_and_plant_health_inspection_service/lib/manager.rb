require_relative '../lib/keeper'
require_relative '../lib/scraper'
require_relative '../lib/parser'

class Manager < Hamster::Harvester

  SUB_FOLDER = 'animal_and_plant_health'
  SUB_FOLDER_PROGRAMS = 'animal_and_plant_health_programs'

  def initialize(**params)
    super
    @keeper     = Keeper.new
    @scraper    = Scraper.new
    @parser     = Parser.new
  end

  def download
    url = '/aphis/newsroom/news/all-news-and-announcements'
    url_programs =  '/aphis/newsroom/news/all-program-updates'
    download_data(SUB_FOLDER, url)
    download_data(SUB_FOLDER_PROGRAMS, url_programs)
  end

  def store
    store_data(SUB_FOLDER)
    store_data(SUB_FOLDER_PROGRAMS)
  end
  private

  attr_accessor  :parser ,:keeper , :scraper, :SUB_FOLDER, :SUB_FOLDER_PROGRAMS

  def download_data(path, link)
    @downloaded_file_names = peon.give_list(subfolder: path).map{|e| e.split('.')[0]}
    save_html_pages(path, link)
  end

  def store_data(path)
    already_inserted_links = keeper.pluck_links(path)
    @inserted_cateogries   = keeper.pluck_catagory(path)
    outer_page = peon.give(subfolder: "#{path}", file: 'outer_page.gz')
    downloaded_files = peon.give_list(subfolder: "#{path}")
    records = parser.get_outer_records(outer_page)
    data_array = []
    records.each do |record|
      title, link, date, type, cateogry = parser.process_outer_record(record)
      next if already_inserted_links.include? link

      file_md5 = Digest::MD5.hexdigest link
      file_name = "#{file_md5}.gz"
      next unless downloaded_files.include? file_name

      file_content = peon.give(subfolder: "#{path}", file: file_name)
      data_hash, cateogry = parser.parse(file_content, title, link, date, type, cateogry)
      next if data_hash.nil?

      data_array.append(data_hash)
      cateogries_table_insertion(cateogry, link, path) unless cateogry.empty?
      if data_array.count > 10
        keeper.insert_records(path, data_array)
        data_array = []
      end
    end
     keeper.insert_records(path, data_array) unless data_array.empty?
  end

  def save_html_pages(path ,link)
    outer_page, code = scraper.connect_main(link)
    save_file(outer_page, "outer_page", path)
    links = parser.get_inner_links(outer_page.body)
    process_inner_pages(links, path) 
  end

  def process_inner_pages(links ,path)
    links.each do |link|
      file_name = Digest::MD5.hexdigest link
      next if @downloaded_file_names.include? file_name
      page, code = scraper.connect_to(link)
      next if page.nil?
      save_file(page, file_name, path)
    end
  end

  def cateogries_table_insertion(cateogries, link, path)
    cateogries.each do |cateogry|
      unless @inserted_cateogries.include? cateogry
        keeper.insert_records_category(path, cateogry)
        @inserted_cateogries.push(cateogry)
      end
      id = keeper. pluck_id(path, cateogry)
      keeper.insert_records_links(path, id, link)
    end
  end

  def save_file(html, file_name, folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: "#{folder}"
  end

end
