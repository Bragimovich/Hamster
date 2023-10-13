# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @run_id = keeper.run_id
    @inserted_cases = @keeper.get_cases().map{|e| e.split("/").last}
  end


  def download
    scraper = Scraper.new
    parser = Parser.new

    start_year = Date.today.year
    end_year = Date.today.year

    years = (start_year..end_year).map(&:to_s)
    years.each do |year|

      Hamster.logger.debug "Currently Year is -> #{year}"

      response = scraper.fetch_main_page
      cookie = response.headers["set-cookie"]
      tokens = parser.get_access_token(response)
      response = scraper.helper_request(tokens, cookie)
      tokens = parser.get_access_token(response)
      cookie = cookie + response.headers["set-cookie"]
      response = scraper.search_request(year, tokens, 1, cookie)
      save_file(response, year, 1)
      total_pages = parser.get_total_pages(response)
      (2..total_pages).each do |page_no|

        Hamster.logger.debug "Current Page No -> #{page_no}"

        #tokens = parser.get_access_token(response)
        cookie = response.headers["set-cookie"]
        response = scraper.search_request(year, tokens, page_no, cookie)
        save_file(response, year, page_no)
      end
    end

  end

  def download_pdfs
    scraper = Scraper.new
    parser = Parser.new

    start_year = Date.today.year
    end_year = Date.today.year

    years = (start_year..end_year).map(&:to_s)
    years.each do |year|

      files = peon.list(subfolder: year).delete_if { |x| x == ".DS_Store" }
      Dir.mkdir("#{storehouse}store/#{year}_pdfs") unless File.directory?("#{storehouse}store/#{year}_pdfs")
      already_fetched = peon.list(subfolder: "#{year}_pdfs")

      files.each do |file|

        file_content = get_content(file, year)
        pdf_urls = parser.get_pdf_urls(file_content)

        pdf_urls.each do |url|

          file_name = url.split("id=").last.strip() + ".pdf"
          next if already_fetched.include? file_name
          body = scraper.download_pdf_from_url(url)
          save_pdf(body, file_name, "#{year}_pdfs")
        end
      end
    end
  end


  def store
    parser = Parser.new
    run_id = @run_id

    start_year = Date.today.year
    end_year = Date.today.year

    years = (start_year..end_year).map(&:to_s)
    years.each do |year|

      files = peon.list(subfolder: year).delete_if { |x| x == ".DS_Store" }

      files.each do |file|

        file_content = get_content(file, year)
        table = parser.parse_page(file_content, year)

        table.each do |row|
          case_id = row.xpath(".//td")[2].text.strip()
          next if @inserted_cases.include? case_id

          Hamster.logger.debug "currently---->>>> #{case_id}"
          next if case_id == "525, 2016; 526, 527, 528, 529 & 530,2016"

          data_hash = parser.parse_case_info(row, year, run_id)
          keeper.insert_case_info(data_hash)
          data_hash = parser.parse_case_additional_info(row, year, run_id)
          keeper.insert_case_additional_info(data_hash) unless data_hash.empty?
          data_has_activity = parser.parse_case_activities(row, year, run_id)
          keeper.insert_case_activities(data_has_activity) unless data_has_activity.empty?
          data_array = parser.parse_case_party(row, year, run_id)
          keeper.insert_case_party(data_array) unless data_array.empty?
          data_hash_aws = parser.parse_case_pdfs_on_aws(row, year, run_id)
          keeper.insert_case_pdfs_on_aws(data_hash_aws)
          data_hash = parser.parse_relations_activity_pdf(run_id, data_has_activity[:md5_hash], data_hash_aws[:md5_hash])
          keeper.insert_relations_activity_pdf(data_hash)
        end

      end
    end
    keeper.finish
  end

  def get_content(file, sub_folder)
    peon.give(file: file, subfolder: sub_folder)
  end


  private

  attr_accessor :keeper, :sub_folder

  def save_pdf(content, file_name, sub_folder)
    pdf_storage_path = "#{storehouse}store/#{sub_folder}/#{file_name}"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def save_file(response, year, page_no)
    peon.put content: response.body, file: "#{year}_#{page_no}", subfolder: year
  end

end
