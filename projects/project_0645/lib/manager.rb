require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/zip_generator'
require 'zip'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @parser   = Parser.new
    @keeper   = Keeper.new
    @sub_folder = "Run_ID_#{@keeper.run_id}"
    @already_inserted_records = keeper.already_inserted_records.map { |e| e.split('_').last }
    @old_records = keeper.old_records.map { |e| e.split('_').last }
  end

  def run
    (keeper.download_status(keeper.run_id)[0].to_s == "true") ? store : download(Date.today.year)
  end

  def download(year = nil)
    years_array = year.nil? ? (2016..Date.today.year.to_i) : [year]
    scraper  = Scraper.new
    years_array.each do |year|
      response = scraper.main_page
      cookie = get_cookie(response)
      main_page = parser.parse_html(response.body)
      body = parser.get_main_body(main_page)
      result_page = scraper.year_page(year, body, cookie)
      final_page = scraper.main_page(result_page["location"])
      iterate_pages(scraper, final_page, result_page["location"], year)
    end
    keeper.mark_download_status(keeper.run_id)
    store if keeper.download_status(keeper.run_id)[0].to_s == "true"
  end

  def store
    years_folder = peon.list(subfolder: sub_folder) rescue []
    years_folder.each do |year|
      page_folder = peon.list(subfolder: "#{sub_folder}/#{year}").sort rescue []
      page_folder.each do |page|
        main_page = peon.give(file: "source_page", subfolder: "#{sub_folder}/#{year}/#{page}")
        main_page = parser.parse_html(main_page)
        links, case_ids = parser.get_links(main_page)
        info_del = []
        activity_del = []
        party_del = []
        links.each_with_index do |link, index|
          begin
            next if already_inserted_records.include? case_ids[index]
            page_number = page.split("_").last
            file_name = Digest::MD5.hexdigest link
            info_page = peon.give(file: "#{file_name}_#{year}_#{page_number}", subfolder: "#{sub_folder}/#{year}/#{page}") rescue nil
            next if info_page.nil?

            party_page = peon.give(file: "#{file_name}_#{year}_#{page_number}_party", subfolder: "#{sub_folder}/#{year}/#{page}") rescue nil
            next if party_page.nil?

            md5_hash_array = insertion(info_page, party_page, info_del, activity_del, party_del)
            next if md5_hash_array.nil?
            keeper.update_touched_run_id(md5_hash_array[0], "CaseInfo")
            keeper.update_touched_run_id(md5_hash_array[2].flatten, "CaseActivity")
            keeper.update_touched_run_id(md5_hash_array[1].flatten, "CaseParty")
          rescue StandardError => e
            msg = "#{e} | #{e.backtrace}"
            logger.error msg
            Hamster.report(to: 'U04N76ASQHW', message: "#{Time.now} - Storing to db failed - #{msg}", use: :slack)
          end
        end
      end
      keeper.mark_deleted("CaseInfo", year)
      keeper.mark_deleted("CaseActivity", year)
      keeper.mark_deleted("CaseParty", year)
    end
    if keeper.download_status(keeper.run_id)[0].to_s == "true"
      keeper.finish
      tars_to_aws
    end
  end

  def upload
    clean_dir("#{storehouse}trash")
    tars_to_aws
  end

  private
  attr_accessor :parser, :keeper, :sub_folder, :already_inserted_records, :old_records

  def clean_dir(path)
    FileUtils.rm_rf("#{path}/.", secure: true)
  end

  def directory_size(path)
    require 'find'
    size = 0
    Find.find(path) do |f|
      size += File.stat(f).size
    end
    size
  end

  def create_zip
    peon.list.each do |run_folder|
      folder = "Run_Id_#{run_folder.scan(/\d+/).join.to_i}"
      peon.list(subfolder: "#{run_folder}").each do |inner_folder|
        file_name = "#{folder}_#{inner_folder}"
        obj = ZipFileGenerator.new("#{storehouse}store/#{folder}/#{inner_folder}", "#{storehouse}trash/#{Hamster::project_number}_#{file_name}.zip")
        obj.write
      end
    end
  end

  def upload_zip
    require "#{Dir.pwd}/lib/ashman/ashman"
    ashman = Hamster::Ashman.new({:aws_opts => {}, account: :hamster, bucket: 'hamster-storage1'})
    all_files = Dir["#{storehouse}trash/*.zip"].map{|e| e.split('/').last}
    all_files.each do |file_name|
      ashman.upload(key: "project_#{Hamster::project_number}_#{file_name}", file_path: "#{storehouse}trash/#{file_name}")
    end
  end

  def tars_to_aws
    path = "#{storehouse}store"
    if (directory_size("#{path}").to_f / 1000000).round(2) > 1000 # Mb
      create_zip
      clean_dir(path)
      upload_zip
    end
    clean_dir("#{storehouse}trash")
  end

  def insertion(info_page, party_page, info_del, activity_del, party_del)
    info_page = parser.parse_html(info_page)
    party_page = parser.parse_html(party_page)
    info_array = parser.get_info(info_page, keeper.run_id)
    return nil if info_array.nil?

    info_del << info_array[0][:md5_hash]
    activities = parser.get_activities(info_page, keeper.run_id)
    party_array = parser.get_party(party_page, keeper.run_id)
    return nil if party_array.nil?

    activity_del << activities.map { |e| e[:md5_hash] }
    party_del << party_array.map { |e| e[:md5_hash] }
    keeper.insert_record("CaseInfo",info_array)
    keeper.insert_record("CaseActivity",activities.flatten)
    keeper.insert_record("CaseParty",party_array.flatten)
    [info_del, party_del, activity_del]
  end

  def iterate_pages(scraper, final_page, url, year)
    page = 0
    max_page = peon.list(subfolder: "#{sub_folder}/#{year}").map{|a| a.split("_").last.to_i}.sort.last rescue 0
    cookie = get_cookie(final_page)
    while true
      page += 1
      files_count = peon.list(subfolder: "#{sub_folder}/#{year}/page_#{page.to_s}").count rescue 0
      next if files_count > 1 && page < max_page
      save_file(final_page, "source_page" , "#{sub_folder}/#{year}/page_#{page}")
      downloaded_files = peon.list(subfolder: "#{sub_folder}/#{year}/page_#{page.to_s}") rescue []
      main_page = parser.parse_html(final_page.body)
      body = parser.get_main_body(main_page)
      links, case_id = parser.get_links(main_page)

        links.each_with_index do |link, index|
          next if (already_inserted_records.include? case_id[index]) || (old_records.include? case_id[index])
          file_name = Digest::MD5.hexdigest link
          next if (downloaded_files.include? "#{file_name}_#{year}_#{page}.gz")
          inner_page = scraper.year_page(year, body, cookie, url, link)
          save_file(inner_page, "#{file_name}_#{year}_#{page}", "#{sub_folder}/#{year}/page_#{page}")
          inner_main_page = parser.parse_html(inner_page.body)
          party_body = parser.get_main_body(inner_main_page)
          party_page = scraper.year_page(year, party_body, cookie, url, "ctl00$ContentPlaceHolder1$gridViewCase", "Parties$0")
          save_file(party_page, "#{file_name}_#{year}_#{page}_party", "#{sub_folder}/#{year}/page_#{page}")
      end
      next_link = parser.next_link(main_page)
      break if next_link.nil?
      final_page = scraper.year_page(year, body, cookie, url, next_link)
    end
  end

  def get_cookie(response)
    response.headers["set-cookie"]
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html.body, file: file_name, subfolder: subfolder
  end

end
