require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = @keeper.run_id
  end

  def run
    download unless keeper.download_status == 'finish'
    store
  end

  attr_accessor :parser, :scraper, :keeper, :run_id

  private
  
  def download(retries = 100)
    begin
      flag = false
      starting_index = resume_download
      downloaded_files = get_downloaded_files
      alphabet_array[starting_index..-1].each do |letters|
        main_page_response = scraper.main_page
        cookie = main_page_response.headers['set-cookie']
        redirect_response = scraper.redirect_request(cookie)
        document = parser.parse_page(redirect_response.body)
        event_validation, view_state, generator = parser.get_values(document)
        counter = 1
        loop do
          response = scraper.search(cookie, letters.first, letters.last, view_state, event_validation, generator, counter, flag)
          document = parser.parse_page(response.body)
          break if document.text.include? "505|error|500|Invalid postback"
          break if document.text.include? 'NO RECORDS SELECTED'
          save_page(response, "source_page_#{counter}", "#{run_id}/#{letters}")
          flag = true
          counter += 1
          download_inner_pages(parser.fetch_links(document), letters, downloaded_files)
          break unless parser.pagination_exists?(document, counter)
          event_validation, view_state, generator = parser.get_string_values(document)
        end
      end
    rescue => exception
      raise if retries < 1
      download(retries - 1)
    end
    keeper.finish_download
  end

  def store
    all_folders = peon.list(subfolder: "#{run_id}").sort rescue []
    all_folders.each do |folder|
      source_pages = peon.list(subfolder: "#{run_id}/#{folder}").keep_if{|e| e.include? 'source'}.sort
      source_pages.each do |source_page|
        source_file = peon.give(subfolder: "#{run_id}/#{folder}", file: "#{source_page}")
        document = parser.parse_page(source_file)
        all_links =  parser.fetch_links(document)
        process_links(all_links, folder)
      end
    end
    keeper.marked_deleted
    keeper.finish
  end

  private

  def download_inner_pages(all_links, letters, downloaded_files)
    all_links.each do |link|
      file_name  = Digest::MD5.hexdigest link
      next if downloaded_files.include? file_name
      response = scraper.link_request(link)
      document = parser.parse_page(response.body)
      save_page(response, file_name, "#{run_id}/#{letters}")
      downloaded_files << file_name
    end
  end

  def process_links(all_links, folder)
    all_links.each do |link|
      file_name  = Digest::MD5.hexdigest link
      html = peon.give(subfolder: "#{run_id}/#{folder}", file: "#{file_name}") rescue nil
      next if html.nil?
      document = parser.parse_page(html)
      immate_id = inmates_fun(document, link)
      arrest_id = arrests_fun(document, link, immate_id)
      charges_array, bonds_array, hearings_array = parser.get_charges_bonds_hearings_data(document, link, run_id, arrest_id)
      charges_bonds_hearings_insertion = charges_bonds_hearings_fun(charges_array, bonds_array, hearings_array, link)
      holdings_insertion = holdings_fun(document, link, arrest_id)
      inmate_ids_insertion = inmate_ids_fun(document, link, immate_id)
    end
  end

  def inmates_fun(document, link)
    inmates_data_hash = parser.get_inmates_data(document, link, run_id)
    immate_id = keeper.insert_for_foreign_key(inmates_data_hash, 'california_fresno_inmates')
  end

  def arrests_fun(document, link, immate_id)
    arrests_data_hash = parser.get_arrests_data(document, link, run_id, immate_id)
    arrest_id = keeper.insert_for_foreign_key(arrests_data_hash, 'california_fresno_arrests')
  end

  def charges_bonds_hearings_fun(charges_array, bonds_array, hearings_array, link)
    return if charges_array.nil?
    charges_array.each_with_index do |hash, idx|
      charge_id = keeper.insert_for_foreign_key(hash, 'california_fresno_charges')
      bond_hash=bonds_array[idx]
      bond_hash[:charge_id] = charge_id
      bond_hash.merge!(parser.get_common(bond_hash, run_id, link))
      hearing_hash = hearings_array[idx]
      hearing_hash[:charge_id] = charge_id
      hearing_hash.merge!(parser.get_common(hearing_hash, run_id, link))
      keeper.insert_data(bond_hash, 'california_fresno_bonds')
      keeper.insert_data(hearing_hash, 'california_fresno_court_hearings')
    end
  end

  def holdings_fun(document, link, arrest_id)
    holdings_array = parser.get_holds(document, link, run_id, arrest_id)
    return if holdings_array.nil?
    keeper.insert_data(holdings_array, 'california_fresno_holdings')
  end

  def inmate_ids_fun(document, link, immate_id)
    inmate_ids_hash = parser.get_inmate_ids(document, link, run_id, immate_id)
    keeper.insert_for_foreign_key(inmate_ids_hash, 'california_fresno_inmate_ids')
  end

  def alphabet_array
    ('AA'..'ZZ').map(&:to_s)
  end

  def get_downloaded_files
    all_folders = peon.list(subfolder: "#{run_id}") rescue []
    all_files = []
    all_folders.each do |folder|
      all_files << peon.list(subfolder: "#{run_id}/#{folder}").reject{|e| e.include? 'source'}.map{|e| e.gsub(".gz",'')}
    end
    all_files.flatten
  end

  def resume_download
    max_folder = peon.list(subfolder: "#{run_id}").sort.max rescue nil
    return 0 if max_folder.nil?
    alphabet_array.index max_folder
  end

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end
end
