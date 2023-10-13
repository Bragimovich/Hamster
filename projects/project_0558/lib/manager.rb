# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/helper'

class Manager < Hamster::Harvester
  attr_reader :run_id

  WILLIAM_DEVRIES = 'U04JLLPDLPP'
  COURTS = {'supreme' => 328, 'appeals' => 445}

  def initialize
    super    
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @helper = Helper.new
    @run_id = @keeper.run_id    
  end

  def download
    Hamster.report(to: WILLIAM_DEVRIES, message: "0558 Download Started")
    @keeper.mark_as_started_download
    COURTS.keys.each { |court_type| download_opinions_html(court_type) }
    @keeper.mark_as_finished_download
    Hamster.report(to: WILLIAM_DEVRIES, message: "0558 Download Finished")
  end

  def download_opinions_html(court_type)
    main_page = @scraper.get_outer_page(court_type)
    @scraper.save_file(main_page, "opinions_#{court_type}.html", 'html')
  end

  def store(year)
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task#558 Store(#{year}) Started!")
    COURTS.keys.each do |court_type|
      main_page = @scraper.load_file("opinions_#{court_type}.html", "html")
      @parser.html = main_page
      pdf_links = @parser.list_links(year)
      
      case_info_records = []
      case_party_records = []
      additional_info_records = []
      case_activity_records = []
      record_counts = 0
      court_id = COURTS[court_type]

      the_case = {
        :info => {},
        :parties => [],
        :additional_info => [],
        :activities => [],
        :pdfs_on_aws => [],
        :relations_activity_pdf => []
      }

      b_start = false
      pdf_links.each_with_index do |pdf_link, index|
        
        pdf_name = pdf_link[:link].scan(/docId=(.*)/)[0][0] + ".pdf"
        
        next if @keeper.is_exist(court_id, pdf_link[:case_id])
        
        case_info =  {
          court_id: court_id,
          case_id:  pdf_link[:case_id],
          case_name: pdf_link[:case_name],
          case_filed_date: nil,
          case_type: nil,
          case_description: nil,
          disposition_or_status: nil,
          status_as_of_date: nil,
          judge_name: nil,
          lower_court_id: nil,
          lower_case_id: nil,
          data_source_url: pdf_link[:link]
        }

        pdf_file = @scraper.download_pdf(court_type, pdf_link[:link])
        pdf_content = @scraper.get_text_from_pdf(pdf_file, 5)
        
        case_info = case_info.merge(@parser.get_case_info(pdf_content))
        
        the_case[:info] = case_info
        md5_info = MD5Hash.new(table: :info)
        case_info[:md5_hash] = md5_info.generate(the_case[:info])

        case_party_arr = @parser.get_case_party(pdf_content)

        md5_party = MD5Hash.new(table: :party)
        case_party_arr.each do |case_party|
          record = {
            court_id: court_id,
            case_id: pdf_link[:case_id],
            data_source_url: case_info[:data_source_url],
          }
          record = record.merge(case_party)
          record[:md5_hash] = md5_party.generate(record)
          the_case[:parties].push(record)
        end
        
        additional_info_record = {
          court_id: court_id,
          case_id: pdf_link[:case_id],
          lower_court_name: nil,
          lower_case_id: nil,
          lower_judge_name: nil,
          lower_judgement_date: nil,
          lower_link: nil,
          disposition: nil,
          data_source_url: case_info[:data_source_url]
        }
        additional_info_record = additional_info_record.merge(@parser.get_additional_info(pdf_content))
        
        md5_additional_info = MD5Hash.new(:columns => %w(court_id case_id lower_court_name lower_case_id lower_judge_name lower_judgement_date lower_link disposition data_source_url))
        additional_info_record[:md5_hash] = md5_additional_info.generate(additional_info_record)

        the_case[:additional_info].push(additional_info_record)      

        case_activity_record = {
          court_id: court_id,
          case_id: pdf_link[:case_id],
          activity_date: nil,
          activity_desc: '',
          activity_type: 'Opinion',
          file: pdf_link[:link]
        }
        case_activity_record = case_activity_record.merge(@parser.get_case_activities(pdf_content))
        md5_activities = MD5Hash.new(:columns => %w(court_id case_id activity_date activity_type activity_desc file data_source_url))
        case_activity_record[:md5_hash] = md5_activities.generate(case_activity_record)
        the_case[:activities].push(case_activity_record)
        
        the_case = @helper.add_additional(the_case)

        @keeper.store_data(the_case[:info], NECaseInfo)
        @keeper.store_data(the_case[:parties], NECaseParty)
        @keeper.store_data(the_case[:additional_info], NECaseAdditionalInfo)
        @keeper.store_data(the_case[:activities], NECaseActivities)
        @keeper.store_data(the_case[:pdfs_on_aws], NECasePdfsOnAws)
        @keeper.store_data(the_case[:relations_activity_pdf], NECaseRelationsActivityPdf)

        @scraper.clear_pdf(court_type, pdf_link[:link])

        the_case = {
          :info => {},
          :parties => [],
          :additional_info => [],
          :activities => [],
          :pdfs_on_aws => [],
          :relations_activity_pdf => [],
        }
      end
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task#558 Store(#{year}) Finished!")
  end


end

