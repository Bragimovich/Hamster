require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester
  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def run_script
    (keeper.download_status == 'finish') ? store : download
  end

  def download
    url = 'https://find.pitt.edu/Search'
    already_downloaded_files = peon.list(subfolder: "#{keeper.run_id}") rescue []
    last_file = already_downloaded_files.sort.last rescue nil
    last_alpha = (last_file.nil?) ? 'aa' : last_file.split('.')[0]
    array = array_formation(last_alpha)
    array.each do |alpha|
      alpha_search_page_response = scraper.alpha_page_request(url, alpha)
      body = parser.html_parsing(alpha_search_page_response.body)
      next if body.text.include? "0 results found"

      if alpha_search_page_response.body.include? 'Too many people matched'
        multiple_records(alpha, url)
      else
        save_file("#{keeper.run_id}", alpha_search_page_response.body, alpha)
      end
    end
    keeper.finish_download
    store if (keeper.download_status == 'finish')
  end

  def store
    files = peon.list(subfolder: "#{keeper.run_id}") rescue []
    already_inserted_search_params = keeper.fetch_search_params
    files.each do |file|
      search_params = file.split('.').first
      next if already_inserted_search_params.include? search_params
      file_data = peon.give(subfolder: "#{keeper.run_id}", file: file) rescue nil
      next if file_data.nil?

      data_array, md5_hash_array = parser.get_data(file_data, "#{keeper.run_id}", search_params)
      next if data_array.empty?

      keeper.insert_records(data_array)
      keeper.update_touch_run_id(md5_hash_array)
    end

    if (keeper.download_status == 'finish')
      keeper.delete_using_touch_id
      keeper.finish
    end
  end

  private
  attr_accessor :keeper, :scraper, :parser

  def array_formation(last_alpha)
    search_alphas = ('aa'..'zz').map(&:to_s)
    letter = last_alpha[0..1]
    index = search_alphas.find_index(letter)
    array =  search_alphas[index..]
    array
  end

  def multiple_records(alpha, url)
    name_array = ('a'..'z').map(&:to_s)
    name_array.each do |name|
      response = scraper.second_alpha_page_request(url, alpha, name)
      body = parser.html_parsing(response.body)
      next if body.text.include? "0 results found"

      if response.body.include? 'Too many people matched'
        array = ('a'..'z').map(&:to_s)
        array.each do |alphabet|
          response = scraper.third_alpha_page_request(url, alpha, name, alphabet)
          body = parser.html_parsing(response.body)
          next if body.text.include? "0 results found"

          save_file("#{keeper.run_id}", response.body, "#{alpha}#{name}#{alphabet}")
        end
      else
        save_file("#{keeper.run_id}", response.body, "#{alpha}#{name}")
      end
    end
  end

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end
end
