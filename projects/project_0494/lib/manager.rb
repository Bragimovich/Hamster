require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @s3 = AwsS3.new(bucket_key = :us_court)
    @already_inserted_pdfs = keeper.get_inserted_pdfs
  end
  
  def download(frequency)
    scraper = Scraper.new
    alread_inserted_url = keeper.get_inserted_records
    (frequency == 'weekly')? start_year = keeper.get_max_year :  start_year = 2016
    current_year = Date.today.year
    first_page = scraper.first_page_response
    location_value = first_page.headers['location']
    cookie_final, cookie_value_first = get_cookie(first_page)
    first_page = scraper.get_captcha_page(location_value, cookie_final)
    submit_page = scraper.get_submit_page(cookie_final, cookie_value_first)
    captcha_response = solve_captch(submit_page)
    solved_captcha_response = scraper.captcha_req(cookie_final, captcha_response)
    response1 = scraper.get_final_page(cookie_final)
    (start_year..current_year).each do |year|
      subfolder = "#{keeper.run_id}/#{year}"
      downloaded_files = peon.give_list(subfolder: subfolder)
      month = 1
      while month <= 12
        page = 0
        while true
          html = scraper.get_search_page(year, month, page, cookie_final)
          file_name = "#{month}_01_#{year}_page_#{page+1}"
          save_file(html.body, file_name, subfolder)
          links = parser.get_inner_links(html.body)
          links.each do |link|
            file_name = Digest::MD5.hexdigest link
            next if (downloaded_files.include? "#{file_name}.gz") || (alread_inserted_url.include? "https://macsnc.courts.state.mn.us#{link}")
            inner_page = scraper.get_inner_page(link, cookie_final)
            cookie = inner_page.headers['set-cookie']
            pdf_rows = parser.get_pdf_table_rows(inner_page.body)
            download_pdf(scraper, link, pdf_rows, cookie)
            save_file(inner_page.body, file_name, subfolder)
          end
          break if parser.check_next(html)
          page += 1
        end
        month += 1
      end
    end
  end

  def store
    alread_inserted_url = keeper.get_inserted_records
    year_folders = peon.list(subfolder: "#{keeper.run_id}").sort
    year_folders.each do |year|
      subfolder = "#{keeper.run_id}/#{year}"
      outer_pages = (peon.list(subfolder: subfolder).select{|s| s.include? 'page_'}).sort
      outer_pages.each do |outer_page|
        main_page = peon.give(subfolder: subfolder, file: outer_page)
        links = parser.get_inner_links(main_page)
        links.each_with_index do |link, index|
          next if alread_inserted_url.include? "https://macsnc.courts.state.mn.us#{link}"
          file_name = Digest::MD5.hexdigest link
          page = peon.give(subfolder: subfolder, file: file_name)
          case_info = parser.prepare_info_hash(main_page, index+2, keeper.run_id)
          party_array = parser.get_case_parties(page, keeper.run_id)
          activities_array = parser.get_case_activities(page, @already_inserted_pdfs, keeper.run_id)
          aws_array = parser.get_aws_hash(page, activities_array, keeper.run_id, @s3)
          relation_array = parser.get_activity_relations(activities_array, aws_array)
          keeper.save_case_info(case_info)
          keeper.save_case_party(party_array) if party_array.count > 0
          keeper.save_activities(activities_array) if activities_array.count > 0
          keeper.save_aws(aws_array, relation_array) if aws_array.count > 0
        end
      end
    end
  end

  private

  attr_accessor :parser, :keeper

  def download_pdf(scraper, link, pdf_rows, cookie)
    downloaded_files = peon.give_list(subfolder: "PDF") 
    pdf_rows.each do |row|
      values = parser.get_values(row)
      next if values.nil?
      next unless @already_inserted_pdfs.select{|a| a.include? "_#{values[1].to_s.squish}_"}.empty?
      name = downloaded_files.select {|f| f.start_with? values[1].squish rescue nil}[0]
      next if downloaded_files.include? name
      pdf_links = scraper.get_ajax_calls(values, link, cookie).body.split('"').select{|a| a.include? 'ctrack'}.map{|a| a.gsub('\\','')} unless values.nil?
      pdf_links = [] if ((values.nil?) || (pdf_links.empty?))
      pdf_links.each do |url|
        url = "https://macsnc.courts.state.mn.us#{url}"
        page = scraper.pdf_download(url)
        file_name = url.split('document=').last
        file_name = "#{values[1].to_i}_#{file_name}"
        save_file(page.body, file_name, "PDF")
      end
    end
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

  def solve_captch(submit_page)
    document = parser.get_parsed_document(submit_page.body)
    captcha_key = "3faa98b3c9e2254ebe22a3eb7caca3c2"
    captcha_client = TwoCaptcha.new("#{captcha_key}")
    data_site_key = parser.get_data_site_key(document)
    options = { googlekey: data_site_key, pageurl: 'https://macsnc.courts.state.mn.us/ctrack/public/caseCaptcha.do?doContinue'}
    captcha = captcha_client.decode_recaptcha_v2(options)
    captcha.text
  end

  def get_cookie(first_page)
    cookie_value = first_page.headers['set-cookie']
    cookie_value_first = cookie_value.split(";")[0]
    cookie_final = cookie_value_first + ";" + cookie_value.split(";")[3].split(',').last.strip
    [cookie_final, cookie_value_first]
  end
end
