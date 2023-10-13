require_relative 'scraper'
require_relative 'parser'
require_relative 'keeper'
require_relative 'pdf_parser'
require_relative '../models/wv_sc_case_activities'
require_relative '../models/wv_sc_case_pdfs_on_aws'

class Manager < Hamster::Scraper

  def initialize(**options)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @court_id = 349
  end

  def download
    landing_page = @scraper.fetch_main_page
    return if landing_page.nil?

    array_links_from_main_page = @parser.get_links_from_landing_page(landing_page)
    array_links_from_main_page.each do |query|
      sub_page_html = @scraper.fetch_sub_page(query)
      sub_data = get_data_from_sub_page(sub_page_html, query)
      parse_data(sub_data)
    end
  end

  def store
    landing_page = @scraper.fetch_latest_page
    return if landing_page.nil?

    get_data_from_sub_page(landing_page, '')
  end

  def parse_data(sub_page_data)
    sub_page_data.each do |data|
      store_data(data)
    end
  end

  def store_data(data)
    pdf_data_hash = data['pdf_data']
    if pdf_data_hash.nil? || pdf_data_hash.empty?
      sc_case_info_hash(data)
    else
      sc_case_info_hash(data)
      sc_case_additional_info(data)
      sc_case_petitioner(data)
      sc_case_respondent(data)
      case_activities = sc_case_activities(data)
      pdfs_on_aws = sc_case_pdfs_on_aws(data)
      case_activities_hash = case_activities[:md5_hash]
      aws_pdf_hash = pdfs_on_aws[:md5_hash]
      sc_case_relations_activity_pdf(case_activities_hash, aws_pdf_hash)
    end
  end

  def create_md5_hash(hash, md5)
    md5.generate(hash)
    md5.hash
  end

  def sc_case_info_hash(info_hash)
    pdf_data_hash = info_hash['pdf_data']
    if pdf_data_hash.nil? || pdf_data_hash.empty?
      sc_case_info_hash = {
        court_id: @court_id,
        case_name: info_hash['case_name'],
        case_id: info_hash['case_id'],
        case_type: info_hash['case_type'],
      }
    else
      sc_case_info_hash = {
        court_id: @court_id,
        case_name: info_hash['case_name'],
        case_id: info_hash['case_id'],
        case_description: 'nil',
        case_type: info_hash['case_type'],
        disposition_or_status: 'nil',
        case_filed_date: pdf_data_hash[:case_filled_date],
        status_as_of_date: pdf_data_hash[:status_as_of_date],
        judge_name: pdf_data_hash[:lower_court_judge_name],
        lower_court_id: pdf_data_hash[:lower_court_id],
        lower_case_id: pdf_data_hash[:lower_case_id],
      }
    end

    md5 = MD5Hash.new(table: :info)
    md5_info_hash = {
      md5_hash: create_md5_hash(sc_case_info_hash, md5),
    }
    sc_case_info_hash.merge!(md5_info_hash)

    @keeper.info_hash(sc_case_info_hash)
  end

  def sc_case_additional_info(info_hash)
    pdf_data_hash = info_hash['pdf_data']
    sc_case_additional_info = {
      court_id: @court_id,
      case_id: info_hash['case_id'],
      lower_court_name: pdf_data_hash[:lower_case_id],
      lower_case_id: pdf_data_hash[:lower_court_name],
      lower_judge_name: pdf_data_hash[:lower_court_judge_name],
      lower_judgement_date: pdf_data_hash[:lower_judgement_date],
      lower_link: pdf_data_hash[:lower_link],
      disposition: pdf_data_hash[:disposition],
    }

    md5 = MD5Hash.new(table: :info)
    md5_info_hash = {
      md5_hash: create_md5_hash(sc_case_additional_info, md5),
    }
    sc_case_additional_info.merge!(md5_info_hash)

    @keeper.additional_info(sc_case_additional_info)
  end

  def sc_case_petitioner(info_hash)
    pdf_data_hash = info_hash['pdf_data']
    sc_case_petitioner = {
      court_id: @court_id,
      case_id: info_hash['case_id'],
      is_lawyer: 0,
      party_name: pdf_data_hash[:Petitioner],
      party_type: 'Petitioner',
    }

    md5 = MD5Hash.new(table: :party)
    md5_info_petitioner = {
      md5_hash: create_md5_hash(sc_case_petitioner, md5),
    }
    sc_case_petitioner.merge!(md5_info_petitioner)
    @keeper.case_party(sc_case_petitioner)
  end

  def sc_case_respondent(info_hash)
    pdf_data_hash = info_hash['pdf_data']
    sc_case_respondent = {
      court_id: @court_id,
      case_id: info_hash['case_id'],
      is_lawyer: 1,
      party_name: pdf_data_hash[:Respondent],
      party_type: 'Respondent',
    }

    md5 = MD5Hash.new(table: :party)
    md5_info_respondent = {
      md5_hash: create_md5_hash(sc_case_respondent, md5),
    }
    sc_case_respondent.merge!(md5_info_respondent)
    @keeper.case_party(sc_case_respondent)
  end

  def sc_case_pdfs_on_aws(info_hash)
    sc_case_pdfs_on_aws = {
      court_id: @court_id,
      case_id: info_hash['case_id'],
      source_type: 'activity' ,
      aws_link: info_hash['aws_url'],
      source_link: info_hash['source_link'],
    }

    md5 = MD5Hash.new(table: :pdfs_on_aws)
    md5_info_hash = {
      md5_hash: create_md5_hash(sc_case_pdfs_on_aws, md5),
    }
    sc_case_pdfs_on_aws.merge!(md5_info_hash)

    @keeper.pdfs_on_aws(sc_case_pdfs_on_aws)
  end

  def sc_case_activities(info_hash)
    wv_sc_case_activities = {
      court_id: @court_id,
      case_id: info_hash['case_id'],
      activity_date: info_hash['activity_date'],
      activity_desc: '',
      activity_type: info_hash['case_type'],
      file: info_hash['source_link'],
    }

    md5 = MD5Hash.new(table: :activities)
    md5_sc_case_activities_hash = {
      md5_hash: create_md5_hash(wv_sc_case_activities, md5),
    }
    wv_sc_case_activities.merge!(md5_sc_case_activities_hash)
    @keeper.case_activities(wv_sc_case_activities)
  end

  def sc_case_relations_activity_pdf(case_activities_hash, pdfs_on_aws_hash)
    sc_case_relations_activity_pdf = {
      case_info_md5: case_activities_hash,
      case_pdf_on_aws_md5: pdfs_on_aws_hash,
    }

    string_to_hash = sc_case_relations_activity_pdf.to_s
    hash = Digest::MD5.hexdigest(string_to_hash)
    md5_info_hash = {
      md5_hash: hash,
    }
    sc_case_relations_activity_pdf.merge!(md5_info_hash)

    @keeper.relations_activity_pdf(sc_case_relations_activity_pdf)
  end

  def get_data_from_sub_page(html, query_str)
    document = Nokogiri::HTML html
    case_info_hash = []
    @year = 2016

    (@year..Time.now.year).each do |year|
      document.css("tr").map do |tr|
        cells = tr.search('td')
        next unless cells.present?
        info_hash = {}
        if cells.css('td a') != 0
          cells.css('td a').map do |link|
            info_hash['activity_date'] = cells[0].text
            info_hash['case_id'] = cells[1].text
            check_data_exists = @keeper.check_record_exits(info_hash['case_id'])
            next if check_data_exists.present?

            info_hash['case_name'] = cells[2].text
            info_hash['case_type'] = cells[3].text
            info_hash['activity_type'] = cells[4].text
            info_hash['source_link'] =  @scraper.get_file_path(link['href'], query_str)
            @scraper.save_pdf_file(info_hash['source_link'], year, info_hash['case_id'])
            pdf_paths = Dir["#{storehouse}store/pdfs/#{year}/*.pdf"]
            pdf_path = pdf_paths.select{|file| file.include? info_hash['case_id']}.first
            reader = PDF::Reader.new(open(pdf_path))
            info_hash['pdf_data'] = @parser.fetch_data_from_pdf(info_hash['source_link'], info_hash['activity_type'], reader)
            info_hash['aws_url'] = info_hash['pdf_data'].nil? || info_hash['pdf_data'].empty? ? '' : @keeper.save_files_to_aws(info_hash['source_link'],info_hash['case_id'])
            case_info_hash << info_hash
            return case_info_hash
          end
        else
          info_hash['activity_date'] = cells[0].text
          info_hash['case_id'] = cells[1].text
          check_data_exist = @keeper.check_record_exits(info_hash['case_id'])
          next if check_data_exist.present?

          info_hash['case_name'] = cells[2].text
          info_hash['case_type'] = cells[3].text
          info_hash['activity_type'] = cells[4].text
          info_hash['source_link'] = nil
          info_hash['aws_url'] = nil
          info_hash['pdf_data'] = nil

          case_info_hash << info_hash
          return case_info_hash
        end
      end
    end
  end

end
