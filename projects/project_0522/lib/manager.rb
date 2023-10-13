# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  attr_reader :recent_year
  def initialize(**params)
    super
    @s3                    = AwsS3.new(bucket_key = :us_court)
    @keeper                = Keeper.new
    @run_id                = @keeper.run_id
    @already_inserted_pdfs = @keeper.get_inserted_pdfs
    set_params(params[:recent_year] || Date.today.year)
  end
  
  def download
    @keeper.mark_as_started_download
    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Download Started")
    last_year = list_folders_years.last
    last_index = last_year ? years.find_index(last_year.to_i) : 0
    scraper = Scraper.new
    years[last_index..].each do |year|
      subfolder = create_subfolder("#{@run_id}/#{year}")
      params_combination.each do |comb|
        Hamster.logger.info("POST #{year}-#{comb}, SET CONNECTION\n")
        post_response = scraper.create_post(terms: "#{year}-#{comb}")
        next if post_response.blank?

        parser = Parser.new(JSON.parse(post_response)["results"])
        row_count = 1
        1.upto(parser.last_page) do |page_num|
          Hamster.logger.info("POST #{year}-#{comb}, page: #{page_num}\n")
          post_response = scraper.create_post(terms: "#{year}-#{comb}", page: page_num, row_count: row_count) 
          next if post_response.blank?                                                                     
          parser = Parser.new(JSON.parse(post_response)["results"])
          row_count = parser.row_count
          delete_broken_cases
          downloaded_cases = peon.list(subfolder: subfolder)  

          case_ids = parser.list_link { |link| link[/\d+/] }
          case_ids = case_ids - downloaded_cases
          case_ids.each do |id|
            opinion_page = scraper.get_inner_page id: id, type: 'opinion'
            opinion_pdf = Parser.new(opinion_page).find_opinion_pdf_link
            save_opinion(opinion_pdf, "#{year}_#{id}") if opinion_pdf

            ['info', 'party', 'docket'].each do |content_type|    
              file_name = "#{id}_#{content_type}"
              Hamster.logger.info("___Extract #{file_name}____")
              case_folder = create_subfolder("#{subfolder}/#{id}")                 
              inner_page = scraper.get_inner_page id: id, type: "#{content_type}"
              save_file(inner_page, file_name, case_folder)
            end
          end
        end
      end
    end
    download_more_info(start_date: (Date.today-30).to_s)
    delete_broken_cases
    @keeper.mark_as_finished_download
    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Download Done")
  end

  def download_more_info(start_date: '2016-01-05')   
    scraper = Scraper.new
    date_range = *(Date.parse(start_date)..Date.today).map{|d| d.strftime("%m/%d/%Y")}
    ['SCT', 'COA'].each do |court_type|
      date_range.each do |date|
        body = scraper.get_opinion_info(court_type, CGI.escape(date))
        next if body.nil? || body.blank?
        begin
          cases_info = Parser.new(body).content_from_opinion
        rescue
          next
        end
        Hamster.logger.info("Сhecking date: #{date}")
 
        cases_info.each do |case_id, info|
          Hamster.logger.debug("Parse #{case_id}")
          file_name = "#{case_id.match?(/coa/i) ? 'coa' : 'sct'}_#{case_id}"
          content = Parser.create_body(info)
          save_file(content, file_name, path_more_info) unless downloaded_more_info_files.include?("#{file_name}.gz")
          Hamster.logger.debug("___FILE SAVED: #{file_name}.gz___")
        end
      end
    end
  end

  def store
    @keeper.mark_as_started_store
    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Store Started")
    list_folders_years.each do |year|
      cases = peon.list(subfolder: "#{@run_id}/#{year}")
      cases.each do |case_num|
        path_to_files = "#{@run_id}/#{year}/#{case_num}"
        case_info_file = peon.give(subfolder: path_to_files, file: "#{case_num}_info")
        case_party_file = peon.give(subfolder: path_to_files, file: "#{case_num}_party")
        case_docket_file = peon.give(subfolder: path_to_files, file: "#{case_num}_docket")
        Hamster.logger.info("___STORE_#{case_num} ______")
        
        begin
          @parser = Parser.new(case_info_file, case_num: case_num)
        rescue => e
          Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Case num: #{case_num} is broken.")
          next
        end

        pdf_opinion = check_pdf_opinion(year, case_num)
        desciption_file = check_description_file(@parser.case_id, @parser.court_id)
        case_in_db = @keeper.get_case(@parser.court_id, @parser.case_id)
        hash_more_info = bind_hash_more_info(pdf: pdf_opinion, desc_file: desciption_file, case_in_db: case_in_db)
        info_hash, additional_info_hash = @parser.prepare_info_hashes(hash_more_info)

        @parser.html = case_docket_file
        docket_array = @parser.prepare_docket_array
        info_hash.merge!(case_filed_date: docket_array.last[:activity_date]) {|_k, oldval, newval| oldval || newval} unless docket_array.empty?

        @keeper.store_data(info_hash, MsSaacCaseInfo) 
        @keeper.store_data(additional_info_hash, MsSaacCaseAdditionalInfo)

        @parser.html = case_party_file                     
        party_array = @parser.prepare_party_array
        @keeper.store_data(party_array, MsSaacCaseParty) unless party_array.empty?

        unless docket_array.empty?
          @keeper.store_data(docket_array, MsSaacCaseActivities)
          store_pdf_activities_in_db(docket_array)
        end
        
        info_html_link = @parser.find_info_html_link
        store_html_info_in_db(info_html_link, info_hash) if info_html_link && info_hash
      end
    end
    after_store
    Hamster.logger.info("___________STORE DONE____________")
  end

  private

  def bind_hash_more_info(pdf:, desc_file:, case_in_db:)
    hash = {status_as_of_date: 'Active (probably)'}
    if pdf.present?
      pdf_path = "#{storehouse}store/#{path_more_info}/#{pdf}"
      pdf_raw_content = PDF::Reader.new(pdf_path).pages.map(&:text).join("\n") rescue nil
      hash.merge!(Parser.scan_pdf(pdf_raw_content)) {|_k, oldval, newval| newval ? newval : oldval} if pdf_raw_content
    end
    if desc_file.present?
      file = peon.give(subfolder: path_more_info, file: desc_file)
      case_description_from_source = Parser.new(file).parse_more_info
    end
    case_description_in_db = case_in_db.case_description if case_in_db
    case_description = case_description_in_db ? case_description_in_db : case_description_from_source ? case_description_from_source : nil
    hash.merge!(case_description: case_description)
    hash
  end

  def check_pdf_opinion(year, case_num)
    downloaded_more_info_files.find { |file| file == "#{year}_#{case_num}.pdf" }
  end

  def check_description_file(case_id, court_id)
    court_abbr = court_id == 1 ? 'sct' : 'coa'
    downloaded_more_info_files.find { |f| f[/(?<=#{court_abbr}_).+(?=\.gz$)/] == case_id }
  end

  def store_pdf_activities_in_db(dockets)
    dockets.each do |activity_hash|
      pdf_url = activity_hash[:file]
      next if pdf_url.nil?
      aws_public_link = get_aws_public_link(pdf_url, '.pdf')
      if aws_public_link&.present?
        aws_hash = store_aws_hash(aws_public_link, pdf_url, 'activity')
        store_relations_hash(activity_hash, aws_hash, 'activities')
      end
    end
  end

  def store_html_info_in_db(url, info_hash)
    aws_public_link = get_aws_public_link(url, '_info.html')
    if aws_public_link&.present?
      aws_hash = store_aws_hash(aws_public_link, url, 'info')
      store_relations_hash(info_hash, aws_hash, 'info')
    end
  end

  def get_aws_public_link(url, file_extension)
    @already_inserted_pdfs.has_key?(url) ? @already_inserted_pdfs[url] : save_to_aws(url: url, extension: file_extension)
  end

  def store_aws_hash(aws_link, pdf_url, type)
    aws_hash = @parser.get_aws_link_hash(aws_link, pdf_url, type)
    @keeper.store_data(aws_hash, MsSaacCasePdfsOnAws)
    aws_hash
  end

  def store_relations_hash(data_hash, aws_hash, type)
    relations_hash = bind_relations_hash(data_hash, aws_hash, type)
    model = type == 'info' ?  MsSaacCaseRelationsInfo : MsSaacCaseRelationsActivityPdf 
    @keeper.store_data(relations_hash, model)
  end

  def save_to_aws(url:, extension:)
    body = Scraper.new.download_pdf(url)
    return if body.nil? || body.empty?
    pdf_link_md5_hash = Digest::MD5.hexdigest(url.gsub(/#{Scraper::ORIGIN}/, ''))
    key = "us_courts/#{@parser.court_id}/#{@parser.case_id}/#{pdf_link_md5_hash}" + extension
    @s3.find_files_in_s3(key).empty? ? @s3.put_file(body, key, metadata={url: url}) : "https://court-cases-activities.s3.amazonaws.com/#{key}"
  end

  def bind_relations_hash(hash_1, hash_2, type)
    data_hash = {}
    data_hash["case_#{type}_md5"] = @keeper.add_md5_hash(hash_1, result: 'only_md_5')
    data_hash['case_pdf_on_aws_md5'] = @keeper.add_md5_hash(hash_2, result: 'only_md_5')
    data_hash
  end
  
  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

  def save_opinion(link, name)
    file_name = "#{name}.pdf"
    return if downloaded_more_info_files.include? file_name 
    url = link.gsub("../..", Scraper::ORIGIN)
    pdf_storage_path = "#{storehouse}store/#{path_more_info}/#{file_name}"
    body = Scraper.new.download_pdf(url)
    return unless body
    File.open(pdf_storage_path, "wb") do |f|
      f.write(body)
    end
    Hamster.logger.debug("___PDF SAVED: #{file_name}___")
  end

  def downloaded_more_info_files
    peon.list(subfolder: path_more_info)
  end

  def create_subfolder(subfolder, full_path: false)
    path = "#{storehouse}store/#{subfolder}"
    FileUtils.mkdir_p(path) unless Dir.exist?(path)
    full_path ? path : subfolder
  end

  def after_store
    models = [
      MsSaacCaseInfo, MsSaacCaseAdditionalInfo, MsSaacCaseParty, MsSaacCaseActivities, 
      MsSaacCasePdfsOnAws, MsSaacCaseRelationsActivityPdf, MsSaacCaseRelationsInfo
    ]

    models.each { |model| @keeper.update_delete_status(model)}
    clear
    peon.throw_trash(2)
    @keeper.finish
    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Store finished")
  end

  def clear
    FileUtils.mv("#{storehouse}store/#{@run_id}", "#{storehouse}trash/", force: true)
    File.delete(*Dir.glob("#{storehouse}trash/**/*.pdf"))
  end

  def delete_broken_cases
    peon.list(subfolder: "#{@run_id}").select {|f| f != 'more_info'}.each do |main_folder|
      cases_folders = peon.list(subfolder: "#{@run_id}/#{main_folder}")
      cases_folders.each do |case_f|
        path_to_files = "#{@run_id}/#{main_folder}/#{case_f}"
        folder_size = peon.list(subfolder: path_to_files).count      
        FileUtils.rm_rf("#{storehouse}store/#{path_to_files}") if Dir.exists?("#{storehouse}store/#{path_to_files}") && folder_size != 3
      end
    end
  end

  attr_reader :params_combination, :years, :path_more_info

  def set_params(recent_year)
    @params_combination = %w[A B C D M AD KA COA AP SCT CT AC TS CP SA IA BR CA BD WC EC DR OL FC JP BA AN]
    @years = *(2016..recent_year)
    @path_more_info = create_subfolder("#{@run_id}/more_info")
  end

  def list_folders_years
    main_sub_folder = create_subfolder("#{@run_id}")
    peon.list(subfolder: main_sub_folder).select {|f| f != 'more_info'}.sort rescue []
  end
end
