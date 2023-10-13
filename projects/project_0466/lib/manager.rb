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

  def download
    scraper = Scraper.new()
    inactive_records = keeper.fetch_inactive_records_db
    sites = ['cav_public','acms_public']
    party = ['APL','APE']
    status = ['active','inactive']
    sites.each do |site_option|
      party.each do |party_option|
        ('a'..'z').each do |letter|
          subfolder_path = create_subfolder(site_option, letter, party_option)
          downloaded_files = peon.give_list(subfolder: subfolder_path)
          status.each do |current_status|
            page = 1
            while true
              if page == 1
                response = scraper.get_first_page(site_option, party_option, current_status, letter)
                cookie = response.headers['set-cookie']
              else
                response = scraper.get_outer_page(response, cookie)
              end
              save_file(response.body, "page_#{page}_#{party_option}_#{current_status}", subfolder_path)
              links = parser.get_links(response.body)
              links.each do |link|
                file_name = link.scan(/\d+/).first
                next if ((downloaded_files.include? "#{file_name}.gz") || (inactive_records.include? file_name))
                html = scraper.get_inner_page(link)
                save_file(html.body, file_name, subfolder_path)
              end
              break if parser.check_next(response)!='Next'
              page+=1
            end
          end
        end
      end
    end
  end

  def store
    @inactive_records = keeper.fetch_inactive_records_db
    info_md5_hash = keeper.fetch_db_info_md5
    party_info_md5_hash = keeper.fetch_db_party_md5
    party_folders = peon.list(subfolder: "#{keeper.run_id}")
    party_folders.each do |option|
      letter_folders = peon.list(subfolder: "#{keeper.run_id}/#{option}").select{|s| s.include? 'letter_'}.sort
      letter_folders.each do |letter_folder|
        subfolder = "#{keeper.run_id}/#{option}/#{letter_folder}"
        outer_page_files = get_outer_page_files(subfolder)
        outer_page_files.each do |file_name|
          outer_page = peon.give(subfolder: subfolder, file: file_name)
          inner_links = parser.get_links(outer_page)
          data_array_info, data_array_add_info, party_info_array,aws_pdf_array, relations_array = parsed_content(inner_links, option, subfolder, party_info_md5_hash, info_md5_hash)
          add_info_md5_array = data_array_info.map { |hash| hash["md5_hash"] }
          info_md5_array = data_array_add_info.map { |hash| hash["md5_hash"] }
          party_md5_array = party_info_array.map { |hash| hash["md5_hash"] }
          aws_md5_array = aws_pdf_array.map { |hash| hash["md5_hash"] }
          keeper.save_case_info(data_array_info) if data_array_info.count > 0
          keeper.save_add_case_info(data_array_add_info) if data_array_add_info.count > 0
          keeper.save_case_party(party_info_array) if party_info_array.count > 0
          keeper.save_aws(aws_pdf_array, relations_array) if aws_pdf_array.count > 0
          keeper.update_touch_run_id(add_info_md5_array , info_md5_array , party_md5_array , aws_md5_array)
        end
      end
      court_id = option == 'cav_public' ? 481 : 347
      keeper.mark_deleted(court_id)
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser

  def parsed_content(links, option, subfolder, party_info_md5_hash, info_md5_hash)
    data_array_info = []
    data_array_add_info = []
    party_info_array = []
    aws_pdf_array = []
    relations_array = []
    links.each do |link|
      file_name = link.scan(/\d+/).first
      next if @inactive_records.include? file_name
      page = peon.give(subfolder: subfolder, file: file_name)
      next unless parser.valid_record?(page)
      court_id = option == 'cav_public' ? 481 : 347
      info_hash = parser.prepare_info_hash(page, link, keeper.run_id, court_id)
      unless info_md5_hash.include? info_hash["md5_hash"]
        data_array_info << info_hash
        data_array_add_info.concat(parser.prepare_additional_info_hash(page, link, keeper.run_id, court_id))
        aws_hash = make_aws_files(page, link, keeper.run_id, court_id)
        aws_pdf_array << aws_hash
        relations_array << make_relations(court_id, info_hash, aws_hash)
      end
      party_info_array.concat(parser.party_info_hash(page, link, keeper.run_id, party_info_md5_hash, court_id))
    end
    [data_array_info, data_array_add_info, party_info_array, aws_pdf_array, relations_array]
  end

  def make_relations(court_id, info_hash, pdf_hash)
    data_hash = {}
    data_hash["run_id"] = keeper.run_id
    data_hash["court_id"] = court_id
    data_hash["case_info_md5"] = info_hash["md5_hash"]
    data_hash["case_pdf_on_aws_md5"] = pdf_hash["md5_hash"]
    data_hash
  end

  def make_aws_files(page, url, run_id, court_id)
    data_hash = parser.get_aws_files_hash(page, court_id)
    key = "us_courts_expansion_#{data_hash["court_id"]}_#{data_hash["case_id"]}_info.html"
    data_hash["aws_html_link"] = upload_file_to_aws(page, key)
    data_hash["md5_hash"] = parser.create_md5_hash(data_hash)
    data_hash["data_source_url"] = "https://eapps.courts.state.va.us#{url}"
    data_hash["run_id"] = run_id
    data_hash["touched_run_id"] = run_id
    data_hash
  end

  def upload_file_to_aws(html,key)
    @s3.put_file(html, key, metadata={})
  end

  def create_subfolder(option,letter,party)
    data_set_path = "#{storehouse}store/#{keeper.run_id}"
    FileUtils.mkdir(data_set_path) unless Dir.exist?(data_set_path)
    data_set_path = "#{data_set_path}/#{option}"
    FileUtils.mkdir(data_set_path) unless Dir.exist?(data_set_path)
    data_set_path = "#{data_set_path}/letter_#{letter}"
    FileUtils.mkdir(data_set_path) unless Dir.exist?(data_set_path)
    data_set_path.split("store/").last
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

  def get_outer_page_files(subfolder)
    peon.give_list(subfolder: subfolder).select{|file| (file.include? 'page_')}
  end
end
