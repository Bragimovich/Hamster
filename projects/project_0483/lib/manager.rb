require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
    @s3 = AwsS3.new(bucket_key = :us_court)
    @already_inserted_links = keeper.fetch_already_inserted_links
  end

  def run_script
    (keeper.download_status == "finish") ? store : download
  end

  def download
    downloaded_cases = peon.list(subfolder: "#{keeper.run_id}") rescue []
    start_year = 2016
    end_year   = Date.today.year
    courts = ['SC', 'COA']
    courts.each do |court|
      (start_year..end_year).each do |year|
        empty_records_count = 0
        (0..999).each do |case_num|
          break if empty_records_count > 100

          case_num = make_number(case_num)
          case_folder = "#{year}_#{case_num}_#{court}"
          next if downloaded_cases.include? case_folder
          url   = "https://pch.tncourts.gov/SearchResults.aspx?k=#{year}-#{case_num}%25-#{court}&Number=True"
          html = scraper.fetch_outer_page(url)
          search_text = "#{year}-#{case_num}%25-#{court}"

          if html.body.length < 300
            empty_records_count +=1
            next
          end

          empty_records_count = 0
          ids, total_pages = parser.fetch_case_ids(html.body)
          subfolder = "#{keeper.run_id}/#{year}_#{case_num}_#{court}"
          eventvalidation, viewstate, viewstategenerator = parser.post_request_parameters(html.body)

          for page_num in 2..total_pages
            response = scraper.next_page_request(url, eventvalidation, viewstate, viewstategenerator, 'btnAdvanceSearch', page_num, total_pages, search_text)
            additional_ids, total_pages = parser.fetch_case_ids(response.body)
            ids = ids + additional_ids
          end

          downloaded_files = peon.give_list(subfolder: subfolder)

          ids.each do |id|
            url = "https://pch.tncourts.gov/CaseDetails.aspx?id=#{id}&Number=True"
            next if @already_inserted_links.include? url

            file_name_detail = Digest::MD5.hexdigest url
            next if downloaded_files.include? "#{file_name_detail}.gz"

            html = scraper.request_next_page(url)
            next if html.body.length < 300

            updated_html = download_pdfs(html.body, subfolder, url)
            save_file(updated_html, file_name_detail, subfolder)
          end
        end
      end
    end
    keeper.finish_download
    store if  (keeper.download_status == "finish")
  end

  def store
    error_count  = 0
    year_folders = peon.list(subfolder: "#{keeper.run_id}").sort
    year_folders.each do |subfolder|
      subfolder = "#{keeper.run_id}/#{subfolder}"
      court_id  = (subfolder.include? 'SC') ? 41 : 42
      cases     = (peon.list(subfolder: subfolder))

      cases.each do |case_name|
        begin
          body = peon.give(file:case_name, subfolder: subfolder)
          url  = parser.fetch_url(body)
          next if @already_inserted_links.include? url

          info_hash, party_array, actvities_array, additional_info_array = parser.fetch_page_info(body, court_id, keeper.run_id)
          parties_md5 = party_array.map{|e| e[:md5_hash]}
          activities_md5 = actvities_array.map{|e| e[:md5_hash]}
          additional_info_md5 = additional_info_array.map{|e| e[:md5_hash]}
          next if info_hash.nil?

          aws_pdf_array, activity_relations_array = [], []
          info_aws_data_hash       = parser.activities_pdfs_on_aws(court_id, info_hash[:case_id], 'info.html', info_hash[:data_source_url], 'info', keeper.run_id)
          info_aws_data_hash       = aws_upload(info_aws_data_hash, body, 'info')
          pdf_md5                  = info_aws_data_hash[:md5_hash]
          info_md5                 = info_hash[:md5_hash]
          data_relations_info_hash = parser.case_relations_info_pdf(pdf_md5, info_md5, court_id)
          aws_pdf_array << info_aws_data_hash
          pdf_links_array = parser.find_pdf_names(body)

          pdf_links_array.each do |pdf_link|
            subfolder_pdf                = info_hash[:data_source_url].split('=')[-2].split("&").first
            pdf_response                 = peon.give(file:pdf_link[:name], subfolder: "pdfs/#{subfolder_pdf}")
            pdf_data_hash                = parser.activities_pdfs_on_aws(court_id, info_hash[:case_id], pdf_link[:name], info_hash[:data_source_url], 'activity', keeper.run_id)
            pdf_md5                      = pdf_data_hash[:md5_hash]
            activity_number              = pdf_link[:key].split('ctrl')[1].split('%')[0]
            activity_md5                 = actvities_array[activity_number.to_i][:md5_hash]
            data_relations_activity_hash = parser.case_relations_activity_pdf(pdf_md5, activity_md5, court_id)
            pdf_data_hash                = aws_upload(pdf_data_hash, pdf_response, 'activity')
            aws_pdf_array                << pdf_data_hash
            activity_relations_array     << data_relations_activity_hash
          end
          aws_pdf_md5_hash = aws_pdf_array.map{|e| e[:md5_hash]}
          keeper.touched_run_id_process(info_hash[:md5_hash], parties_md5, activities_md5, additional_info_md5, aws_pdf_md5_hash)
          keeper.save_record(info_hash, party_array, actvities_array, additional_info_array, aws_pdf_array, activity_relations_array, data_relations_info_hash)
        rescue Exception => e
          error_count +=1
          raise e.full_message if error_count > 10
          p e.full_message
          Hamster.report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
        end
      end
    end
    if (keeper.download_status == "finish")
      keeper.mark_deleted
      keeper.finish
    end
  end

  private

  attr_accessor :keeper, :parser, :scraper

  def download_pdfs(html, subfolder, url)
    alread_downloaded_pdfs_count = keeper.alread_downloaded_pdfs_count(url)
    pdfs_names_array = []
    pdf_links_array  = parser.fetch_pdf_links(html, alread_downloaded_pdfs_count)
    eventvalidation, viewstate, viewstategenerator = parser.post_request_parameters(html)
    
    pdf_links_array.each do |link_info|
      folder_name  = url.split('=')[-2].split('&').first
      pdf_response = scraper.pdf_request(eventvalidation, viewstate, viewstategenerator, link_info, url)
      next if pdf_response.body.length < 300

      name = pdf_response.headers["content-disposition"].split("\;")[1].split('=')[1] rescue nil
      next if name.nil?

      info_hash        = {}
      info_hash[:key]  = link_info
      info_hash[:name] = name
      pdfs_names_array << info_hash
      save_file(pdf_response.body, info_hash[:name], "pdfs/#{folder_name}")
    end
    parser.update_html(html, pdfs_names_array)
  end

  def aws_upload(pdf_hash, pdf, type)
    type == 'activity' ? pdf_hash[:aws_link] = upload_file_to_aws(pdf_hash, pdf) : pdf_hash[:aws_html_link] = upload_file_to_aws(pdf_hash, pdf)
    pdf_hash
  end

  def upload_file_to_aws(aws_atemp, pdf)
    aws_url = 'https://court-cases-activities.s3.amazonaws.com/'
    if aws_atemp[:aws_link].nil?
      key = aws_atemp[:aws_html_link]
    else
      return aws_url + aws_atemp[:aws_link] unless @s3.find_files_in_s3(aws_atemp[:aws_link]).empty?

      key = aws_atemp[:aws_link]
    end
    @s3.put_file(pdf, key, metadata={})
  end

  def make_number(number)
    number.to_s.rjust(3, '0')
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end
end
