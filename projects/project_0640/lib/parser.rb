require_relative 'scraper'
require_relative 'manager'


class Parser < Hamster::Parser
  attr_reader :scraper

  def initialize
    super
    @scraper = Scraper.new
    @court_id = 330
  end

  def get_links(source)
    page = Nokogiri::HTML source.body
    link = page.xpath("//a[@class='file file--mime-application-pdf file--application-pdf']/@href")
  end

  def get_last_page(source)
    page = JSON.parse source.body
    last_page = page['last_page']
  end

  def parse_cases_pdf(link_pdf)
    pdf = scraper.get_pdf(link_pdf, 'case_accepted')
    data_source_url = 'https://www.courts.nh.gov/our-courts/supreme-court/cases-accepted'
    key_start = "us_courts_expansion/#{@court_id}/accepted/"
    aws_link = scraper.save_to_aws(link_pdf, key_start),

    case_info = []
    array_hash = []
    hash_case_info = []
    hash_additional_info = []
    hash_activity = []
    array_hash_pdf_on_aws = []
    array_hash_relation_pdf_activity = []
    array_hash_party_type = []

    unless pdf.nil?
      pdf.pages.each do |page|
        page_check = page.text.scan(/(\d{4}-\d{4}.*)\n.*Report/m)[0][0] rescue nil
        next unless page_check
        page.text.scan(/(\d{4}-\d{4}.*)\n.*Report/m)[0][0].split(/\n\n20/m).each do |case_info|
          hash_data = {}
          hash_data[:case_id] = '20' + case_info.scan(/\d{2}-\d{4}/)[0]
          hash_data[:case_name_first] = case_info.scan(/\d{2}-\d{4}(.*)\d{2}\/\d{2}\/\d{4}/)[0].first.squish rescue nil
          last_case_name = case_info.scan(/\n+ {19,}(.*) {20,}|\n+ {19,}(.*)/m)[0].compact[0].strip rescue ''
          hash_data[:full_case_name] = hash_data[:case_name_first] + " " + last_case_name.squish rescue nil
          hash_data[:lower_court_name] = case_info.scan(/\d+\/\d+\/\d+(.*)/m)[0][0].gsub(last_case_name, '').squish rescue nil
          hash_data[:date] = case_info.scan(/\d{2}\/\d{2}\/\d{4}/)[0]
          hash_data = mark_empty_as_nil(hash_data)
          array_hash << hash_data
        end
      end
    end
    
    array_hash.each do |arr|
      date_filled = Date.strptime(arr[:date], "%m/%d/%Y").to_s rescue nil
      case_name = arr[:full_case_name][0..500] rescue nil
      lower_court_name = arr[:lower_court_name][0..250] rescue nil
      new_hash_info = {
        court_id: @court_id,
        case_id: arr[:case_id],
        case_name: case_name,
        case_filed_date: date_filled,
        status_as_of_date: 'Active',
        data_source_url: link_pdf
      }
      hash_case_info << new_hash_info
      generate_md5_hash(%i[court_id case_id case_name case_filed_date], new_hash_info)

      additional_info = {
        court_id:         @court_id,
        case_id:          arr[:case_id],
        lower_court_name: lower_court_name,
        data_source_url: link_pdf,
      }
      generate_md5_hash(%i[court_id case_id lower_court_name data_source_url], additional_info)

      hash_additional_info << additional_info

      activity = {
        court_id:        @court_id,
        case_id:         arr[:case_id],
        activity_date:   date_filled,
        activity_type:   'Accepted',
        file:            link_pdf,
        data_source_url: 'https://www.courts.nh.gov/our-courts/supreme-court/cases-accepted'
      }
      generate_md5_hash(%i[court_id case_id activity_date activity_type file data_source_url], activity)

      hash_activity << activity

      #key_start = "us_courts_expansion/#{@court_id}/#{arr[:case_id]}_#{activity[:activity_type].downcase}/"

      hash_pdf_on_aws = {
        court_id: @court_id,
        case_id: activity[:case_id],
        source_type: 'activity',
        #aws_link: scraper.save_to_aws(link_pdf, key_start),
        aws_link: aws_link,
        source_link: link_pdf,
      }
      generate_md5_hash(%i[court_id case_id source_type source_link], hash_pdf_on_aws)

      array_hash_pdf_on_aws << hash_pdf_on_aws

      hash_relation_pdf_activity = {
        case_activities_md5: activity[:md5_hash],
        case_pdf_on_aws_md5: hash_pdf_on_aws[:md5_hash]
      }
      generate_md5_hash(%i[court_id case_id case_activities_md5 case_pdf_on_aws_md5], hash_relation_pdf_activity)

      array_hash_relation_pdf_activity << hash_relation_pdf_activity

      if !new_hash_info[:case_name].nil? && new_hash_info[:case_name].downcase.include?('in re')
        hash_party_one = {
          court_id:   @court_id,
          case_id:    new_hash_info[:case_id],
          party_name: new_hash_info[:case_name].split('In re').last.strip,
          party_type: 'party_1',
          data_source_url:  data_source_url
        }
        generate_md5_hash(%i[court_id case_id party_name party_type], hash_party_one)

      elsif !new_hash_info[:case_name].nil? && new_hash_info[:case_name].downcase.include?('v.')
        hash_party_one = {
          court_id:   @court_id,
          case_id:    new_hash_info[:case_id],
          party_name: new_hash_info[:case_name].split('v.').first.strip,
          party_type: 'party_1',
          data_source_url:  data_source_url
        }
        generate_md5_hash(%i[court_id case_id party_name party_type], hash_party_one)

        hash_party_two = {
          court_id:   @court_id,
          case_id:    new_hash_info[:case_id],
          party_name: new_hash_info[:case_name].split('v.').last.strip,
          party_type: 'party_2',
          data_source_url:  data_source_url
        }
        generate_md5_hash(%i[court_id case_id party_name party_type], hash_party_two)
      end

      array_hash_party_type << hash_party_one
      array_hash_party_type << hash_party_two

    end
    new_array_hash_info_join = { case_info: hash_case_info, additional_info:  hash_additional_info, case_activity: hash_activity, case_pdf_on_aws: array_hash_pdf_on_aws, case_relation: array_hash_relation_pdf_activity, party_type: array_hash_party_type }
  end

  def get_json_and_parse(source)
    array_hash_info = [] 
    array_hash_activity = [] 
    array_hash_party_type = [] 
    array_hash_pdf_on_aws = []
    array_hash_relation_pdf_activity = []
    json_data = JSON.parse(source)

    json_data['data'].each do |data|
      parsed_date = Date.strptime(Nokogiri::HTML.parse(data['list_content']).xpath("//div[@class='document__detail__information']").text.split.last, "%m/%d/%Y").to_s rescue nil
      pdf_url = BASE_URL + Nokogiri::HTML.parse(data['list_content']).xpath("//a/@href").text

      reader = scraper.get_pdf(pdf_url, 'case_opinion') rescue nil
      return if reader.nil?
      status_as_of_date = reader.pages.last.text.scan(/([A-Z]\w+{7,15})\./).first[0] rescue nil
      case_id = data['title'].split(',').first.scan(/\d+{4}-\d+{4}/).first
      if case_id.nil?
        case_id = reader.pages.first.text.scan(/\d{4,}-\d{4,}/)[0]
      end
      case_name = data['title'].split(',', 2).last.strip
      data_source_url = 'https://www.courts.nh.gov/our-courts/supreme-court/orders-and-opinions/case-orders/'

      hash_case_info = {
        court_id:         @court_id,
        case_id:          case_id,
        case_name:        case_name,
        case_filed_date: parsed_date,
        status_as_of_date:status_as_of_date,
        data_source_url: data_source_url,
      }
      generate_md5_hash(%i[court_id case_id case_name case_filed_date status_as_of_date], hash_case_info)


      hash_activity = {
        court_id:      @court_id,
        case_id:       case_id,
        activity_date: parsed_date,
        activity_type: 'Opinion',
        file:             pdf_url,
        data_source_url:  data_source_url,
      }

      generate_md5_hash(%i[court_id case_id activity_date activity_type file data_source_url], hash_activity)

      key_start = "us_courts_expansion/#{@court_id}/#{case_id}_#{hash_activity[:activity_type].downcase}/"

      hash_pdf_on_aws = {
        court_id: @court_id,
        case_id: hash_activity[:case_id],
        source_type: 'activity',
        aws_link: scraper.save_to_aws(pdf_url, key_start),
        source_link: pdf_url,
      }
      generate_md5_hash(%i[court_id case_id source_type source_link], hash_pdf_on_aws)

      if case_name.downcase.include?('in re')
        hash_party_one = {
          court_id:   @court_id,
          case_id:    data['title'].split(',').first.scan(/\d{4,}-\d{4,}/).first,
          party_name: case_name.split('In re').last.strip,
          party_type: 'party_1',
          data_source_url:  data_source_url
        }
        generate_md5_hash(%i[court_id case_id party_name party_type], hash_party_one)

      elsif case_name.downcase.include?('v.')
        hash_party_one = {
          court_id:   @court_id,
          case_id:    data['title'].split(',').first.scan(/\d{4,}-\d{4,}/).first,
          party_name: case_name.split('v.').first.strip,
          party_type: 'party_1',
          data_source_url:  data_source_url
        }
        generate_md5_hash(%i[court_id case_id party_name party_type], hash_party_one)

        hash_party_two = {
          court_id:   @court_id,
          case_id:    data['title'].split(',').first.scan(/\d{4,}-\d{4,}/).first,
          party_name: case_name.split('v.').last.strip,
          party_type: 'party_2',
          data_source_url:  data_source_url
        }
        generate_md5_hash(%i[court_id case_id party_name party_type], hash_party_two)
      end

      hash_relation_pdf_activity = {
        case_activities_md5: hash_activity[:md5_hash],
        case_pdf_on_aws_md5: hash_pdf_on_aws[:md5_hash]
      }
      generate_md5_hash(%i[court_id case_id case_activities_md5 case_pdf_on_aws_md5], hash_relation_pdf_activity)

      array_hash_info << hash_case_info
      array_hash_party_type << hash_party_one
      array_hash_party_type << hash_party_two
      array_hash_activity << hash_activity
      array_hash_pdf_on_aws << hash_pdf_on_aws
      array_hash_relation_pdf_activity << hash_relation_pdf_activity
    end
    array_hash_info_and_party = { record_info: array_hash_info, record_activity: array_hash_activity, record_party: array_hash_party_type, record_pdf_on_aws: array_hash_pdf_on_aws, record_relation_pdf: array_hash_relation_pdf_activity }
    array_hash_info_and_party = array_hash_info_and_party.compact
  end

  def generate_md5_hash(column, hash)
    md5 = MD5Hash.new(columns: column)
    md5.generate(hash)
    hash[:md5_hash] = md5.hash
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values {|value| value.empty? ? nil : value }
  end
end
