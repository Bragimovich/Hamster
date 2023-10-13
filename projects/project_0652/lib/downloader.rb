module Downloader
  COURT_ID = 95
  def download_cases(c,start_date, end_date)
    record_count = nil
    return if search_downloaded?("#{c}#{start_date}#{end_date}")
    scraper.start_browser
    20.times do
      logger.debug "downloading files: last name #{c}, range [#{start_date},#{end_date}]"
      search_html = scraper.search_cases(c,start_date, end_date) 
      next if (search_html.nil? || search_html.empty?)
      case_links = parser.page(search_html).cases
      search_success = parser.search_success?
      record_count = parser.record_count
      logger.debug("search_success:  #{search_success}, record_count: #{record_count}")
      unless case_links.empty?
        dump_search_html(search_html,"#{c}#{start_date}#{end_date}") 
        case_links.each do |case_link|
          download_case(case_link)
        end
      end
      break unless case_links.empty?
      break if search_success
      sleep(2)
    end
    scraper.close_browser
    
    record_count
  end

  def download_documents
    cases_list = peon.give_list(subfolder: case_folder).sort
    cases_list.map do |case_digest|
      sub_folder = activity_folder(case_digest.gsub('.gz',''))
      activities_list = peon.give_list(subfolder: sub_folder).sort
      activities_list.map do |file|
        html = peon.give(file: file,subfolder: sub_folder)
        activities = parser.page(html).activities
        activities.map do |ac|
          pdf_name = file_name(scraper.absolute_url(ac[:activity_pdf]))
          case_detail = parser.page(peon.give(file: case_digest,subfolder: case_folder)).case_detail
          save_pdf_on_aws(pdf_name,ac[:activity_pdf],case_detail[:case_id])
        end
      end
    end
  end

  def move_pdfs_to_aws
    cases_list = peon.give_list(subfolder: case_folder).sort
    cases_list.map do |case_digest|
      sub_folder = activity_folder(case_digest.gsub('.gz',''))
      activities_list = peon.give_list(subfolder: sub_folder).sort
      activities_list.map do |file|
        html = peon.give(file: file,subfolder: sub_folder)
        activities = parser.page(html).activities
        activities.map do |ac|
          pdf_name = file_name(scraper.absolute_url(ac[:activity_pdf]))
          pdf_storage_path = "#{storehouse}store/#{pdf_folder}/#{pdf_name}.gz"
          if File.exists?(pdf_storage_path)
            logger.debug "#{pdf_storage_path}"
            logger.debug 'moving pdf'
            pdf = peon.give(file: pdf_name,subfolder: pdf_folder)
            if pdf
              case_detail = parser.page(peon.give(file: case_digest,subfolder: case_folder)).case_detail
              aws_link  = save_pdf_on_aws(pdf,pdf_name,ac[:activity_pdf],case_detail[:case_id])
              # delete file from server
              File.delete(pdf_storage_path)
            end
          end
        end
      end
    end
  end

  private

  def save_file(html, file, sub_folder)
    logger.debug(file.to_s)
    peon.put content: html, file: file.to_s, subfolder: sub_folder
  end

  def dump_case_html(d)
    logger.debug "dumping case detail "
    save_file(d[:html], file_name(d[:link]), case_folder) unless d[:html].nil?
  end

  def dump_activity_html(d)
    logger.debug "dumping activity detail"
    unless d[:html].nil? || d[:link].nil?
      save_file(d[:html], file_name(d[:link]), activity_folder(file_name(d[:case_link])))
    end
  end

  def file_name(link)
    Digest::MD5.hexdigest link
  end

  def case_folder
    "#{keeper.run_id}"
  end

  def search_folder
    "#{case_folder}/search"
  end

  def activity_folder(case_digest)
    "#{case_folder}/activity/#{case_digest}"
  end

  def pdf_folder
    "#{case_folder}/pdf"
  end

  def dump_search_html(html,character)
    logger.debug "dumping search #{file_name(character)}"
    save_file(html, file_name(character), search_folder) unless html.nil?
  end

  def save_pdf_on_aws(pdf_name,url,case_id)
    key = "us_courts/#{COURT_ID}/#{case_id}/#{pdf_name}.pdf"
    if(@s3.find_files_in_s3(key).empty?)
      pdf = scraper.download_pdf(url)
      logger.debug "uploading on aws"
      aws_link = @s3.put_file(pdf, key, metadata={ url: url })
    else
      logger.debug "file already exists on aws"
      aws_link = get_aws_link(case_id,pdf_name)
    end
    # aws_link = @s3.put_file(pdf, key, metadata={ url: url })
    logger.debug "#{aws_link}"
  end

  def get_aws_link(case_id,pdf_name)
    "https://court-cases-activities.s3.amazonaws.com/us_courts/#{COURT_ID}/#{case_id}/#{pdf_name}.pdf"
  end

  def attach_run_id!(hash)
    hash.merge!(touched_run_id: keeper.run_id,run_id: keeper.run_id)
  end

  def case_downloaded?(case_link)
    storage_path = "#{storehouse}store/#{case_folder}/#{file_name(case_link)}.gz"
    File.exists?(storage_path)
  end

  def activity_downloaded?(case_link,activity_link)
    storage_path = "#{storehouse}/store/#{activity_folder(file_name(case_link))}/#{file_name(activity_link)}.gz"
    File.exists?(storage_path)
  end

  def search_downloaded?(character)
    storage_path = "#{storehouse}/store/#{search_folder}/#{file_name(character)}.gz"
    File.exists?(storage_path)
  end

  def download_case(case_link)
    if case_downloaded?(case_link.to_s)
      # case_html = peon.give(file: file_name(case_link),subfolder: case_folder)
    else
      case_html = scraper.download_page(case_link) unless case_link.nil?
    end

    unless (case_html.nil? || case_html.empty?)
      dump_case_html({link: case_link,html: case_html}) 
      activity_link = parser.page(case_html).activity_link
      if activity_downloaded?(case_link,activity_link.to_s)
        # activity_html = peon.give(file: file_name(activity_link),subfolder: activity_folder(file_name(case_link)))
      else
        activity_html = scraper.download_page(activity_link) unless activity_link.nil?
      end

      unless (activity_html.nil? || activity_html.empty?)
        dump_activity_html({link: activity_link,html: activity_html,case_link: case_link})
      end
    end
  end

  def store_in_db(update_run_id)
    problematic_cases = []
    search_files = peon.give_list(subfolder: search_folder).sort
    search_files.map do |search_file|
      logger.debug "search file #{search_file}"
      search_html = peon.give(file: search_file,subfolder: search_folder)
      case_links = parser.page(search_html).cases
      logger.debug "cases count #{case_links.count}"
      case_links.map do |case_link|
        next unless case_downloaded?(case_link)
        logger.debug "processing file #{file_name(case_link)}"
        logger.debug "case_link #{case_link}"
        case_html = peon.give(file: file_name(case_link),subfolder: case_folder)
        case_detail = parser.page(case_html).case_detail
        
        if case_detail[:case_id].nil? || case_detail[:case_id].empty?
          logger.debug "no case file #{file_name(case_link)}"
          problematic_cases.push file_name(case_link)
          next
        end
        case_detail.merge!(data_source_url: scraper.absolute_url(case_link),court_id: COURT_ID)
        attach_run_id!(case_detail)
        case_parties = parser.parties
        case_parties.each do |party|
          party.merge!(data_source_url: scraper.absolute_url(case_link),court_id: COURT_ID,case_id: case_detail[:case_id])
          attach_run_id!(party)
        end
        activity_link = parser.activity_link
        unless activity_link
          logger.warn "activity_link not found"
          next
        end
        next unless activity_downloaded?(case_link,activity_link)
        
        activity_html = peon.give(file: file_name(activity_link),subfolder: activity_folder(file_name(case_link)))
        pdfs_on_aws =[]
        activities = parser.page(activity_html).activities
        activities.each do |activity|
          activity.merge!(
            data_source_url: scraper.absolute_url(activity_link),
            activity_pdf: scraper.absolute_url(activity[:activity_pdf]),
            court_id: COURT_ID,
            case_id: case_detail[:case_id]
          )
          attach_run_id!(activity)
          # # add to db
          pdf_on_aws_relation = {}
          pdf_on_aws = {
            court_id: COURT_ID,
            case_id:  case_detail[:case_id],
            source_type: 'activities',
            aws_link: get_aws_link(case_detail[:case_id],file_name(activity[:activity_pdf])),
            source_link: scraper.absolute_url(activity[:activity_pdf]),
            data_source_url: scraper.absolute_url(activity_link)
          }
          pdf_on_aws[:md5_hash] = parser.create_md5_hash(pdf_on_aws)
          attach_run_id!(pdf_on_aws)
          pdf_on_aws_relation.merge!(case_activities_md5: activity[:md5_hash],case_pdf_on_aws_md5: pdf_on_aws[:md5_hash])
          pdf_on_aws_relation[:md5_hash] = parser.create_md5_hash(pdf_on_aws_relation)
          attach_run_id!(pdf_on_aws_relation)

          activity.merge!(pdf_on_aws: pdf_on_aws,pdf_on_aws_relation: pdf_on_aws_relation)

        end
        logger.debug "storing case_id #{case_detail[:case_id]}"
        keeper.store({
          case: case_detail,
            parties: case_parties,
            activities: activities
          })
      end
    end
    keeper.finish(update_run_id)
    problematic_cases
  end
end
