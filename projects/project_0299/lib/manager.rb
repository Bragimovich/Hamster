require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
  end
  
  def download
    scraper = Scraper.new
    url = "https://www.sos.state.co.us/pubs/elections/VoterRegNumbers/VoterRegNumbers.html#January"
    main_page = scraper.get_page(url)
    save_file(main_page.body, "main_page", "/#{@keeper.run_id}")
    links = @parser.get_links(main_page.body)
    links.each do |link|
      url = "https://www.sos.state.co.us/pubs/elections/VoterRegNumbers/#{link}"
      file_name = link.split("/")[-2]
      puts "File name is #{file_name}.xlsx"
      file = scraper.get_page(url)
      save_zip(file.body, file_name)
    end
  end

  def store
    main_page = peon.give(file: "main_page.gz", subfolder: "/#{@keeper.run_id}")
    links = @parser.get_links(main_page)
    links.each do |link|
      file_name = link.split("/")[-2]
      path = "#{storehouse}store/#{@keeper.run_id}/#{file_name}.xlsx"
      data_array = @parser.get_parsed_data(path, link, @keeper.run_id)
      @keeper.save_records(data_array)
    end
    @keeper.finish
  end

  def save_zip(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{@keeper.run_id}"
    zip_storage_path = "#{storehouse}store/#{@keeper.run_id}/#{file_name}.xlsx"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end
end
