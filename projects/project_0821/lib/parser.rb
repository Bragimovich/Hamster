# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    @hash = nil
    @data_source_url = nil
    @get_info = ->(array, key) { array.select{|item| item[0].match(/#{key}/i)}&.first[1] }
    super
  end

  def search_form_data(response_body, last_name)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    data = {}
    parsed_doc.xpath("//input").each do |item|
      key = item.xpath("./@name").text
      val = item.xpath("./@value").text

      val = last_name if key == 'LName'
      next if val == 'Clear'

      data[key] = val
    end
    data
  end

  def inmate_ids(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    parsed_doc.xpath("//tr[@class='rowHover']/td[2]").map(&:text)
  end

  def parse_detail_page(response_body, data_source_url, scraper)
    @hash = {}
    @data_source_url = data_source_url
    parsed_doc = Nokogiri::HTML.parse(response_body)
    user_info_div = parsed_doc.xpath("//div[@id='DivFirstInfo']")
    user_info_table = user_info_div.at_xpath("./table/tr/td/table")
    user_info_arr = user_info_table.xpath("./tr").map{|tr| tr.xpath("./td/span").map(&:text)}
    photo_url = user_info_div.at_xpath("./table/tr/td/img[@id='criminalpix']/@src").value
    inmate_data(user_info_arr)
    inmate_id_data(user_info_arr)
    additional_data(user_info_arr)
    arrest_data(user_info_arr)
    mugshot_data(photo_url, scraper)
    table_data = parsed_doc.xpath("//table[@id='GridDetails']/tr").map{|tr| tr.xpath("./td").map(&:text)}
    parse_table_data(table_data)
    @hash.dup
  end

  def inmate_data(user_info_arr)
    @full_name = @get_info.call(user_info_arr, 'name')
    @hash['TxFortBendInmate'] = {
      data_source_url: @data_source_url,
      full_name: @full_name,
      last_name: @full_name.split(',').first,
      first_name: @full_name.split(',').last,
      race: @get_info.call(user_info_arr, 'race'),
      sex: @get_info.call(user_info_arr, 'sex')
    }
  end

  def inmate_id_data(user_info_arr)
    @inmate_id = @get_info.call(user_info_arr, 'jail')
    @hash['TxFortBendInmateId'] = {
      type: 'JAIL ID',
      number: @inmate_id,
      data_source_url: @data_source_url
    }
  end

  def additional_data(user_info_arr)
    @hash['TxFortBendInmateAdditionalInfo'] = {
      age: @get_info.call(user_info_arr, 'age'),
      data_source_url: @data_source_url
    }
  end

  def arrest_data(user_info_arr)
    ar_date = Date.strptime(@get_info.call(user_info_arr, 'arrest'), '%m/%d/%Y') rescue nil
    bk_date = DateTime.strptime(@get_info.call(user_info_arr, 'booking'), '%m/%d/%Y %H:%M %P') rescue nil
    @hash['TxFortBendArrest'] = {
      arrest_date: ar_date,
      booking_date: bk_date,
      data_source_url: @data_source_url
    }
  end

  def mugshot_data(photo_url, scraper)
    aws_link = scraper.upload_to_aws(photo_url, @full_name, @inmate_id)
    data = {
      aws_link: aws_link,
      original_link: photo_url,
      data_source_url: @data_source_url
    }
    @hash['TxFortBendMugshot'] = data
  end

  def parse_table_data(table_data)
    @hash['TxFortBendCharge'] = []
    booking_agency = nil
    table_data.each do |item|
      next if item.empty?

      disposition_date = Date.strptime(item[9].presence, '%m/%d/%Y') rescue nil
      @hash['TxFortBendCharge'] << {
        data_source_url: @data_source_url,
        docket_number: item[2].presence,
        offense_type: item[3].presence,
        description: item[4].presence,
        disposition: nil,
        disposition_date: disposition_date,
        additional: {
          authority: item[1].presence,
          lvl: item[5].presence,
          fines: item[8].presence
        },
        bond: {
          data_source_url: @data_source_url,
          bond_type: item[6].presence,
          bond_amount: item[7].presence
        }
      }
      booking_agency = item[0].presence
    end
    @hash['TxFortBendArrest'][:booking_agency] = booking_agency
  end
end
