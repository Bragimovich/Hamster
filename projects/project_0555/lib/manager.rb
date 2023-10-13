# frozen_string_literal: true

require 'date'

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester
  SUB_FOLDER = 'iowacourts_gov'
  BASE_URL   = 'https://www.iowacourts.gov'

  attr_reader :higher_court, :lower_court

  def initialize(courts)
    super
    @higher_court = courts[:higher_court]
    @lower_court  = courts[:lower_court]

    @scraper = Scraper.new
    @parser  = Parser.new(courts)
    @keeper  = Keeper.new
  end

  def download
    begin
      @all_cases = []
      number = 0

      loop do
        url = BASE_URL + "/iowa-courts/supreme-court/supreme-court-opinions/page/#{number.to_s}"
        page_response , status = @scraper.download_page(url)
        each_page_cases = @parser.get_each_page_cases(page_response.body)

        each_page_cases.each do |per_case|
          @all_cases.push per_case.css('a > @href')
        end

        break unless status == 200
        number += 1

        @all_cases.each do |cases|
          list_case_info_data     = []
          list_case_info_add_data = []
          list_case_party         = []
          list_case_activity      = []
          list_case_pdf_on_aws    = []
          list_case_relations     = []
          @md5_array = []

          @data_source_url = "#{BASE_URL}#{cases.to_s}"
          page_response , status = @scraper.download_page(@data_source_url)
  
          next unless status == 200
  
          hash_info, 
          hash_info_add, 
          array_party, 
          array_activity,
          array_pdf_on_aws,
          array_case_relation = get_case_info(page_response)
  
          list_case_info_data << hash_info
          list_case_info_add_data.concat(hash_info_add)
          list_case_party.concat(array_party)
          list_case_activity.concat(array_activity)
          list_case_pdf_on_aws.concat(array_pdf_on_aws)
          list_case_relations.concat(array_case_relation)

          list_case_info_data = list_case_info_data.map{ |hash| add_md5_hash(hash) }
          list_case_info_add_data = list_case_info_add_data.map{ |hash| add_md5_hash(hash) }
          list_case_party = list_case_party.map{ |hash| add_md5_hash(hash) }
          list_case_relations = list_case_relations.map{ |hash| add_md5_hash(hash) }
          
          @keeper.update_touch_run_id(@md5_array)
          @keeper.store_case_info(list_case_info_data)
          @keeper.store_case_info_add(list_case_info_add_data)
          @keeper.store_case_party(list_case_party)
          @keeper.store_case_activity(list_case_activity)
          @keeper.store_case_relations(list_case_relations)
          @keeper.store_case_pdf_on_aws(list_case_pdf_on_aws)
          @keeper.finish
        rescue Exception => e
          next
          Hamster.report(to: 'Robert Arnold', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}", use: :slack)
        end
      rescue Exception => e
        next
        Hamster.report(to: 'Robert Arnold', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}", use: :slack)
      end

    rescue Exception => e
      Hamster.report(to: 'Robert Arnold', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}", use: :slack)
    end
  end

  private

  def get_case_info(response)
    case_info = @parser.get_case_info(response.body)
    case_filed_date = Date.parse(case_info[:case_filed_date]).strftime('%Y-%m-%d')

    filename = @scraper.pdf(case_info[:opinion_link], SUB_FOLDER, case_info[:case_id]) unless case_info[:opinion_link].nil?
    
    reader = PDF::Reader.new("#{ENV['HOME']}/HarvestStorehouse/project_0555/trash/iowacourts_gov/#{filename}")

    status_as_of_date = ''
    first_page = reader.pages[0].text.squish
    status = first_page.scan /\b[A-Z ,]{3,}\./

    case_info_data_add = []
    
    start_text = 'Appeal from the '
    lower_court_name = first_page[/#{start_text}(.*?)\,/m, 1]
    lower_judge_name = first_page[/#{lower_court_name}\,( .*?)\,/m, 1].strip unless first_page[/#{lower_court_name}\,( .*?)\,/m, 1].nil?

    if lower_judge_name == nil || lower_judge_name.length == 0
      first = first_page.gsub(/[^0-9A-Za-z ,.]/, '')
      court_name = lower_court_name.gsub(/[^0-9A-Za-z ,.]/, '')
      lower_judge_name = first[/#{court_name}\,( .*?)\,/m, 1].strip
    end
  
    if case_info[:lower_court_id].to_s == @lower_court.to_s
      start_text = 'On review from the '
      lower_name = first_page[/#{start_text}(.*?)\./m, 1]
      lower_judge_name = nil
      data = {
        'court_id'              => @higher_court,
        'case_id'               => case_info[:case_id],
        'lower_court_name'      => lower_name,
        'lower_case_id'         => case_info[:lower_case_id],
        'lower_judge_name'      => lower_judge_name,
        'lower_judgement_date'  => case_info[:lower_judgement_date],
        'lower_link'            => case_info[:lower_link],
        'disposition'           => case_info[:disposition],
        'data_source_url'       => @data_source_url
      }
      case_info_data_add << data
    end

    data = {
      'court_id'              => case_info[:lower_court_id].to_s == @lower_court.to_s ? @lower_court : @higher_court,
      'case_id'               => case_info[:case_id],
      'lower_court_name'      => lower_court_name,
      'lower_case_id'         => case_info[:lower_court_id].to_s == @lower_court.to_s ? nil : case_info[:lower_case_id],
      'lower_judge_name'      => lower_judge_name,
      'lower_judgement_date'  => case_info[:lower_judgement_date],
      'lower_link'            => case_info[:lower_link],
      'disposition'           => case_info[:disposition],
      'data_source_url'       => @data_source_url
    }
    case_info_data_add << data

    loop do 
      status_as_of_date = status.pop
      break if status_as_of_date.length >= 7
    end
    status_as_of_date.delete_suffix!(".")

    case_info_data = {
      'court_id'              => @higher_court,
      'case_id'               => case_info[:case_id],
      'case_name'             => case_info[:case_name],
      'case_filed_date'       => case_filed_date,
      'case_type'             => case_info[:case_type],
      'case_description'      => case_info[:case_description],
      'disposition_or_status' => case_info[:disposition_or_status],
      'status_as_of_date'     => status_as_of_date,
      'judge_name'            => case_info[:judge_name],
      'lower_court_id'        => case_info[:lower_court_id],
      'lower_case_id'         => case_info[:lower_case_id],
      'data_source_url'       => @data_source_url
    }

    case_info[:case_party].each do |party|
      party['court_id']          = @higher_court
      party['case_id']           = case_info[:case_id]
      party['party_law_firm']    = nil
      party['party_address']     = nil
      party['party_city']        = nil
      party['party_state']       = nil
      party['party_zip']         = nil
      party['party_description'] = nil
      party['data_source_url']   = @data_source_url
    end

    case_info[:case_activities].each do |activity|
      activity_date               = Date.parse(activity['activity_date']).strftime('%Y-%m-%d')
      activity['court_id']        = @higher_court
      activity['case_id']         = case_info[:case_id]
      activity['activity_desc']   = nil
      activity['activity_date']   = activity_date
      activity['data_source_url'] = @data_source_url
    end

    case_info[:case_activities] = case_info[:case_activities].map{ |hash| add_md5_hash(hash) }

    case_pdf_aws = case_info[:case_pdf_on_aws].slice(0 .. -1)

    case_pdf_aws.each do |pdf_aws|
      pdf_aws['court_id'] = @higher_court
      pdf_aws['case_id']  = case_info[:case_id]
      filename = @scraper.pdf(pdf_aws['source_link'], SUB_FOLDER, pdf_aws['case_id']) unless pdf_aws['source_link'].nil?
      pdf_aws['aws_link'] = @scraper.store_to_aws( "#{ENV['HOME']}/HarvestStorehouse/project_0555/trash/iowacourts_gov/#{filename}",
                                                   pdf_aws['source_name'],
                                                   pdf_aws['source_link'],
                                                   pdf_aws['court_id'],
                                                   pdf_aws['case_id']
                                                  )
      pdf_aws['data_source_url'] = @data_source_url
      pdf_aws.delete('source_name')
    end

    case_pdf_aws = case_pdf_aws.map{ |hash| add_md5_hash(hash) }

    num_loop = case_pdf_aws.length()

    case_relation = []

    num_loop.times do |num|
      data = {
        'court_id'            => @higher_court,
        'case_id'             => case_info[:case_id],
        'case_activities_md5' => case_info[:case_activities][num]['md5_hash'],
        'case_pdf_on_aws_md5' => case_info[:case_pdf_on_aws][num]['md5_hash'],
        'source_link'         => case_info[:case_pdf_on_aws][num]['source_link'],
        'aws_html_link'       => case_info[:case_pdf_on_aws][num]['aws_html_link'],
        'data_source_url'     => @data_source_url
      }
      case_relation << data
    end

    @scraper.clear_folder("#{ENV['HOME']}/HarvestStorehouse/project_0555/trash/iowacourts_gov/")

    [
      case_info_data,
      case_info_data_add,
      case_info[:case_party],
      case_info[:case_activities],
      case_pdf_aws,
      case_relation
    ]
  end

  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    @md5_array << hash['md5_hash']
    hash['run_id'] = @keeper.run_id
    hash['touched_run_id'] = @keeper.run_id
    hash
  end

end
