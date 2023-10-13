# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @scraper = Scraper.new
  end

  def download
    db_case_ids = @keeper.get_case_numbers
    source_case_ids = []
    start_date = Date.new(Date.today.year,Date.today.month,1)
    end_date = Date.new(Date.today.year,Date.today.month,Date.today.day)
    date_array = (start_date..end_date).map(&:to_s)
    date_loop = date_array.select{|e| date_array.index(e)%7==0}
    date_loop.each do |date|
      start_record = 1
      year = date.split('-').first
      while true
        main_response = @scraper.main_request_post(date.to_date.strftime("%m/%d/%Y"),start_record)
        case_ids = @parser.get_case_ids(main_response)
        break if (case_ids.empty?)
        source_case_ids << case_ids
        start_record += 15
      end
    end
    download_pages(db_case_ids.concat(source_case_ids.flatten))
  end

  def store
    processed_files = file_handling(processed_files,'r') rescue []
    downloaded_folders = peon.list(subfolder: "#{@keeper.run_id}").reject{|e| e.include? 'txt'}
    downloaded_folders.each do |folder|
      next if (processed_files.include? folder)
      downloaded_files = peon.give_list(subfolder: "#{@keeper.run_id}/#{folder}")
      case_file   = get_file_name(downloaded_files,'case')
      party_file  = get_file_name(downloaded_files,'party')
      docket_file = get_file_name(downloaded_files,'docket')
      next if (case_file.nil? || party_file.nil? || docket_file.nil?)
      case_body   = get_page_body(folder,case_file)
      party_body  = get_page_body(folder,party_file)
      docket_body = get_page_body(folder,docket_file)
      next if ((case_body.include? 'html') || (party_body.include? 'html') || (docket_body.include? 'html'))
      data_array = @parser.parse_data(case_body,party_body,docket_body,@keeper.run_id)
      @keeper.insert_records(data_array.first,'info')
      @keeper.insert_records(data_array.second,'party')
      @keeper.insert_records(data_array.third,'activity')
      file_handling(folder,'a')
    end
    @keeper.mark_delete('info')
    @keeper.finish
    FileUtils.rm_rf("#{storehouse}store/#{@keeper.run_id}")
  end

  private

  def download_pages(case_ids)
    downloaded_ids = file_handling(downloaded_ids,'r') rescue []
    case_ids.each do |case_id|
      next if (downloaded_ids.include? case_id)
      main_response = @scraper.main_request
      cookie_value = main_response.headers['set-cookie']
      case_response = @scraper.get_inner_response("https://www.courts.mo.gov/cnet/cases/newHeaderData.do?caseNumber=#{case_id}&courtId=CT22&isTicket=&locnCode=",cookie_value)
      party_response = @scraper.get_inner_response("https://www.courts.mo.gov/cnet/cases/party.do?caseNumber=#{case_id}&courtId=CT22&isTicket=",cookie_value)
      docket_response = @scraper.get_inner_response("https://www.courts.mo.gov/cnet/cases/docketEntriesSearch.do?displayOption=A&sortOption=D&hasChange=false&caseNumber=#{case_id}&courtId=CT22&isTicket=",cookie_value)
      subfolder = "#{@keeper.run_id}/#{create_file_name(case_id)}/"
      begin
        save_html(case_response,"case_#{create_file_name(case_id)}",subfolder)
        save_html(party_response,"party_#{create_file_name(case_id)}",subfolder)
        save_html(docket_response,"docket_#{create_file_name(case_id)}",subfolder)
      rescue
        next
      end
      file_handling(case_id,'a')
    end
  end

  def create_file_name(value)
    file_name = value.scan(/\d+/).join('_')
    file_name = value.gsub(' ','_') if (file_name.empty?)
    file_name
  end

  def get_page_body(folder,file)
    peon.give(subfolder: "#{@keeper.run_id}/#{folder}",file: file)
  end

  def get_file_name(files,key)
    files.select{|e| e.include? key}.first
  end

  def get_date_start_index(year)
    begin
      dates_list = peon.list(subfolder: "#{@keeper.run_id}/#{year}/")
      @date_loop.index(dates_list.sort.reverse.first.gsub('_','-'))
    rescue
      0
    end
  end

  def get_downloaded_case_ids(year,date)
    begin
      peon.list(subfolder: "#{@keeper.run_id}/#{year}/#{date}")
    rescue
      []
    end
  end

  def save_html(html,file_name,sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end

  def file_handling(content,flag)
    list = []
    File.open("#{storehouse}store/links.txt","#{flag}") do |f|
      flag == 'r' ? f.each {|e| list << e.strip } : f.write(content.to_s + "\n")
    end
    list unless list.empty?
  end

end
