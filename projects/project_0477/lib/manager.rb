# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'
class Manager < Hamster::Scraper

  SUB_FOLDER = "UsCourtsExpansion"
  BASE_URL = "https://www.courts.wa.gov"
  BASE_URL_FOR_COURT_ACTIVITES_PAGE = "https://dw.courts.wa.gov/index.cfm"

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @s3 = AwsS3.new(bucket_key = :us_court)
    @two_captcha = Hamster::CaptchaAdapter.new(:two_captcha_com, timeout:200, polling:10)
    p @two_captcha.balance
    @dir_path = @_storehouse_ + 'filename_link.csv'
    @pdf_path = @_storehouse_ + 'hash_to_pdf_link.csv'
    @activites_got_with_captcha = @_storehouse_ + 'activites_to_link.csv'
    @files_to_link = {}
    @pdfmd5_to_link = {} 
    @outerfilename_to_link = {}
    @activites_to_file_path = {}
    @downloaded_file_names = peon.give_list(subfolder: SUB_FOLDER)
    
    if File.file?(@dir_path)
      table = CSV.parse(File.read(@dir_path), headers: false)
      table.map{ |x| @files_to_link[x[0]] = x[1] }
      outer_pages = table.select{|x| x[0].include?("outer_page_")}
      outer_pages.map{|x| @outerfilename_to_link[x[0]]= x[1]}
      table1 = CSV.parse(File.read(@pdf_path), headers: false)
      table1.map{ |x| @pdfmd5_to_link[x[0]] = x[1] }
    end
  
    if File.file?(@activites_got_with_captcha)
      activites = CSV.parse(File.read(@activites_got_with_captcha), headers: false)
      activites.map{ |x| @activites_to_file_path[x[0]] = x[1] }
    end
  end

  def download
    page_response , status = @scraper.download_page(BASE_URL+ "/opinions/index.cfm?fa=opinions.displayAll")
    return if status != 200
    all_links = @parser.get_all_links(page_response.body)
    
    all_links.each do |link|
      hash = download_outer_page(link)
      next if hash[:status] != 200
      all_pdf_links = hash[:all_pdf_links]
      
      all_pdf_links.each do |pdf_div|
        inner_hash = download_inner_page_data(pdf_div)
        download_case_activites(inner_hash[:inner_file_name])
      end
      
      # save outer page
      save_file(hash[:outer_page_response], hash[:outer_file_name])
      save_csv(hash[:outer_file_name], hash[:outer_link])
    end
  end

  def store
    process_each_file
    @keeper.finish
  end

  private

  def download_outer_page(link)
    outer_link = BASE_URL + link['href']
    outer_page_response , status = @scraper.download_page(outer_link)
    outer_file_name = "outer_page_" + Digest::MD5.hexdigest(outer_link) + '.gz'
    case_year = outer_link.match(/\d{4}/)&.to_s&.to_i
    all_pdf_links = @parser.parse_rows(outer_page_response.body)
    {
      status: status,
      case_year: case_year,
      outer_link: outer_link,
      outer_file_name: outer_file_name,
      outer_page_response: outer_page_response,
      all_pdf_links: all_pdf_links 
    }
  end

  def download_case_activites(inner_file_name)
    if @two_captcha.balance > 0
      file_content = peon.give(subfolder: SUB_FOLDER, file: inner_file_name)
      hash = @parser.parse_inner_page(file_content,"")
      court_id = hash[:case_info]['court_id']
      case_id = hash[:case_info]['case_id'].gsub(',','')
      if court_id&.present? and case_id&.present?
        download_and_save_case_activites(court_id, case_id)
      end
    end
  end

  def download_inner_page_data(pdf_div)
    # getting links from divs
    inner_link, pdf_link = @parser.get_links(pdf_div)
    inner_file_name = Digest::MD5.hexdigest(inner_link) + '.gz'
    
    if @files_to_link[inner_file_name].present?
      puts "Skipped: #{inner_link}"
    else
      # save link
      inner_page_response , status = @scraper.download_page(inner_link)
      save_file(inner_page_response, inner_file_name) if status == 200
      save_csv(inner_file_name, inner_link) if status == 200
    end
    
    if not @keeper.pdf_link_exits_in_db?(pdf_link)
      # save pdf
      pdf_response, status = @scraper.download_page(pdf_link)
      pdf_link_md5_hash = Digest::MD5.hexdigest(pdf_link) + '.pdf'
      
      save_pdf(pdf_response&.body,pdf_link_md5_hash) if status == 200
      save_csv_pdf_source(pdf_link_md5_hash ,pdf_link) if status == 200
    else
      puts "Skipped: #{pdf_link}"
    end
    {inner_file_name: inner_file_name}
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end

  def save_csv(file_name, link)
    unless @files_to_link.key?(link)
      rows = [[file_name , link]]
      File.open(@dir_path, 'a') { |file| file.write(rows.map(&:to_csv).join) }
    end
  end

  def save_csv_pdf_source(pdf_md5_hash, link)
    unless @pdfmd5_to_link.key?(pdf_md5_hash)
      rows = [[pdf_md5_hash , link]]
      File.open(@pdf_path, 'a') { |file| file.write(rows.map(&:to_csv).join) }
    end
  end

  def save_pdf(pdf , file_name)
    pdf_storage_path = @_storehouse_ + "store/#{file_name}"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(pdf)
    end
  end

  def save_activity_csv(file_name, file_path)
    unless @activites_to_file_path.key?(file_name)
      rows = [[file_name , file_path]]
      File.open(@activites_got_with_captcha, 'a') { |file| file.write(rows.map(&:to_csv).join) }
    end
  end

  def process_each_file
    @outerfilename_to_link.each do |file_name|
      file_content = peon.give(subfolder: SUB_FOLDER,file: file_name[0])
      puts "Parsing outer_page #{file_name[1]}".yellow
      case_year = file_name[1].match(/\d{4}/)&.to_s&.to_i

      all_pdf_links = @parser.parse_rows(file_content)
      all_pdf_links.each do |pdf_div|
        inner_link, pdf_link = @parser.get_links(pdf_div)

        # parse inner file
        inner_file_name = Digest::MD5.hexdigest(inner_link) + '.gz'
        file_content = peon.give(subfolder: SUB_FOLDER, file: inner_file_name)
        data_source_url = @files_to_link[inner_file_name]

        hash = @parser.parse_inner_page(file_content, data_source_url)
        
        court_id = hash[:case_info]['court_id']
        case_id = hash[:case_info]['case_id']
        
        if court_id.present?
          # store inner file results in db
          @keeper.store_parties(hash[:list_of_parties])
          @keeper.store_additional_info(hash[:additional_info])

          # get case file date and activites
          captcha_response_file_name = Digest::MD5.hexdigest(court_and_caseid_file_name(court_id, case_id.gsub(',',''))) + '.gz'
          if @downloaded_file_names.include?(captcha_response_file_name)
            file_content = peon.give(subfolder: SUB_FOLDER, file: captcha_response_file_name)
            case_file_date = @parser.get_case_filed_date(file_content)
            hash[:case_info]['case_filed_date'] = case_file_date
        
            # store_parties
            list_of_hashes = @parser.parse_parties_from_captcha_page(file_content)
            list_of_hashes.each do|hash|
              hash['court_id'] = court_id
              hash['case_id'] = case_id
              hash['is_lawyer'] = '0'
              hash['data_source_url'] = BASE_URL_FOR_COURT_ACTIVITES_PAGE + "?fa=home.casesearch&terms=accept&flashform=0&tab=clj"
            end
            @keeper.store_parties(list_of_hashes)
          end
          # adding case year
          hash[:case_info][:year] = case_year
          @keeper.store_case_info(hash[:case_info])
          store_pdf_in_db(hash[:case_info], pdf_link, court_id, case_id)
          store_activites_in_db(court_id, case_id)
        end
      end
    end
  end


  def store_pdf_in_db(case_info, pdf_link, court_id, case_id)
    # check if pdf exits already on db/aws
    if not @keeper.pdf_link_exits_in_db?(pdf_link)
      aws_public_link = store_pdf_to_aws(pdf_link,court_id ,case_id)
      if aws_public_link&.present?
        hash = aws_link_hash(aws_public_link, pdf_link, court_id, case_id)
        # store results in db
        @keeper.store_aws_link(hash)
        # store case_info and pdf_on_aws relation
        case_info_relation_hash = {}
        case_info_relation_hash['case_info_md5'] = Digest::MD5.hexdigest(case_info.to_s)
        case_info_relation_hash['case_pdf_on_aws_md5'] = Digest::MD5.hexdigest(hash.to_s)
        @keeper.store_case_relations_info_pdf(case_info_relation_hash)
      end
    else
      # if pdf is in db (update touched_run_id)
      @keeper.update_touched_run_id_of_pdf_on_aws(pdf_link)
      # update relation of case_info and pdf
      @keeper.update_touched_run_id_of_case_info_relation_to_pdf(pdf_link)
    end
  end

  def store_pdf_to_aws(pdf_link,court_id,case_id)
    pdf_link_md5_hash = Digest::MD5.hexdigest(pdf_link) + '.pdf'
    pdf_storage_path = @_storehouse_ + "store/#{pdf_link_md5_hash}"
    key = "us_courts_expansion_#{court_id}_#{case_id}_#{pdf_link_md5_hash}"
    aws_link = nil
    if @s3.find_files_in_s3(key).empty?
      if File.file?(pdf_storage_path)
        aws_link = @s3.put_file(File.open(pdf_storage_path), key , metadata={ url: pdf_link})
      end
    else
      aws_link = 'https://court-cases-activities.s3.amazonaws.com/' + key
    end
    aws_link
  end

  def store_activites_in_db(court_id, case_id)
    activities_file_name = court_and_caseid_file_name(court_id, case_id) + '.gz'
    data_source_url = @activites_to_file_path[activities_file_name]
    if @downloaded_file_names.include?(activities_file_name)
      activites_file_content = peon.give(subfolder: SUB_FOLDER, file: activities_file_name)
      if activites_file_content.present?
        str_array = @parser.parse_activites(activites_file_content)
        hashes_of_activites = @parser.parse_activites_text(str_array)
        @list_of_activites = @parser.activites_helper(hashes_of_activites, court_id, case_id, data_source_url)
        @keeper.store_activites(@list_of_activites)
      end
    end
  end

  def handle_captcha_in_browser
    options = {
      pageurl: BASE_URL_FOR_COURT_ACTIVITES_PAGE + "?fa=home.casesearch&terms=accept&flashform=0&tab=clj",
      googlekey: '6LdfirwaAAAAAJXTslce1jzWGKow3FUsNUTm3jDt'
    }
    decoded_captcha = @two_captcha.decode_recaptcha_v2!(options)
    decoded_captcha.text
  end

  def download_and_save_case_activites(court_id, case_id)
    
    activities_file_name = court_and_caseid_file_name(court_id, case_id) + '.gz'

    if @activites_to_file_path.key?(activities_file_name)
      puts "Skipped:#{activities_file_name}"
    else
      begin
        recaptcha_response = handle_captcha_in_browser
        url = BASE_URL_FOR_COURT_ACTIVITES_PAGE + "?fa=home.caselist&amp;init=&amp;rtlist=case"
        court_name_for_form = @parser.get_court_name_by_id(court_id.to_i)

        if court_id.to_i == 482
          crt_itl_nu_appellate = "A01"
        elsif court_id.to_i == 483
          crt_itl_nu_appellate = "A02"
        elsif court_id.to_i == 484
          crt_itl_nu_appellate = "A03"
        elsif court_id.to_i == 348
          crt_itl_nu_appellate = "A08"
        end
        
        form_data = "selectedCourtName=#{court_name_for_form}&pageSize=10&pageIndex=1&saveHistory=1&courtType=C&searchType=2&CRT_ITL_NU_superior=S01&TYP_CD_Superior=CV&CRT_ITL_NU_appellate=#{crt_itl_nu_appellate}&TYP_CD_Appellate=&CRT_ITL_NU_district=ABM&TYP_CD_District=CV&fil_dt_to=08-06-2023&fil_dt_from=01%2F01%2F2022&firstName=&lastName=&Name_bus=&caseNumber=#{case_id}&g-recaptcha-response=#{recaptcha_response}"
        
        response ,status = @scraper.download_page_with_post_request(url,form_data)
        captcha_response_file_name = Digest::MD5.hexdigest(court_and_caseid_file_name(court_id,case_id)) + '.gz'

        save_file(response , captcha_response_file_name)        
        activites_links = @parser.parse_form_results_page(response.body)
        links = activites_links.map{ |x| @parser.get_link_from_page_result_divs(x) }
        
        if links.length != 0
          activites_url = BASE_URL_FOR_COURT_ACTIVITES_PAGE + links.first
          cookie = response.headers["set-cookie"]
          activites_response ,status = @scraper.download_Page(activites_url ,cookie)
          # saving file and its mapping
          save_file(activites_response,activities_file_name) if status == 200
          save_activity_csv(activities_file_name ,activites_url)
        else
          save_activity_csv(activities_file_name ,"Not Found")
        end
      rescue TwoCaptcha::Timeout => e
        save_activity_csv(activities_file_name ,"Time out")
        puts e
      end
    end
  end

  def aws_link_hash(aws_link, pdf_link, court_id, case_id)
    {
      court_id: court_id,
      case_id: case_id,
      source_link: pdf_link,
      aws_link: aws_link,
      source_type: "info",
    }
  end

  def court_and_caseid_file_name(court_id, case_id)
    court_id.to_s + '___' + case_id.to_s
  end
end
  