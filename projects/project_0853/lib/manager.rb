require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @keeper.generate_custody_levels
  end

  def scrape(options)
    download(options)
    store(options)
  end

  def download(options)
    letters = letter_range(options)
    letters.each do |letter|
      file_path = "#{store_file_path}/#{letter}.dat"
      data      = []
      page      = 0
      response  = @scraper.search_page
      form_data = @parser.search_form_data(response.body, letter, page)
      response  = @scraper.search(form_data, page)
      loop do
        inmate_ids, last_page = @parser.inmate_list(response.body)
        logger.info "Downloading with letter: #{letter}, page: #{page}, inmates: #{inmate_ids.count}"
        data.concat(inmate_ids)
        if last_page
          store_data(file_path, data)
          break
        end

        page += 1
        form_data = @parser.search_form_data(response.body, letter, page)
        response  = @scraper.search(form_data, page)
      end
    end
  end

  def store(options)
    letters = letter_range(options)
    files   = letters.map{|l| "#{store_file_path}/#{l}.dat"}
    files.each do |file_path|
      store_to_db(file_path)
      File.delete(file_path) if File.exist?(file_path)
    end
    @keeper.regenerate_and_flush
    @keeper.update_history
    @keeper.finish
  end

  def clear
    @keeper.regenerate_and_flush
  end

  def clear_files
    files = Dir.glob(store_file_path + "/*")
    FileUtils.rm_rf files
  end

  private

  def letter_range(options)
    if options[:letter]
      [options[:letter]]
    elsif options[:range]
      st, ed = options[:range].split('-')
      st..ed
    else
      'a'..'z'
    end
  end

  def store_to_db(file_path)
    file_data = File.read(file_path).split("\n") rescue []
    logger.info "Started storing file: #{file_path}, data: #{file_data.count}"
    file_data.each do |data|
      data      = eval(data)
      response  = @scraper.search_page
      form_data = @parser.hidden_field_data(response.body)
      form_data['ctl00$MainContent$txtAIS'] = data[:ais]
      form_data['ctl00$MainContent$btnSearch'] = 'Search'
      response  = @scraper.search(form_data)

      next unless response

      inmate_ids, last_page  = @parser.inmate_list(response.body)     
      form_data   = @parser.hidden_field_data(response.body)
      inmate_data = inmate_ids[0]
      if inmate_data.nil?
        logger.info "Search error with AIS data: #{data}"

        next
      end
      
      form_data['__EVENTTARGET'] = inmate_data[:href]
      begin
        detail_page = @scraper.detail_page(form_data)
        hash_data = @parser.parse_detail_page(detail_page.body, inmate_data)
        @keeper.store(hash_data)
      rescue => e
        logger.info "Raised error inmate_data: #{inmate_data}"
        logger.info e.full_message
        next
      end
      logger.debug "#{'>'*10}Scraped AIS: #{data[:ais]}, Name: #{data[:inmate_name]}"
    end
  end

  def store_data(file_path, data)
    File.open(file_path, 'w+') do |f|
      f.puts(data)
    end
  end

  def store_file_path
    store_path = "#{storehouse}store"
    FileUtils.mkdir_p(store_path)
    store_path
  end
end
