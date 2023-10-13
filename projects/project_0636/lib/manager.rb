# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  attr_reader :keeper, :run_id, :pdf_path 
  
  FRANK_RAO_ID  = 'U04MHBRVB6F'
  BASE_URL      = "https://www.lasc.org"
  DOCKET_BASE_URL = "http://www.lasc.org/docket/dockets"
  COURT_ID      = 319
  LOWER_COURT_ID = {
    432 => ['1st', 'first'],
    433 => ['2nd', 'second'],
    434 => ['3rd', 'third'],
    435 => ['4th', 'fourth'],
    436 => ['5th', 'fifth']
  }

  def initialize(**params)
    super
    @s3                     = AwsS3.new(bucket_key = :us_court)
    @keeper                 = Keeper.new
    @run_id                 = @keeper.run_id
    
  end

  def download_dockets
    scraper = Scraper.new
    dockets_page = scraper.get_dockets_page
    
    parser = Parser.new(dockets_page.body)
    docket_pdf_urls = parser.get_docket_links
    b_start = false
    docket_pdf_urls.each do |docket_pdf_url|
      
      # if docket_pdf_url.include?('/February 202003.pdf')
      #   b_start = true
      # end
      # next unless b_start
      begin
        scraper.download_docket_pdf(docket_pdf_url)
      rescue Exception => e
        Hamster.report(to: FRANK_RAO_ID, message:  "#{e.full_message}\n", use: :slack)
        Hamster.report(to: FRANK_RAO_ID, message:  "Failed: #{docket_pdf_url}", use: :slack)
      end
    end
  end

  def download_dockets_for(year)
    Hamster.report(to: FRANK_RAO_ID, message: "project-#{Hamster::project_number}. download_dockets_for(#{year}) started.", use: :slack)
    scraper = Scraper.new
    dockets_page = scraper.get_dockets_page
    
    parser = Parser.new(dockets_page.body)
    docket_pdf_urls = parser.get_docket_links
    b_start = false
    docket_pdf_urls.each do |docket_pdf_url|
      next unless docket_pdf_url.include?(year.to_s)

      begin
        scraper.download_docket_pdf(docket_pdf_url)
      rescue Exception => e
        Hamster.report(to: FRANK_RAO_ID, message:  "#{e.full_message}\n", use: :slack)
        Hamster.report(to: FRANK_RAO_ID, message:  "Failed: #{docket_pdf_url}", use: :slack)
      end
    end
  
  end

  def store_for(year)
    download_and_store(year)
    parse_dockets_and_store(year)
  end

  # Functions to download opinion pdf and parse one by one with loop
  def download_and_store_with_opinion_pdf(year)
    Hamster.report(to: FRANK_RAO_ID, message: "project-#{Hamster::project_number}. download_and_store_with_opinion_pdf(#{year}) started.", use: :slack)
    scraper = Scraper.new
    parser = Parser.new
    links = []
    
    year_actions_page  = scraper.get_court_actions_page(year)
    parser = Parser.new(year_actions_page.body)
    links = links +  parser.list_links

    case_info_list = []
    links.each do |link|
      actions_page = scraper.get_page(link)
      parser = Parser.new(actions_page.body)
      # case_info_list = case_info_list + parser.get_case_info_list
      # p case_info_list
      parser.get_case_info_list.each_with_index do |case_info, index|
        begin
          opinion_pdf_path = scraper.download_opinion_pdf(case_info[:pdf_url])
          opinion_pdf_text = scraper.get_origin_text_from_pdf_file(opinion_pdf_path)

          if year.to_i <= 2019
            opinion_info = parser.get_info_from_opinion_pdf_2019(opinion_pdf_text)
          else
            opinion_info = parser.get_info_from_opinion_pdf(opinion_pdf_text)
          end

          case_pdf_on_aws = {
            court_id: case_info[:court_id],
            case_id: case_info[:case_id],
            source_type: "activity",
            aws_link: nil,
            source_link: case_info[:pdf_url],
            aws_html_link: nil
          }
          case_pdf_on_aws[:aws_link] = store_to_s3(case_pdf_on_aws, opinion_pdf_path)
  
          opinion_info[:case_pdf_on_aws] = case_pdf_on_aws
  
          case_relations_activity_pdf = {
            case_activities_md5: @keeper.add_md5_hash(opinion_info[:case_activity], LaScCaseActivities)[:md5_hash],
            case_pdf_on_aws_md5: @keeper.add_md5_hash(case_pdf_on_aws, LaScCasePdfsOnAws)[:md5_hash],
          }
          
          opinion_info[:case_relations_activity_pdf] = case_relations_activity_pdf
          
          opinion_info[:case_info][:case_name] = case_info[:case_name].gsub(/\n/, "")
          opinion_info[:case_info][:case_id] = case_info[:case_id]
          opinion_info[:case_info][:data_source_url] = case_info[:pdf_url]
          
          @keeper.store_case_info(opinion_info[:case_info])
          @keeper.store_data(opinion_info[:case_additional_info], LaScCaseAdditionalInfo, case_info[:pdf_url])
          @keeper.store_data(opinion_info[:case_party], LaScCaseParty, case_info[:pdf_url])
          @keeper.store_data(opinion_info[:case_activity], LaScCaseActivities, case_info[:pdf_url])
          @keeper.store_data(case_pdf_on_aws, LaScCasePdfsOnAws)
          @keeper.store_data(case_relations_activity_pdf, LaScCaseRelationsActivityPdf)
  
          scraper.clear_opinion_pdf
      
        rescue Exception => e
          Hamster.report(to: FRANK_RAO_ID, message: e.full_message, use: :slack)
          Hamster.report(to: FRANK_RAO_ID, message: "project-#{Hamster::project_number}. Parsing Error PDF: #{case_info[:pdf_url]}", use: :slack)
        end
      end
      
    end
  end
  
  def store_to_s3(case_pdf_on_aws, opinion_pdf_path)
    file_name = case_pdf_on_aws[:source_link].split("/")[-1]
    body = File.read(opinion_pdf_path)
    key = "us_courts_expansion/#{case_pdf_on_aws[:court_id]}/#{case_pdf_on_aws[:case_id]}_opinion/#{file_name}"
    @s3.find_files_in_s3(key).empty? ? @s3.put_file(body, key, metadata={url: case_pdf_on_aws[:source_link]}) : "https://court-cases-activities.s3.amazonaws.com/#{key}"
  end

  def store_with_docket_pdf
    Hamster.report(to: FRANK_RAO_ID, message: "project-#{Hamster::project_number}. store_with_docket_pdf() started.", use: :slack)
    scraper = Scraper.new
    parser = Parser.new
    scraper.docket_pdf_list.each do |pdf_file|
      
      pdf_text = scraper.get_origin_text_from_pdf_file(pdf_file)
      blocks = parser.get_case_context_from_origin(pdf_text)

      blocks[1..].each do |block|
        
        block_hash = parser.get_context_analyzed_origin_text(block)
        party_items = parser.get_party_info(block_hash[:body])
        
        party_items.each do |party_item|
          data = party_item.merge({court_id: Manager::COURT_ID, case_id: block_hash[:head]})
          @keeper.store_data(data, LaScCaseParty)
        end
      end
    end
  end

  def clear_docket_pdfs
    Hamster.report(to: FRANK_RAO_ID, message: "project-#{Hamster::project_number}. clear_docket_pdfs() started.", use: :slack)
    scraper = Scraper.new
    scraper.clear_docket_pdfs
  end
  
end
