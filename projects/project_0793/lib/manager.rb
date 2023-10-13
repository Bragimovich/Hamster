require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @parser   = Parser.new
    @keeper   = Keeper.new
    @scraper  = Scraper.new
  end

  def run_script
    (keeper.download_status == "finish") ? store : download
  end

  def download
    main_page = get_first_page
    data_year = parser.get_year(main_page)
    dirs = peon.list(subfolder: "#{keeper.run_id}").sort.select { |d| d =~ /^\d{4}/ }
    starting_year = find_starting_year(dirs)
    begin
      start_index = data_year.find_index(starting_year.to_s)
      data_year[start_index..-1].each do |year|
        last_year_folder = peon.list(subfolder: "#{keeper.run_id}/#{year}").max { |a,b| a.to_i <=> b.to_i } rescue []
        page_num = (last_year_folder.empty?) ? 1 : last_year_folder.to_i
        main_page = get_first_page
        vs, vs_generator, event_validator = parser.get_main_body(main_page)
        search_page = scraper.get_search_page(vs, vs_generator, event_validator, year)
        page_num, search_page = skip_pagination(search_page, year, page_num)
        while true
          save_file(search_page, "source_page", "#{keeper.run_id}/#{year}/#{page_num}")
          pp, vs, vs_generator, event_validator  = process_html_for_values(search_page.body)
          fetch_links(vs, vs_generator, event_validator, pp, year, page_num)
          page_num +=1
          break if parser.next_page_exists?(pp, page_num)
          search_page = scraper.pagination(vs, vs_generator, event_validator, year, page_num)
        end
      end
    end
    keeper.finish_download
    store
  end

  def store
    data_array = []
    year_folders = peon.list(subfolder: "#{keeper.run_id}")
    year_folders.each do |folder|
      inner_folders = peon.list(subfolder: "#{keeper.run_id}/#{folder}")
      inner_folders.each do |page_folder|
        files = peon.list(subfolder: "#{keeper.run_id}/#{folder}/#{page_folder}").sort.reject {|folder| folder =~ /source/ } rescue []  
        files.each do |file|
          year = folder.to_i
          html = peon.give(file: file, subfolder: "#{keeper.run_id}/#{folder}/#{page_folder}")
          page = parser.parse_page(html)
          data_array << parser.process_rows(page, year, keeper.run_id)
          if data_array.size == 5000
            keeper.save_record(data_array) rescue nil
            records_md5_hashes = data_array.map { |data| data[:md5_hash] }
            keeper.update_touch_run_id(records_md5_hashes)
            data_array = []
          end
        end
      end
    end
    keeper.save_record(data_array) unless data_array.empty?
    if (keeper.download_status == "finish")
      keeper.delete_using_touch_id
      keeper.finish
    end
  end

  private
  attr_accessor :parser, :keeper, :scraper

  def get_first_page
    page_body = scraper.get_first_page
    parser.parse_page(page_body)
  end

  def skip_pagination(search_page, year, page_num)
    if page_num != 1
      script_counter = 21
      while script_counter < page_num
        search_page = do_request(search_page, year, script_counter)
        script_counter += 20
      end
      search_page = do_request(search_page, year, page_num)
    end
    [page_num, search_page]
  end

  def do_request(search_page, year, script_counter)
    pp, vs, vs_generator, event_validator = process_html_for_values(search_page)
    scraper.pagination(vs, vs_generator, event_validator, year, script_counter)
  end

  def process_html_for_values(search_page)
    pp = parser.parse_page(search_page)
    vs, vs_generator, event_validator = parser.get_string_values(pp)
    [pp, vs, vs_generator, event_validator]
  end

  def fetch_links(vs, vs_generator, event_validator, pp, year, page_num)
    all_rows = parser.get_rows(pp)
    all_rows.each do |row|
      file_name = Digest::MD5.hexdigest row.to_s
      next if file_already_downloaded(year).include? (file_name)
      button_number = row.css('a')[0]['href'].split('$').last.scan(/\d+/).join.to_i
      res = scraper.record(vs, vs_generator, event_validator, year, button_number)
      save_file(res, "#{file_name}", "#{keeper.run_id}/#{year}/#{page_num}")
    end
  end

  def find_starting_year(year)
    year = year.map { |y| y.scan(/\d+/).first.to_i }.sort
    low  = 0
    high = year.length - 1
     while low < high
      middle = (low + high) / 2
      if year[middle] >= 2011
        high = middle
      else
        low = middle + 1
      end
    end
    year[low]
  end

  def file_already_downloaded(year)
    last_folder = peon.list(subfolder: "#{@subfolder}/#{keeper.run_id}/#{year}").max { |a,b| a.to_i <=> b.to_i } rescue nil
    peon.list(subfolder: "#{@subfolder}/#{keeper.run_id}/#{year}/#{last_folder}").reject {|folder| folder =~ /source/ }.map {|a| a.gsub('.gz', '')} rescue []
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html.body, file: file_name, subfolder: subfolder
  end
end
