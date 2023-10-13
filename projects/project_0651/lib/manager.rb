require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @scraper = Scraper.new
    @s3 = AwsS3.new(bucket_key = :us_court)
  end

  def run(year)
    keeper.download_status == 'finish' ? store : download(year)
  end
  
  def download(year)
    date_array = date_array_formation(year)
    year = 'latest_records' if year == '--download'
    response = scraper.redirect_landing
    cookie = response.headers['set-cookie'].split('\;').first
    response = scraper.agree_request(cookie)
    @two_captcha = TwoCaptcha.new(Storage.new.two_captcha['general'], timeout: 200, polling: 10)
    decoded_captcha = solve_captcha
    response = scraper.captcha_request(cookie, decoded_captcha)
    response = scraper.landing_page(cookie)
    page = parser.parsing(response.body)
    all_locations = parser.locations(page)
    case_types_available = parser.case_types(page)
    already_downloaded_folders = peon.list(subfolder: "#{keeper.run_id.to_s}/#{year}") rescue []
    date_array.each do |date|
      next if already_downloaded_folders.include? date.gsub("-","_")
      all_locations.each do |location|
        sub_path = "#{year}/#{date.gsub("-","_")}"
        case_types_available.each do |case_type|
          last_location_path = "#{keeper.run_id}/#{sub_path}/#{location[1]}_#{case_type[1]}"
          response = scraper.do_search(cookie, date.gsub("-","%2F"), case_type[1], location[1])
          pp = parser.parsing(response.body)
          json_response = scraper.json_loading(cookie)
          next if json_response.body.length < 50

          save_file(json_response.body, "outer_page", last_location_path)
          data = parser.json_parsing(json_response.body)
          json_processing(data["rows"], last_location_path, cookie, location[1], case_type[1], sub_path)
        end
      end
    end
    keeper.finish_download
    store if keeper.download_status == "finish"
  end

  def store
    already_inserted_records = keeper.already_inserted_ids
    year_folders = peon.list(subfolder: "#{keeper.run_id}")
    year_folders.each do |year|
      error_count = 0
      date_folders = peon.list(subfolder: "#{keeper.run_id}/#{year}")
      date_folders.each do |date_folder|
        date = date_folder.gsub('_', '-').to_date
        md5_hashes_array = []
        begin
          outer_folder = "#{keeper.run_id}/#{year}/#{date_folder}"
          location_folders = peon.list(subfolder: outer_folder)
          location_folders.each do |location|
            location_path = "#{outer_folder}/#{location}"
            main_page = peon.give_list(subfolder: location_path)
            case_folders = peon.list(subfolder: location_path)
            json = peon.give(subfolder: location_path, file: main_page[0])
            data = parser.json_parsing(json)
            cases = data["rows"].map{|e| [e["EncryptedCaseNumber"], e["CaseNumber"]]}
            cases.each do |case_data|
              next if already_inserted_records.include? case_data[1]

              path = "#{location_path}/#{case_data[1]}"
              next if (!case_folders.include? case_data[1])

              case_type_files    = peon.list(subfolder: path)
              case_info_file     = file_index(case_type_files, "summary.gz")
              case_activity_file = file_index(case_type_files, "action.gz")
              case_party_file    = file_index(case_type_files, "parties.gz")
              case_info_data     = file_extraction(path, case_type_files, case_info_file)
              case_activity_data = file_extraction(path, case_type_files, case_activity_file)
              case_party_data    = file_extraction(path, case_type_files, case_party_file)
              case_info_hash, md5_hash, case_activities_array, case_party_array = parser.parse_files(case_info_data, case_activity_data, case_party_data, "#{keeper.run_id}", case_data[0])
              html_aws_hash, info_relations_hash = upload_info_to_aws(case_info_hash, case_info_data)
              md5_hashes_array << md5_hash
              pdf_hash_array, relations_array = upload_files_to_aws(case_activities_array)
              pdf_hash_array = [] if pdf_hash_array.nil?
              pdf_hash_array << html_aws_hash
              keeper.insert_records([case_info_hash], case_activities_array, case_party_array, pdf_hash_array, relations_array, [info_relations_hash])
            end
          end
        rescue StandardError => e
          error_count += 1
          if error_count > 10
            Hamster.report(to: 'U04MEH7MT1B', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
            return
          end
        end
        keeper.update_touch_run_id(md5_hashes_array)
        keeper.delete_using_touch_id(date)
      end
    end
    keeper.finish if keeper.download_status == "finish"
  end
  
  private

  attr_accessor :parser, :keeper, :two_captcha, :scraper

  def json_processing(rows, path, cookie, location, case_type, sub_path)
    rows.each do |row|
      record_id = row["EncryptedCaseNumber"]
      inner_folder = row['CaseNumber']
      already_downloaded_inner_folders = peon.list(subfolder: path)
      next if already_downloaded_inner_folders.include? inner_folder

      response = scraper.record_search(cookie, record_id)
      tabs = {"summary" => 1, "action" => 2, "parties" => 3}
      tabs.keys.each do |tab|
        response = scraper.record_redirect(cookie, tabs[tab], record_id)
        download_pdfs(response.body, cookie, inner_folder) if tab == "action"
        save_file(response.body, tab.to_s, "#{keeper.run_id}/#{sub_path}/#{location}_#{case_type}/#{inner_folder}")
      end
    end
  end

  def date_array_formation(year)
    if year == '--download'
      start_date = keeper.max_file_date.to_s
      end_date = Date.today.to_s
    elsif year == Date.today.year.to_s
      start_date = Date.strptime("01/01/#{year}", '%m/%d/%Y').to_date.to_s
      end_date = Date.today.to_s
    else
      start_date = "#{year}-01-01"
      end_date = "#{year}-12-31"
    end
    date_generation(start_date, end_date)
  end

  def date_generation(start_date, end_date)
    ((Date.parse(start_date))..(Date.parse(end_date))).map(&:to_s)
  end

  def upload_files_to_aws(case_activities_array)
    pdf_hash_array   = []
    relations_array  = []
    pdf_folder       = peon.list(subfolder: "pdfs").select { |e| e == case_activities_array[0][:case_id] } rescue nil
    return [] if (pdf_folder.nil?) || (pdf_folder.empty?)
    case_activities_array.each do |activity|
      pdf_file_name  = activity[:activity_pdf].split("/").last rescue nil
      next if pdf_file_name.nil?

      pdf_data       = peon.give(subfolder: "pdfs/#{activity[:case_id]}", file: pdf_file_name)
      pdf_aws_hash   = parser.pdfs_on_aws(activity, pdf_file_name)
      pdf_hash_array, relations_array = parser.aws_upload(pdf_aws_hash, pdf_data, @s3, pdf_hash_array, activity[:md5_hash], relations_array, "#{keeper.run_id}")
    end
    [pdf_hash_array, relations_array]
  end

  def upload_info_to_aws(case_info_hash, case_info_file)
    html_aws_hash = parser.pdfs_on_aws(case_info_hash, 'info')
    html_aws_hash, relations_hash = parser.aws_html_upload(html_aws_hash, case_info_file, @s3, case_info_hash[:md5_hash], keeper.run_id)
    [html_aws_hash, relations_hash]
  end

  def file_extraction(path, case_info, file)
    (file.nil?) ? nil : file_data(path, case_info[file])
  end

  def download_pdfs(response, cookie, inner_folder)
    links = parser.fetch_pdf_links(response)
    links.each do |link|
     pdf  = scraper.pdf_request(link, cookie)
     name = link.split('/').last
     save_file(pdf.body, name, "pdfs/#{inner_folder}")
    end
  end

  def solve_captcha(retries = 5)
    options = {
    pageurl: "https://publicrecords.alameda.courts.ca.gov/PRS/Home/Disclaimer",
    googlekey: "6Lf-sv4SAAAAAHRpSvXoB3UXX07EI3mmEEf3yCwP"
    }
    begin
      two_captcha.decode_recaptcha_v2!(options)
    rescue Exception => e
      raise if retries <= 1
      solve_captcha(retries - 1)
    end
  end

  def file_index(case_array, value)
    case_array.find_index(value)
  end

  def file_data(path, file_name)
    peon.give(subfolder: path, file: file_name) rescue nil
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end
end
