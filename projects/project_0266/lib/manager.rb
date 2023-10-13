require_relative '../lib/keeper'
require_relative '../lib/scraper'
require_relative '../lib/parser'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper     = Keeper.new
    @parser     = Parser.new
    @scraper    = Scraper.new
    @run_id     = keeper.run_id
    @sub_folder = "RunID_#{run_id}"
  end

  def download(type)
    home_page = scraper.fetch_main_page
    response  = parser.fetch_nokogiri_response(home_page.body)
    states    = parser.fetch_all_states(response)
    boards    = parser.fetch_all_boards(response)

    already_downloaded_states = peon.list(subfolder: "#{sub_folder}/#{type}").sort[0..-2] rescue []
    
    states.each do |state|
      next if already_downloaded_states.include? state
      boards.each do |board|
        main_page = scraper.fetch_main_page
        next if main_page.body.length < 13000

        values = main_page_response(main_page)
        response = (type == 'individual') ? individual_response(values[0], values[1], type, board, state) : business_response(values[0], values[1], type, board, state)
        next if (response[1].nil?) || (response[1].include? 'No results.')

        if parser.source_count(response[1]) < 100
          file_name = 'outer_page'
          save_file(response[2], file_name, "#{sub_folder}/#{type}/#{state}/#{board.gsub(/[^0-9A-Za-z]/, '').downcase}")
          inner_pages(response[0], state, board, type)
        elsif parser.source_count(response[1]) == 100
          all_cities = keeper.fetch_db_cities(state)
          city_running_threads(values, all_cities, state, board,type)
        end
      end
    end
    keeper.finish_download_status(type)
    store if (keeper.get_download_status == ["finish", "finish"])
  end

  def store
    types = ["individual", "business"]
    types.each do |type|
      inserted_md5_hash = keeper.fetch_db_inserted_md5_hash(type)
      states            = peon.list(subfolder: "#{sub_folder}/#{type}")
      states.each do |state|
        boards = peon.list(subfolder: "#{sub_folder}/#{type}/#{state}/")
        boards.each do |board|
          downloaded_files = peon.list(subfolder: "#{sub_folder}/#{type}/#{state}/#{board.gsub(/[^0-9A-Za-z]/, '').downcase}")
          outer_files = downloaded_files.select { |e| e.include? 'outer' }
          outer_files.each do |file|
            outer_file = peon.give(file: file, subfolder: "#{sub_folder}/#{type}/#{state}/#{board}") rescue nil
            next if outer_file.nil?
            response = parser.fetch_nokogiri_response(outer_file)
            links = parser.fetch_downloaded_links(response)
            data_array        = []
            links.each do |link|
              next if link == 'https://elicense.az.gov/cdn-cgi/l/email-protection'

              file_name   = Digest::MD5.hexdigest link
              inner_page  = peon.give(file: "#{file_name}.gz", subfolder: "#{sub_folder}/#{type}/#{state}/#{board}") rescue nil
              next if inner_page.nil?

              response    = parser.fetch_nokogiri_response(inner_page)
              data_hash, md5_hash   =  parser.parse_data(response, link, run_id, type)
              next if inserted_md5_hash.include? md5_hash

              data_array << data_hash
            end
            keeper.insert_records(data_array,type) unless data_array.empty?
          end
        end
      end
      keeper.mark_deleted(type)
    end
    keeper.finish if (keeper.get_download_status == ["finish", "finish"])
  end

  private

  attr_accessor :keeper, :parser, :scraper, :sub_folder, :run_id

  def inner_pages(response, state, board, type)
    all_rows  = parser.fetch_rows(response)
    row_links = parser.fetch_all_links(all_rows)
    row_links.each do |link|
      inner_response   = scraper.get_inner_response(link)
      downloaded_files = peon.list(subfolder: "#{sub_folder}/#{type}/#{state}/#{board.gsub(/[^0-9A-Za-z]/, '').downcase}")
      file_name        = Digest::MD5.hexdigest link
      next if downloaded_files.include? "#{file_name}.gz"

      save_file(inner_response, file_name, "#{sub_folder}/#{type}/#{state}/#{board.gsub(/[^0-9A-Za-z]/, '').downcase}")
    end
  end

  def city_running_threads(values, list, state, board,type)
    mutex = Mutex.new
    sliced_array = list.each_slice(100).to_a
    sliced_array.each do |all_records|
      2.times.map {
        Thread.new(all_records) do |records|
          while (city = mutex.synchronize { records.pop })
            cookie_value = scraper.fetch_cookie
            response = (type == 'individual') ? individual_response(values, cookie_value, type, board, state, city) : business_response(values, cookie_value, type, board, state, city)
            next if (response[1].nil?) || (response[1].include? 'No results.')

            if parser.source_count(response[1]) < 100
              file_name = "outer_page_#{city.downcase.gsub(/[^0-9A-Za-z]/, '')}"
              save_file(response[2], file_name, "#{sub_folder}/#{type}/#{state}/#{board.gsub(/[^0-9A-Za-z]/, '').downcase}")
              inner_pages(response[0], state, board, type)
            elsif parser.source_count(response[1]) == 100
              all_zips = keeper.fetch_db_zipcodes(city).uniq
              zip_running_threads(values, all_zips, cookie_value, state, board, city, type)
            end
          end
        end
      }.each(&:join)
    end
  end

  def zip_running_threads(values, list, cookie_value, state, board, city, type)
    list.each do |zip_value|
      cookie_value = scraper.fetch_cookie
      response = (type == 'individual') ? individual_response(values, cookie_value, type, board, state, city, zip_value) : business_response(values, cookie_value, type, board, state, city, zip_value)
      next if (response[1].nil?) || (response[1].include? 'No results.')

      file_name = "outer_page_#{zip_value}"
      save_file(response[2], file_name, "#{sub_folder}/#{type}/#{state}/#{board.gsub(/[^0-9A-Za-z]/, '').downcase}")
      inner_pages(response[0], state, board, type)
    end
  end

  def switch_page(values, cookie_value, board,state,type = 'switch')
    response_business = scraper.fetch_search_page(values, cookie_value,'switch', board, state)
    business_page     = parser.fetch_nokogiri_response(response_business.body)
    values_business   = parser.get_values(business_page)
    cookie_business   = response_business.headers['set-cookie']
    [values_business,cookie_business]
  end

  def business_response(values, cookie,type, board , state, city = '', zip = '')
    switch_data = switch_page(values, cookie, board, state)
    result_page = scraper.fetch_search_page(switch_data[0], switch_data[1], type, board, state, city, zip)
    process_response(result_page)
  end

  def individual_response(values, cookie,type, board, state , city = '', zip = '')
    result_page = scraper.fetch_search_page(values, cookie, type, board, state, city, zip)
    process_response(result_page)
  end

  def process_response(result_page)
    response    = parser.fetch_nokogiri_response(result_page.body)
    result_text = parser.result_text(response)
    [response, result_text, result_page]
  end

  def main_page_response(main_page)
    response    = parser.fetch_nokogiri_response(main_page.body)
    values      = parser.get_values(response)
    cookie      = main_page.headers['set-cookie']
    [values ,cookie]
  end

  def save_file(body, file_name, sub_folder)
    peon.put content: body.body, file: file_name, subfolder: sub_folder
  end
end
