require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
class Manager < Hamster::Harvester
  
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @s3 = AwsS3.new(bucket_key = :us_court)
  end
  
  def run
    (keeper.download_status == "finish") ? store : download(Date.today.year)
  end

  def download(year = nil)
    scraper = Scraper.new
    years_array = (year.nil?) ? (2016..Date.today.year.to_i).map(&:to_s) : [year]
    years_array.each do |year|
      subfolder = create_subfolder(year)
      downloaded_files = peon.give_list(subfolder: subfolder)
      already_inserted_records = keeper.inserted_links
      search_page = scraper.get_search_page
      page = parser.parse_nokogiri(search_page.body)
      verification_token = parser.get_verification_token(page)
      html = scraper.get_outer_page(year, verification_token, search_page)
      save_file(html.body, "main_page_#{year}", subfolder)
      links = parser.get_links(html.body)
      links.each_with_index do |link|
        file_name = Digest::MD5.hexdigest link
        next if (downloaded_files.include? "#{file_name}.gz") || (already_inserted_records.include? "https://www.appeals2.az.gov/ODSPlus/#{link}")
        html = scraper.get_inner_page(link)
        save_file(html.body, file_name, subfolder)
      end
    end
    keeper.finish_download
    store if (keeper.download_status == "finish")
  end

  def store
    already_inserted_records = keeper.inserted_links
    year_folders = peon.list(subfolder: "#{keeper.run_id}").sort.reverse
    year_folders.each do |year|
      subfolder = "#{keeper.run_id}/#{year}"
      main_page = peon.give(subfolder: subfolder, file: "main_page_#{year}")
      links = parser.get_links(main_page)
      dates = parser.get_dates(main_page,links.count)
      links.each_with_index do |link , index|
        next if already_inserted_records.include? "https://www.appeals2.az.gov/ODSPlus/#{link}"
        file_name = Digest::MD5.hexdigest link
        raw_html = peon.give(subfolder: subfolder, file: file_name)
        page = parser.parse_nokogiri(raw_html)
        case_info = parser.prepare_info_hash(main_page, page, link,dates[index], keeper.run_id)
        case_party = parser.get_case_parties(page, keeper.run_id)
        additional_info = parser.prepare_additional_info_hash(page, keeper.run_id)
        aws_pdf = parser.get_aws(page, keeper.run_id, s3, raw_html)
        activities = parser.get_case_activities(page, keeper.run_id)
        party_md5 =  case_party.map{|e| e[:md5_hash]}
        additional_info_md5 = additional_info.map{|e| e[:md5_hash]}
        activities_md5 = activities.map{|e| e[:md5_hash]}
        relations = parser.get_relations(case_info[:md5_hash], aws_pdf[:md5_hash])

        keeper.save_case_info(case_info) unless case_info.empty?
        keeper.save_add_case_info(additional_info) unless additional_info.empty?
        keeper.save_case_party(case_party) unless case_party.empty?
        keeper.save_aws(aws_pdf,relations) unless aws_pdf.empty?
        keeper.save_activities(activities) unless activities.empty?
        keeper.update_touched_run_id(case_info[:md5_hash], party_md5, additional_info_md5, activities_md5, aws_pdf[:md5_hash])
        keeper.mark_deleted(year)
      end
    end
    keeper.finish if (keeper.download_status == "finish")
  end

  private

  attr_accessor :parser, :keeper, :s3

  def create_subfolder(year)
    data_set_path = "#{storehouse}store/#{keeper.run_id}"
    FileUtils.mkdir(data_set_path) unless Dir.exist?(data_set_path)
    data_set_path = "#{data_set_path}/#{year}"
    FileUtils.mkdir(data_set_path) unless Dir.exist?(data_set_path)
    data_set_path.split("store/").last
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end
end
