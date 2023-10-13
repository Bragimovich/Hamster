# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    @hash = nil
    @data_source_url = nil
    @get_info = ->(array, key) { array.select{|item| item.match(/#{key}/i)}.first }
    super
  end

  def get_detail_page_links_from(response_body)    
    parsed_doc = Nokogiri::HTML.parse(response_body)
    parsed_doc.xpath("//tr[contains(@class,'resultPages')]/child::*[1]/a/@href").map(&:value)
  end

  def parseable?(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    span8 = parsed_doc.xpath("//div[@id='PageContentBody']/div/div[1]")
    span8.xpath("./table").count > 0
  end

  def parse_detail_page(response_body, data_source_url, scraper)
    @hash = {}
    @data_source_url = data_source_url
    parsed_doc = Nokogiri::HTML.parse(response_body)
    span8 = parsed_doc.xpath("//div[@id='PageContentBody']/div/div[1]")
    arrests_info = []
    name_info = span8.xpath("./h3[1]").text
    inmate_info = span8.xpath("./h4[1]").text   
    additional_info = span8.xpath("./table[@class='table table-striped']/tr/td").map(&:text)
    charges_info = []
    hearing_info = []
    span8.xpath("./h4[not(contains(@class, 'inmateID'))]").each do |charge|
      charge_key = charge.text.split(':').first.strip.presence
      charges_info << {
        description: charge_key,
        offense_type: charge.text.split(':').last.strip.presence
      }
      hearing_table = get_next_table_from(charge)
      hearing_data = hearing_table.xpath("./tr/td").map(&:text)
      hearing_info << {
        charge_key: charge_key,
        hearing_data: hearing_data.map{|i| i&.split(':')&.last&.strip}
      }
    end
    tentative_release_date_table = span8.xpath("./table").last
    tentative_release_date = tentative_release_date_table.xpath('./tr/td').map(&:text)
    tr_date = @get_info.call(tentative_release_date, 'tentative release:')&.split(':')&.last&.strip
    span4 = parsed_doc.xpath("//div[@id='PageContentBody']/div/div[2]")
    photo_url = span4.at_xpath("./div[@class='photoBox']/img/@src")&.value

    inmate_data(name_info, additional_info)
    inmate_id_data(inmate_info)
    additional_data(additional_info)
    physical_location_data(additional_info)
    mugshot_data(photo_url, scraper)
    charges_data(charges_info)
    court_hearings_data(hearing_info)
    holding_facilities_data(additional_info, tr_date)
    @hash.dup
  rescue => e
    logger.info "Parse error #{data_source_url}"
    logger.info response_body

    raise e
  end

  def inmate_data(name_info, info)
    @full_name = name_info
    data = {
      full_name: @full_name,
      first_name: name_info.split.first,
      last_name: name_info.split.last,
      race: get_field_value(info, 'race'),
      sex: get_field_value(info, 'sex'),
      data_source_url: @data_source_url
    }
    dot = @get_info.call(info, 'date of birth')&.split(':')&.last&.strip
    data[:birthdate] = Date.strptime(dot, '%m/%d/%Y') rescue nil
    @hash['MississippiInmate'] = data
  end

  def inmate_id_data(inmate_info)
    @inmate_id = inmate_info.split(':').last.strip
    data = {
      type: inmate_info.split(':').first.strip,
      number: @inmate_id,
      data_source_url: @data_source_url
    }

    @hash['MississippiInmateId'] = data
  end

  def additional_data(info)
    data = {
      height: get_field_value(info, 'height'),
      weight: get_field_value(info, 'weight'),
      hair_color:  get_field_value(info, 'hair color'),
      eye_color:  get_field_value(info, 'eye color'),
      complexion: get_field_value(info, 'complexion'),
      build: get_field_value(info, 'build'),
      current_location: get_field_value(info, 'location:'),
      unit: get_field_value(info, 'unit'),
      number_of_sentence: get_field_value(info, 'number of sentences')
    }
    @hash['MississippiInmateAdditionalInfo'] = data
  end

  def physical_location_data(info)
    movement_date = @get_info.call(info, 'location change date')&.split(':')&.last&.strip
    movement_date = Date.strptime(movement_date, '%m/%d/%Y') rescue nil
    data = {
      location: get_field_value(info, 'location:'),
      movement_date: movement_date
    }
    @hash['MississippiPhysicalLocationHistory'] = data
  end

  def mugshot_data(photo_url, scraper)
    original_link = photo_url ? "#{Scraper::BASE_URL}#{photo_url}" : nil
    aws_link = scraper.upload_to_aws(original_link, @inmate_id, @full_name)
    data = {
      aws_link: aws_link,
      original_link: original_link,
      data_source_url: @data_source_url
    }
    @hash['MississippiMugshot'] = data
  end

  def charges_data(charges_info)
    data = []
    charges_info.each do |item|
      data << item.merge(data_source_url: @data_source_url)
    end
    @hash['MississippiCharge'] = data
  end

  def court_hearings_data(hearing_info)
    data = []
    hearing_info.each do |item|
      data << item.merge(data_source_url: @data_source_url)
    end
    @hash['MississippiCourtHearing'] = data
  end

  def holding_facilities_data(info, date)
    planned_release_date = Date.strptime(date, '%m/%d/%Y') rescue nil
    st_date = @get_info.call(info, 'entry date:')&.split(':')&.last&.strip
    st_date = Date.strptime(st_date, '%m/%d/%Y') rescue nil
    data = {
      facility: get_field_value(info, 'location'),
      start_date: st_date,
      total_time: get_field_value(info, 'total length:'),
      planned_release_date: planned_release_date,
      data_source_url: @data_source_url
    }
    @hash['MississippiHoldingFacility'] = data
  end
  
  private

  def get_field_value(info, field)
    field_value = @get_info.call(info, field)
    field_value = field_value&.split(':')&.last&.strip
    field_value.presence
  end

  def get_next_table_from(item)
    loop do
      item = item.next_sibling
      return item if item.name == 'table'
    end
  end
end
