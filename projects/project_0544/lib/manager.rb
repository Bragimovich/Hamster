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
    scraper = Scraper.new
    already_inserted_links, unparsed_pdf_links = resolved_links
    array = get_court_type
    array.each do |court_type|
      (2016..Date.today.year).each do |year|
        main_page = scraper.main_page(court_type, year)
        main_page_doc = parser.main_page(main_page.body)
        save_file(main_page.body, "#{year}", "#{keeper.run_id}/#{court_type}")
        links = parser.pdf_links(main_page_doc)
        links.each do |link|
          link = "https://legacy.utcourts.gov/opinions/#{court_type}/" + link.gsub(" ","%20")
          next if ((already_inserted_links.include? link) || (unparsed_pdf_links.include? link))
          file_name = Digest::MD5.hexdigest link
          pdf_response = scraper.pdf_response(link)
          save_pdf(pdf_response.body, file_name, year, court_type)
          save_file(pdf_response.body, "#{file_name}", "#{keeper.run_id}/#{court_type}/pdfs/#{year}")
        end
      end
    end
  end

  def store
    array = get_court_type
    already_inserted_links, unparsed_pdf_links = resolved_links
    array.each_with_index do |court_type,ind|
      (2016..Date.today.year).each do |year|
        main_page = peon.give(subfolder: "#{keeper.run_id}/#{court_type}", file: "#{year}")
        main_page_doc = parser.main_page(main_page)
        links = parser.pdf_links(main_page_doc)
        links.each do |link|
          link = "https://legacy.utcourts.gov/opinions/#{court_type}/" + link.gsub(" ","%20")
          next if ((already_inserted_links.include? link) || (unparsed_pdf_links.include? link))
          file_name = Digest::MD5.hexdigest link
          page = peon.give(file: file_name, subfolder: "#{keeper.run_id}/#{court_type}/pdfs/#{year}")
          file_path = "#{storehouse}store/#{keeper.run_id}/#{court_type}/pdfs/#{year}/#{file_name}.pdf"
          data_lines = parser.get_info(file_path, link)
          next if ((data_lines.include? "▯") || (data_lines.empty?) || (data_lines[5].nil?))
          ((ind==0)? data_tables(data_lines,link,"480",page) : data_tables(data_lines,link,"345",page))
        end
      end
    end
  end 

  def activity_page
    scraper = Scraper.new
    two_captcha = TwoCaptcha.new(Storage.new.two_captcha['general'], timeout: 200, polling: 10)
    courts = find_court
    courts.each do |court_id|
      main_page = scraper.pdf_response("https://apps.utcourts.gov/CourtsPublicWEB/LoginServlet")
      cookie = main_page["set-cookie"]
      main_page = parser.main_page(main_page.body)
      response = scraper.get_activity_page(cookie, main_page, two_captcha)
      page = parser.main_page(response.body)
      action_url = parser.fetch_action_url(page)
      court_type = find_court_type(court_id)
      case_ids = keeper.court_ids(court_id).map{|e| e[0].split("-").first}
      case_ids.each do |case_id|
        puts "Processing ---> #{case_id}"
        result = scraper.get_final_page(action_url, case_id, court_type, cookie)
        save_file(result.body, "#{case_id}", "#{keeper.run_id}/#{court_type}")
      end
    end
  end

  def activity_page_store
    courts = find_court
    courts.each do |court_id|
      court_type = find_court_type(court_id)
      cases = peon.give_list(subfolder: "#{keeper.run_id}/#{court_type}")
      case_ids = keeper.court_ids(court_id).map{|e| e.split("-").first}
      cases.each do |case_num|
        file = peon.give(file: case_num, subfolder: "#{keeper.run_id}/#{court_type}")
        pp = parser.main_page(file)
        link = case_ids.select{ |a| a[0].split("-").first == case_num.split(".").first}.map{ |a| a[1]}[0]
        data_array = parser.case_activities(court_id, pp, keeper.run_id, link)
        keeper.insert_case_info("CaseActivity", data_array)
      end
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser

  def resolved_links
    [keeper.already_inserted_links, keeper.unparsed_pdf_links]
  end

  def get_court_type
    ["appopin", "supopin"]
  end

  def find_court
    appellate = "480"
    supreme = "345"
    [appellate, supreme]
  end

  def find_court_type(court_id)
    court_id == "480" ? "A" : "S"
  end

  def data_tables(data_lines,link, court_id,page)
    info_array, add_info_array, party_array, array_aws, relations_array  = parser.party_info(data_lines,link,keeper.run_id,court_id,page, @s3)
    keeper.insert_case_info("CaseInfo",info_array.flatten)
    keeper.insert_case_info("CaseAddInfo",add_info_array.flatten)
    keeper.insert_case_info("CaseParty",party_array.flatten)
    keeper.insert_case_info("CaseAwsFiles",array_aws.flatten)
    keeper.insert_case_info("CasePdfRelations",relations_array.flatten)
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

  def save_pdf(pdf, file_name, year, court_type)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}/#{court_type}/pdfs/#{year}"
    pdf_storage_path = "#{storehouse}store/#{keeper.run_id}/#{court_type}/pdfs/#{year}/#{file_name}.pdf"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(pdf)
    end
  end
end
