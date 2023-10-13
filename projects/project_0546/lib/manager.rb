# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  attr_reader :keeper, :run_id, :pdf_path 
  COURTS = {'nmca' => 488, 'nmsc' => 332}
  
  def initialize(**params)
    super
    @s3                     = AwsS3.new(bucket_key = :us_court)
    @keeper                 = Keeper.new
    @run_id                 = @keeper.run_id
    @already_inserted_pdf   = @keeper.get_inserted_pdf
    @already_inserted_html  = @keeper.get_inserted_html
    @pdf_path               = create_subfolder("#{run_id}/pdf", full_path: true)
  end

  def download
    @keeper.mark_as_started_download
    Hamster.report(to: 'U02JPKC1KSN', message: "0546 Download Started")
    COURTS.keys.each { |court_type| download_cases_for(court_type) }
    @keeper.mark_as_finished_download
    Hamster.logger.info("_________________DOWNLOAD DONE___________________")
    Hamster.report(to: 'U02JPKC1KSN', message: "0546 Download Done")
  end

  def download_cases_for(court_type)
    scraper = Scraper.new
    years = *(2016..Date.today.year)
    last_year = list_folders_years(court_type).last
    last_index = last_year ? years.find_index(last_year.to_i) : 0

    years[last_index..].each do |year| 
      subfolder = create_subfolder("#{run_id}/#{court_type}/#{year}")
      main_page = scraper.get_outer_page(year: year, type: court_type)
      parser = Parser.new(main_page)
      count_pages = parser.check_count_pages

      1.upto(count_pages).each do |page|
        Hamster.logger.info("Year: #{year}, page: #{page}, court: #{court_type}")
        main_page = scraper.get_outer_page(year: year, type: court_type, page: page) if page > 1
        parser.html = main_page
        links = parser.list_links
        next if links.empty?

        downloaded_cases = peon.list(subfolder: subfolder).map { |f| f[/.+(?=\.gz)/] }
        links.each do |case_link|
          file_name = case_link[/(?<=\/)\d+(?=\/)/]
          next if downloaded_cases.include? file_name
          inner_page = scraper.get_inner_page(case_link) 
          pdf_link = Parser.new(inner_page).find_pdf_link
          save_opinion(pdf_link) if pdf_link
          save_file(inner_page, file_name, subfolder)
        end
      end
    end
  end

  def store
   @keeper.mark_as_started_store
   Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Store started")

    COURTS.keys.each do |court_type|
      list_folders_years(court_type).each do |year|
        subfolder = "#{run_id}/#{court_type}/#{year}"
        cases = peon.list(subfolder: subfolder).map { |file| file[/.+(?=\.gz)/] }
        cases.each do |case_num|
          Hamster.logger.info("______STORE__#{case_num} ______")
          file = peon.give(subfolder: subfolder, file: case_num)
          parser = Parser.new(file)

          if parser.all_info_hash.nil? || parser.all_info_hash['case_ids'].nil?
            Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Case_num: #{case_num} is broken")
            next
          end

          case_ids = parser.all_info_hash['case_ids']
          case_ids = case_ids.scan(/[A-Z0-9,-\. ]{4,}?(?:,|$)/).map { |case_id| case_id.squish.sub(/(\.|,| |-)$/, '').sub(/^(\.|,| |-)/, '') }

          cases_info, cases_addit_info, cases_activities, party_not_lawyer, party_lawyer = [], [], [], [], []
          party_not_lawyer_temp = {}

          case_ids.each do |case_id|
            parser.set_base_details(court_type, case_id, case_num)
            pdf_content = check_pdf(parser.find_pdf_link)
            pdf_data_hash = parser.scan_pdf(pdf_content)
            cases_info << parser.case_info
            cases_addit_info << pdf_data_hash[:additional_info]
            party_lawyer << pdf_data_hash[:case_party_lawyer]
            party_not_lawyer_temp[case_id] = pdf_data_hash[:case_party_not_lawyer]
            cases_activities << parser.case_activities(pdf_data_hash[:activity_desc])
          end

          party_not_lawyer_dup = party_not_lawyer_temp.dup
          party_not_lawyer_common_data = party_not_lawyer_temp.find { |_k, v| !v.empty? }
          party_not_lawyer_common_data = party_not_lawyer_common_data ? party_not_lawyer_common_data.last : []
          party_not_lawyer_dup = party_not_lawyer_dup.map do |case_id, arr| 
            arr.empty? ? party_not_lawyer_common_data.map { |hash| hash.merge(case_id: case_id) } : arr
          end
          party_not_lawyer.concat party_not_lawyer_dup
          cases_party = party_not_lawyer.zip(party_lawyer).map(&:flatten)
          cases_data = cases_info.zip(cases_addit_info, cases_party, cases_activities)

          cases_data.each do |data|
            info_hash = keeper.store_info_data(data[0].dup, data[3][:activity_date])
            next unless info_hash
            keeper.store_data(data[1], NmScCaseAdditionalInfo)
            keeper.store_data(data[2], NmScCaseParty)
            keeper.store_data(data[3], NmScCaseActivities)
            store_pdf_on_aws(data[3]) 
            info_html = peon.give(subfolder: subfolder, file: case_num)
            store_html_on_aws(info_hash, info_html)
          end
        end
      end
    end
    after_store
  end

  private

  def store_pdf_on_aws(activity_hash)
    url = activity_hash[:file]
    return unless url

    aws_public_link =  @already_inserted_pdf.find { |entry| entry[0] == activity_hash[:court_id] && entry[1] == activity_hash[:case_id] && entry[2] == url }&.last
    aws_public_link = save_to_aws(url: url, case_id: activity_hash[:case_id], court_id: activity_hash[:court_id], extension: '.pdf') unless aws_public_link

    if aws_public_link&.present?
      aws_hash = {
        court_id: activity_hash[:court_id],
        case_id: activity_hash[:case_id],
        source_link: url,
        aws_link: aws_public_link,
        source_type: 'activity'
      }

      @keeper.store_data(aws_hash, NmScCasePdfsOnAws)
      store_relations_hash(activity_hash, aws_hash, 'activities')
    end
  end

  def store_html_on_aws(info_hash, html)
    url = info_hash[:data_source_url]
    aws_public_link = @already_inserted_html.find { |entry| entry[0] == info_hash[:court_id] && entry[1] == info_hash[:case_id] && entry[2] == url }&.last
    aws_public_link = save_to_aws(url: url, case_id: info_hash[:case_id], court_id: info_hash[:court_id], content: html, extension: '_info.html') unless aws_public_link

    if aws_public_link&.present?
      aws_hash = {
        court_id: info_hash[:court_id],
        case_id: info_hash[:case_id],
        source_link: url,
        aws_html_link: aws_public_link,
        source_type: 'info'
      }

      @keeper.store_data(aws_hash, NmScCasePdfsOnAws)
      store_relations_hash(info_hash, aws_hash, 'info')
    end
  end

  def save_to_aws(**params)
    file_name = Digest::MD5.hexdigest(params[:url].sub(/#{Scraper::ORIGIN}/, ''))
    body = params[:content] || File.read("#{pdf_path}/#{file_name}.pdf")
    key = "us_courts_expansion/#{params[:court_id]}/#{params[:case_id]}_opinion/#{file_name}" + params[:extension]
    @s3.find_files_in_s3(key).empty? ? @s3.put_file(body, key, metadata={url: params[:url]}) : "https://court-cases-activities.s3.amazonaws.com/#{key}"
  end

  def store_relations_hash(data_hash, aws_hash, type)
    relations_hash = bind_relations_hash(data_hash, aws_hash, type)
    model = type == 'info' ?  NmScCaseRelationsInfoPdf : NmScCaseRelationsActivityPdf
    @keeper.store_data(relations_hash, model)
  end

  def bind_relations_hash(hash_1, hash_2, type)
    data_hash = {}
    data_hash["case_#{type}_md5"] = type == 'info' ? hash_1[:md5_hash] : @keeper.add_md5_hash(hash_1, NmScCaseActivities)[:md5_hash]
    data_hash['case_pdf_on_aws_md5'] = @keeper.add_md5_hash(hash_2, NmScCasePdfsOnAws)[:md5_hash]
    data_hash
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

  def save_opinion(link)
    file_name = Digest::MD5.hexdigest(link) + '.pdf'
    return if downloaded_pdf.include? file_name 
    url = Scraper::ORIGIN + link
    pdf_storage_path = "#{pdf_path}/#{file_name}"
    body = Scraper.new.download_pdf(url)
    return unless body
    File.open(pdf_storage_path, "wb") do |f|
      f.write(body)
    end
  end

  def check_pdf(link)
    save_opinion(link) unless downloaded_pdf.find { |file| file == "#{Digest::MD5.hexdigest(link)}.pdf" }
    saved_pdf = downloaded_pdf.find { |file| file == "#{Digest::MD5.hexdigest(link)}.pdf" }
    PDF::Reader.new("#{pdf_path}/#{saved_pdf}").pages.map(&:text).join("\n") rescue nil if saved_pdf
  end

  def create_subfolder(subfolder, full_path: false)
    path = "#{storehouse}store/#{subfolder}"
    FileUtils.mkdir_p(path) unless Dir.exist?(path)
    full_path ? path : subfolder
  end

  def list_folders_years(court_type)
    path = create_subfolder("#{run_id}/#{court_type}")
    peon.list(subfolder: path).sort rescue []
  end

  def downloaded_pdf
    peon.list(subfolder: "#{run_id}/pdf")
  end

  def after_store
    models = [
      NmScCaseInfo, NmScCaseAdditionalInfo, NmScCaseParty, NmScCaseActivities, 
      NmScCasePdfsOnAws, NmScCaseRelationsActivityPdf, NmScCaseRelationsInfoPdf
    ]
    keeper.update_delete_status(*models)
    clear
    peon.throw_trash(2)
    keeper.finish
    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Store finished")
  end

  def clear
    FileUtils.mv("#{storehouse}store/#{@run_id}", "#{storehouse}trash/", force: true)
    File.delete(*Dir.glob("#{storehouse}trash/**/*.pdf"))
  end
end
