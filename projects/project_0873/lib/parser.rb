# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    @hash      = nil
    @aws_s3    = AwsS3.new(:hamster, :hamster)
    @get_info  = ->(array, key) { array.select{|item| item[0]&.match(/#{key}/i)}&.first }
    super
  end

  def inmate_list(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    parsed_doc.xpath("//td/a[contains(@href, '/DOC_Inmate/details')]/@href").map(&:text)
  end

  def require_accept_page?(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    njdoc_text = parsed_doc.at_xpath("//div[@id='mainContent']/table/tbody/tr[2]/td/p[2]")&.text
    !!njdoc_text.presence
  end

  def parse_detail_page(response_body, data_source_url)
    @hash            = {}
    match = data_source_url.match(/(https.*)&n/)
    @data_source_url = match[1]
    parsed_doc       = Nokogiri::HTML.parse(response_body)
    inmate_table     = parsed_doc.at_xpath("//div[@id='mainContent']/table/tbody/tr[2]/td/table/tbody/tr/td[1]/table")
    mugshot_table    = parsed_doc.at_xpath("//div[@id='mainContent']/table/tbody/tr[2]/td/table/tbody/tr/td[2]/table")
    charge_table     = parsed_doc.at_xpath("//div[@id='mainContent']/table/tbody/tr[3]/td/table/tbody/tr[1]/td[1]/table")
    arrest_table     = parsed_doc.at_xpath("//div[@id='mainContent']/table/tbody/tr[3]/td/table/tbody/tr[2]/td[1]/table")
    alias_table      = parsed_doc.at_xpath("//div[@id='mainContent']/table/tbody/tr[3]/td/table/tbody/tr[2]/td[2]/table")
    inmate_row_data  = []
    mubgshot_url     = mugshot_table.at_xpath("./tbody/tr[1]/td/img/@src").value
    inmate_table.xpath("./tbody/tr").each do |tr|
      next if tr.xpath("./td").count != 2
      inmate_row_data << [tr.at_xpath("./td[1]").text, tr.at_xpath("./td[2]").text]
    end

    inmate_data(inmate_row_data)
    inmate_id_data(inmate_row_data)
    mugshot_data(mubgshot_url)
    additional_data(inmate_row_data)
    alias_data(alias_table)
    arrest_data(arrest_table)
    charge_data(charge_table)
    @hash.dup
  end

  def inmate_data(inmate_row_data)
    @full_name = get_field_value(inmate_row_data, 'Sentenced as:')
    @hash['NjDocInmate'] = {
      data_source_url: @data_source_url,
      full_name: @full_name,
      race: get_field_value(inmate_row_data, 'Race:'),
      sex: get_field_value(inmate_row_data, 'Sex:'),
      birthdate: get_field_value(inmate_row_data, 'Birth Date:'),
      data_source_url: @data_source_url
    }
    mrd = get_field_value(inmate_row_data, 'Current Max Release Date:')
    mrd = mrd == 'N/A' ? nil : mrd
    @hash['NjDocHoldingFacility'] = {
      start_date: get_field_value(inmate_row_data, 'Admission Date:'),
      facility: 'Current Facility',
      facility_type: get_field_value(inmate_row_data, 'Current Facility:'),
      max_release_date: mrd,
      actual_release_date: nil,
      data_source_url: @data_source_url
    }
    e_date = get_field_value(inmate_row_data, 'Current Parole Eligibility Date:')   
    if e_date != 'N/A'
      @hash['NjDocParoleBookingDate'] = {
        date: e_date, 
        event: 'Current Parole Eligibility'
      }
    end
    
  end

  def inmate_id_data(inmate_row_data)
    @inmate_id = get_field_value(inmate_row_data, 'SBI Number:')
    @hash['NjDocInmateId'] = {
      type: 'SBI Number',
      number: @inmate_id,
      data_source_url: @data_source_url
    }
  end

  def mugshot_data(mubgshot_url)
    org_link = nil
    aws_link = nil
    if mubgshot_url
      org_link = "#{Scraper::HOST}#{mubgshot_url}"
      aws_link = upload_to_aws(org_link, @full_name, @inmate_id)
    end    
    @hash['NjDocMugshot'] = {
      aws_link: aws_link,
      original_link: org_link,
      data_source_url: @data_source_url
    }
  end

  def additional_data(inmate_row_data)
    @hash['NjDocInmateAdditionalInfo'] = {
      ethnicity: get_field_value(inmate_row_data, 'Ethnicity:'),
      hair_color: get_field_value(inmate_row_data, 'Hair Color:'),
      eye_color: get_field_value(inmate_row_data, 'Eye Color:'),
      height: get_field_value(inmate_row_data, 'Height:'),
      weight: get_field_value(inmate_row_data, 'Weight:')
    }
  end

  def alias_data(alias_table)
    @hash['NjDocInmateAlias'] = []
    alias_table.xpath("./tbody/tr").each do |tr|
      full_name = tr.at_xpath("./td").text

      next if full_name == 'ALIASES'

      @hash['NjDocInmateAlias'] << {
        full_name: full_name,
        data_source_url: @data_source_url
      }
    end
  end

  def arrest_data(arrest_table)
    tr = arrest_table.xpath("./tbody/tr").last
    if tr.at_xpath("./td[2]").text == 'Currently In Custody'
      status = 'Currently In Custody'
    else
      status = 'Release'
      @hash['NjDocHoldingFacility'][:actual_release_date] = tr.at_xpath("./td[2]").text.strip
    end
    @hash['NjDocArrest'] = {
      status: status,
      booking_date: tr.at_xpath("./td[1]").text,
      data_source_url: @data_source_url
    }
  end

  def charge_data(charge_table)
    @hash['NjDocCharge'] = []
    ind = 1
    charge_table.xpath("./tbody/tr").each do |tr|
      next if tr.xpath("./td").count != 7 || tr.xpath("./td[1]").text == 'Offense'

      tr_data = tr.xpath("./td/div").map(&:text)
      o_date = tr_data[1].strip == 'UNKNOWN' ? nil : tr_data[1].strip
      @hash['NjDocCharge'] << {
        counts: tr_data[0].split("\n")[0].strip,
        description: "Charge##{ind}: #{tr_data[0].split("\n")[1].strip}",
        offense_date: o_date,
        data_source_url: @data_source_url,
        court_hearing_data: {
          court_date: tr_data[2].strip,
          case_number: tr_data[4].strip,
          min_release_date: parse_date(tr_data[5].strip),
          max_release_date: parse_date(tr_data[6].strip),
          data_source_url: @data_source_url,
          court_address: {
            full_address: tr_data[3].strip
          }
        }
      }
      ind += 1
    end
  end

  private

  def get_field_value(array, field)
    field_value = @get_info.call(array, field)
    field_value[1]&.strip&.presence if field_value
  end

  def upload_to_aws(photo_url, full_name, inmate_id)
    return unless photo_url
    return if photo_url.include?('badge/docbadge.gif')

    begin
      response  = Hamster.connect_to(photo_url)
      content   = response.body if response
      key       = "inmates/nj/doc/#{full_name.parameterize.underscore}_#{inmate_id}.jpg"
      @aws_s3.put_file(content, key) if content
    rescue => e
      logger.info "404 not found mugshot url: #{photo_url}"
      logger.info e.full_message

      return
    end
  end

  def parse_date(date_string)
    return if !date_string.presence || date_string == 'None' || date_string == 'LIFE'

    year, month, day = [0,0,0]
    if date_string.match(/(\d.*)\s(?:Year|Years)(\d.*)\s(?:Month|Months)(\d*.)\sDay/)
      match = date_string.match(/(\d.*)\s(?:Year|Years)(\d.*)\s(?:Month|Months)(\d*.)\sDay/)
      year = match[1]
      month = match[2]
      day = match[3]
    elsif date_string.match(/(\d.*)\sYear/)
      match = date_string.match(/(\d.*)\sYear/)
      year = match[1]
    elsif date_string.match(/(\d.*)\sMonth/)
      match = date_string.match(/(\d.*)\sMonth/)
      month = match[1]
    elsif date_string.match(/(\d*.)\sDay/)
      match = date_string.match(/(\d.*)\sDay/)
      day = match[1]
    end
    Date.today + year.to_i.years + month.to_i.months + day.to_i.days
  end
end
