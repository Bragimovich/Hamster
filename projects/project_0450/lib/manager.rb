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
  
  def store_case_numbers
    @scraper = Scraper.new
    @full_last_name = keeper.fetch_last_name
    ('A'..'Z').each do |letter|
      data_array = []
      searched_page,searched_page_doc,cookie,token = main_page(letter)
      next_page = keeper.get_last_page(letter)
      (next_page.nil?)?  next_page = 1 : next_page
      value = (fetch_info(searched_page, cookie, token, 1,@full_last_name))
      next unless (insertion(value, searched_page_doc, data_array, next_page, letter))
      page = 1
      total = parser.get_total_records(searched_page_doc)
      while true
        break_counter = 0
        begin
          searched_page,searched_page_doc,cookie,token = main_page(letter)
          token = parser.get_token(searched_page_doc, "caseNameForm")
          searched_page = @scraper.get_next_page(token, letter, cookie, page, next_page, total)
          searched_page_doc = parser.get_parsed_object(searched_page.body)
          value = (fetch_info(searched_page, cookie, token, page+1, @full_last_name))
          next if (value.nil?)
          break unless (insertion(value, searched_page_doc, data_array, page, letter))
          page = next_page
          next_page = next_page + 1
          data_array = []
        rescue Exception => e
          break_counter += 1
          raise e.full_message if break_counter > 4
          Hamster.report(to: 'Tauseeq Tufail', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
          next
        end
      end
    end
  end

  def download(retries = 10)
    begin
      already_downloaded = peon.list(subfolder:"/#{keeper.run_id}") rescue []
      case_numbers = keeper.fetch_case_numbers
      case_numbers.each do |case_number|
        file_name = case_number.split.join("_")
        next if ((already_downloaded.include? file_name) || (case_number.include? "No Case"))
        subfolder = "/#{keeper.run_id}/#{file_name}"
        retarget_main(case_number,file_name,subfolder)
      end
    rescue Exception => e
      if retries < 1
        p e.full_message
        Hamster.report(to: 'Tauseeq Tufail', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
      download(retries-1)
    end
  end

  def store
    cases = peon.list(subfolder:"/#{keeper.run_id}")
    already_inserted_case = keeper.fetch_case_id
    cases.each do |case_folder|
      next if already_inserted_case.include? (case_folder.gsub("_"," "))
      activities_array = []
      files = peon.give_list(subfolder:"/#{keeper.run_id}/#{case_folder}").sort
      page = peon.give(file: files[0], subfolder: "/#{keeper.run_id}/#{case_folder}")
      info_array = parser.prepare_info_hash(page, keeper.run_id)
      next if info_array == {}
      party_info = keeper.fetch_party_info(info_array[:case_id])
      party_array = parser.get_party_info(party_info, keeper.run_id)
      aws_hash = parser.get_aws_uploads(page, @s3, keeper.run_id)
      files.each do |file|
        file = peon.give(file: file, subfolder: "/#{keeper.run_id}/#{case_folder}")
        activities_array.concat(parser.get_case_activities(file, keeper.run_id))
      end
      relations_hash = get_relations_pdf(info_array[:md5_hash], aws_hash[:md5_hash], keeper.run_id)
      keeper.insert_case_info("CaseInfo",info_array)
      keeper.insert_case_info("CaseParty",party_array) unless party_array.empty?
      keeper.insert_case_info("CaseActivities",activities_array) unless activities_array.empty?
      keeper.insert_case_info("CaseAwsFiles",aws_hash)
      keeper.insert_case_info("CasePdfRelations",relations_hash)
    end
  end

  def store_party
    case_numbers_with_different_count = keeper.fetch_change
    case_numbers_with_different_count.each do |case_num|
      party_info = keeper.fetch_party_info(case_num)
      party_array = parser.get_party_info(party_info, keeper.run_id)
      keeper.insert_case_info("CaseParty",party_array) unless party_array.empty?
    end
  end

  private

  attr_accessor :parser, :keeper

  def retarget_main(case_number,file_name,subfolder)
    scraper = Scraper.new
    html = scraper.get_main_page
    main_page_doc = parser.get_parsed_object(html.body)
    cookie = html.headers['set-cookie']
    token = parser.get_token(main_page_doc, "caseNumberForm")
    page = scraper.get_inner_page(token, cookie, case_number)
    page_body = parser.get_parsed_object(page.body)
    retarget_main(case_number,file_name,subfolder) unless (page_body.text.include? case_number)
    save_file(page.body, "#{file_name}_page_1", subfolder)
    activities_page = 0
    total_pages = parser.get_activities_pages(page.body).to_i
    page_body = parser.get_next_page_body(page.body, activities_page+1)
    while true
      break if total_pages == activities_page
      next_page = scraper.get_next_activity(cookie, page_body)
      page_body = parser.get_parsed_object(next_page.body)
      retarget_main(case_number,file_name,subfolder) unless (page_body.text.include? case_number)
      save_file(next_page.body, "#{file_name}_page_#{activities_page+2}", subfolder)
      activities_page += 1
      page_body = parser.get_next_page_body(next_page.body, activities_page+1)
    end
  end

  def main_page(letter)
    html = @scraper.get_main_page
    cookie = html.headers['set-cookie']
    main_page_doc = parser.get_parsed_object(html.body)
    token = parser.get_token(main_page_doc, "caseNumberForm")
    searched_page = @scraper.get_results_page(token, letter, cookie)
    searched_page_doc = parser.get_parsed_object(searched_page.body)
    [searched_page,searched_page_doc,cookie,token]
  end

  def insertion(value, searched_page_doc, data_array, page, letter)
    data_array.concat(value) unless (value.nil?)
    keeper.insert_case_info("CaseNumbers",data_array.flatten)
    parser.check_next(searched_page_doc).include? 'Next'
  end

  def get_relations_pdf(case_info_md5, aws_pdf_md5, run_id)
    {
      run_id: run_id,
      case_info_md5: case_info_md5,
      case_pdf_on_aws_md5: aws_pdf_md5
    }
  end

  def fetch_info(html, cookie, token, page, full_last_name)
    main_page_doc = parser.get_parsed_object(html.body)
    table_rows = parser.get_record_rows(main_page_doc,cookie,token,page)
    return if table_rows.nil?
    data_array = []
    table_rows.each do |row|
      javascript_parameters = parser.get_javascript(row)
      next if full_last_name.include? javascript_parameters[3].squish.gsub("'","")
      cases_page = @scraper.get_cases_page(cookie, token, javascript_parameters)
      data_array.concat(parser.get_case_info(cases_page.body, javascript_parameters, page))
    end
    data_array
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end
end
