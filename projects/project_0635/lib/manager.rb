require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @sub_folder = "Run_ID_#{@keeper.run_id}"
  end

  def run(params)
    (keeper.get_download_status("#{params[-3]}") == 'finish') ? method(params[-2]).call : method(params.last).call
  end

  def download_committees
    scraper = Scraper.new
    (0..3).map(&:to_i).each do |party_id|
      pages = scraper.do_search(party_id)
      pages.each do |page|
        save_file(page[:HTML], "page_#{page[:Page_Number].to_s}", "#{sub_folder}/Committees/#{page[:Party_ID]}")
      end
    end
    scraper.close_browser
    keeper.finish_download("committees")
    store_committees
  end

  def store_committees
    all_party_folders = peon.list(subfolder: "#{sub_folder}/Committees").sort
    all_party_folders.each do |party_folder|
      all_files = peon.list(subfolder: "#{sub_folder}/Committees/#{party_folder}").sort
      hash_array = []
      all_files.each do |file|
        html = peon.give(file: file, subfolder: "#{sub_folder}/Committees/#{party_folder}")
        page = parser.parse_page(html)
        hash_array = parser.parse_committees(page, keeper.run_id, hash_array)
      end
      keeper.make_insertions("committees", hash_array)
    end
  end

  def download_reports(retries = 10)
    begin
      report_links = keeper.fetch_committees_reports("committees", "report_list_link")
      downloaded_files = fetch_downloaded_files
      scraper = Scraper.new
      cookies = scraper.landing_page_ce
      scraper.close_browser
      url = ""
      report_links.each do |report_link|
        folder_name = Digest::MD5.hexdigest report_link.last
        next if downloaded_files.include? folder_name
        page = 1
        while true
          final_url = (page == 1)? report_link.last : url
          final_url = URI.escape(final_url)
          html = scraper.ce_request(final_url, cookies)
          parsed_object = parser.parse_page(html.body)
          save_file(html.body, "page_#{page}", "#{sub_folder}/Reports/#{folder_name}")
          break if parser.check_next_page(parsed_object)
          url = parser.get_url(parsed_object)
          page += 1
        end
      end
      keeper.finish_download("reports")
      store_reports
    rescue Exception => e
      if retries < 1
        Hamster.report(to: 'UK50M4K3R', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
      download_reports(retries-1)
    end
  end

  def store_reports
    report_links = keeper.fetch_committees_reports("committees", "report_list_link")
    report_links.each do |report_link|
      folder_name = Digest::MD5.hexdigest report_link.last
      files = peon.list(subfolder: "#{sub_folder}/Reports/#{folder_name}") rescue []
      hash_array = []
      files.each do |file|
        next if file.include? 'empty_record'
        html = peon.give(file: file, subfolder: "#{sub_folder}/Reports/#{folder_name}")
        page = parser.parse_page(html)
        hash_array = parser.parse_reports(report_link.first, page, keeper.run_id, report_link.last, hash_array)
      end
      keeper.make_insertions("reports", hash_array)
    end
  end

  def download_ce(retries = 10)
    begin
      downloaded_files = fetch_downloaded_ce
      report_links = keeper.fetch_reports("reports")
      scraper = Scraper.new
      cookies = scraper.landing_page_ce
      scraper.close_browser
      report_links.each do |report|
        file_name = report[2].split('=').last
        next if downloaded_files.include? file_name
        html = scraper.ce_request(report[2], cookies)
        save_file(html.body, file_name.to_s, "#{sub_folder}/CE")
      end
      keeper.finish_download("ce")
      store_ce
    rescue Exception => e
      if retries < 1
        Hamster.report(to: 'UK50M4K3R', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
      download_ce(retries-1)
    end
  end

  def store_ce
    report_links = keeper.fetch_reports("reports")
    already_inserted_links = keeper.fetch_committees_reports("expenditures", "data_source_url")
    contributions_array = []
    expenditures_array = []
    report_links.each do |report|
      file_name = report[2].split('=').last
      next if (already_inserted_links.select{|a| a[1].include? file_name}.count > 0)
      html = peon.give(file: file_name, subfolder: "#{sub_folder}/CE") rescue nil
      next if html.nil?
      page = parser.parse_page(html)
      next if page.text.empty?
      contributions_array = parser.contributions_unitem(page, report, keeper.run_id, contributions_array)
      contributions_array = parser.contributions_item(page, report, keeper.run_id, contributions_array)
      expenditures_array = parser.expenditures_unitem(page, report, keeper.run_id, expenditures_array)
      expenditures_array = parser.expenditures_item(page, report, keeper.run_id, expenditures_array)
      keeper.make_insertions("expenditures", expenditures_array.flatten)
      keeper.make_insertions("contributions", contributions_array.flatten)
    end
    keeper.finish if db_status
    tars_to_aws
  end

  private

  attr_accessor :keeper, :parser, :sub_folder

  def db_status
    return true if ((keeper.get_download_status("committees") == 'finish') && (keeper.get_download_status("reports") == 'finish') && (keeper.get_download_status("ce") == 'finish'))
    false
  end

  def create_tar
    path = "#{storehouse}store"
    time = Time.parse(Time.now.to_s).strftime('%Y-%m-%d').to_s
    file_name = ("Run_ID_#{@keeper.run_id}") ? "#{path}/#{time}_#{@keeper.run_id}.tar" : "#{path}/#{time}.tar"
    File.open(file_name, 'wb') { |tar| Minitar.pack(Dir.glob("#{path}"), tar) }
    move_folder("#{path}/*.tar", "#{storehouse}trash")
    clean_dir(path)
    file_name
  end

  def clean_dir(path)
    FileUtils.rm_rf("#{path}/.", secure: true)
  end

  def move_folder(folder_path, path_to)
    FileUtils.mv(Dir.glob("#{folder_path}"), path_to)
  end

  def directory_size(path)
    require 'find'
    size = 0
    Find.find(path) do |f|
      size += File.stat(f).size
    end
  end

  def tars_to_aws
    s3 = AwsS3.new(:hamster,:hamster)
    create_tar
    path = "#{storehouse}trash"
    if (directory_size("#{path}").to_f / 1000000).round(2) > 500 # Mb
      Dir.glob("#{path}/*.tar").each do |tar_path|
        content = IO.read(tar_path)
        key = tar_path.split('/').last
        s3.put_file(content, "tasks/scrape_tasks/st0#{Hamster::project_number}/#{key}", metadata = {})
      end
      clean_dir(path)
    end
  end

  def fetch_downloaded_ce
    peon.list(subfolder: "#{sub_folder}/CE").map{|e| e.gsub('.gz','')} rescue []
  end

  def fetch_downloaded_files
    peon.list(subfolder: "#{sub_folder}/Reports") rescue []
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end
end
