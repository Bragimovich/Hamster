# frozen_string_literal: true

require_relative 'pdf_parser'

class Parser < Hamster::Parser
  def initialize
    super
    @court_id = 434
  end

  def extract_form_fields(response, year, month)
    parsed_doc = Nokogiri::HTML.parse(response.body)
    field_elements = parsed_doc.xpath("//*[contains(@name, '__') or contains(@name, 'ctl00$')][not(contains(@type, 'submit'))][not(contains(@type, 'button'))]")
    form_fields = {}
    field_elements.each do |field_el|
      form_fields[field_el[:name]] = field_el[:value] || ''
    end
    form_fields['__EVENTTARGET'] = 'ctl00$MainContent$btnSearchOpinionsByMonthYear'
    form_fields['ctl00$MainContent$ddlSearchOpinions1_Year'] = Date.today.year.to_s
    form_fields['ctl00$MainContent$ddlSearchOpinions2_Year'] = year.to_s
    form_fields['ctl00$MainContent$ddlSearchOpinions2_Month'] = month
    form_fields
  end

  def parse_opinions(response)
    parsed_doc = Nokogiri::HTML.parse(response.body)
    @case_ids  = []
    opinions   = []
    parsed_doc.xpath("//div[@id='searchModal']//table/tbody/tr/td").each do |td|
      begin
        parsed_hash = tags_to_hash(td)
        opinions << parsed_hash if parsed_hash
      rescue Exception => e
        logger.info td&.text
        logger.info e.full_message
        next
      end
    end
    opinions
  end

  def scraped_ids
    @case_ids
  end

  private

  def upload_to_aws(pdf_file_url)
    aws_s3        = AwsS3.new(bucket_key = :us_court)
    cobble        = Hamster::Scraper::Dasher.new(:using => :cobble)
    pdf_file_name = /([^\/]+.pdf)/.match(pdf_file_url)[0]
    pdf_body      = cobble.get(pdf_file_url)
    metadata      = {court_id: @court_id.to_s, case_id: @case_id.to_s}
    key           = "us_courts_expansion/#{@court_id}/#{@case_id}/#{pdf_file_name}"
    aws_s3.put_file(pdf_body, key, metadata)
  end

  def tags_to_hash(td)
    # skipping if case_id does not exist in the scrapped tags
    return unless td.xpath(".//strong").first
  
    hash_data     = {}
    @case_id      = td.xpath(".//strong").first.text
    @pdf_file_url = td.at_xpath(".//a/@href").value
    td_text       = td.text.split(/\r|\n|\r\n/).map(&:strip).reject(&:empty?).map { |s| s.split(/:\s*/) }
    td_text.each do |text|
      if text[0] == 'Opinion Date'
        @activity_date = Date.strptime(text[1], '%m/%d/%Y').to_s
      elsif text[0] == 'Case Title'
        @case_name = text[1].split(' ').join(' ')
      elsif text[0] == 'Lower Court'
        @lower_court_name = text[1]
      end
    end
    logger.info ">>>>>Parsing pdf: case_id is #{@case_id}, pdf_url: #{@pdf_file_url}"
    pdf_parser = PdfParser.new(@pdf_file_url, @case_id)

    return unless pdf_parser.parseable? # Skipping for denied PDFs
    @case_ids << @case_id

    @pdf_info = pdf_parser.parse
    logger.info ">>>>>Parsing pdf DONE!!!!!\n"
    @aws_url  = upload_to_aws(@pdf_file_url)
    hash_data[:case_info]            = case_info
    hash_data[:case_additional_info] = case_additional_info
    hash_data[:case_party]           = @pdf_info[:party_info]
    hash_data[:case_activities]      = case_activities
    hash_data[:case_pdfs_on_aws]     = case_pdfs_on_aws
    hash_data[:case_activity_pdf]    = case_activity_pdf
    hash_data
  end

  def case_info
    hash = {
      court_id: @court_id,
      case_id: @case_id,
      case_name: @case_name,
      status_as_of_date: @pdf_info[:status_as_of_date],
      judge_name: @pdf_info[:judge_name],
      lower_case_id: @pdf_info[:lower_case_id],
      data_source_url: @pdf_file_url
    }
    hash.merge(md5_hash: create_md5_hash(hash))
  end

  def case_additional_info
    hash = {
      court_id: @court_id,
      case_id: @case_id,
      lower_court_name: @lower_court_name.match(/other/i) ? @pdf_info[:lower_court_name] : @lower_court_name,
      lower_case_id: @pdf_info[:lower_case_id],
      lower_judge_name: @pdf_info[:lower_judge_name],
      data_source_url: @pdf_file_url
    }
    hash.merge(md5_hash: create_md5_hash(hash))
  end

  def case_activities
    hash = {
      court_id: @court_id,
      case_id: @case_id,
      activity_date: @activity_date,
      activity_type: 'Opinion',
      file: @pdf_file_url,
      data_source_url: @pdf_file_url
    }
    hash.merge(md5_hash: create_md5_hash(hash))
  end

  def case_pdfs_on_aws
    hash = {
      court_id: @court_id,
      case_id: @case_id,
      source_type: 'activity',
      aws_link: @aws_url,
      source_link: @pdf_file_url,
      data_source_url: @pdf_file_url
    }
    hash.merge(md5_hash: create_md5_hash(hash))
  end

  def case_activity_pdf
    hash = {
      case_id: @case_id,
      case_activities_md5: case_activities[:md5_hash],
      case_pdf_on_aws_md5: case_pdfs_on_aws[:md5_hash],
      data_source_url: @pdf_file_url
    }
    hash.merge(md5_hash: create_md5_hash(hash))
  end

  def create_md5_hash(hash)
    hash.delete(:md5_hash) if hash[:md5_hash]
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end
end
