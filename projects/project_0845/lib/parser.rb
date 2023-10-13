# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    @hash = nil
    @data_source_url = nil
    @get_info = ->(array, key) { array.select{|item| item[0]&.match(/#{key}/i)}&.first }
    super
  end

  def invalid_captcha?(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    alert = parsed_doc.at_xpath("//div[@class='alert alert-danger']")&.text

    return false unless alert

    alert.match(/Invalid Captcha/i)
  end

  def inmate_ids(response_body)
    data = []
    parsed_doc = Nokogiri::HTML.parse(response_body)
    parsed_doc.xpath("//table/tbody/tr").each do |tr|
      data << {
        href: tr.at_xpath("./td[1]/a/@href").text,
        booking_number: tr.at_xpath("./td[1]").text,
        booking_name: tr.at_xpath("./td[2]").text,
        race: tr.at_xpath("./td[3]").text,
        sex: tr.at_xpath("./td[4]").text,
        dob: tr.at_xpath("./td[5]").text,
        arrest_date: tr.at_xpath("./td[6]").text,
        booking_date: tr.at_xpath("./td[7]").text,
        release_date: tr.at_xpath("./td[8]").text,
        release_code: tr.at_xpath("./td[9]").text,
        release_remarks: tr.at_xpath("./td[10]").text
      }
    end
    data
  end

  def parse_detail_page(response_body, data_source_url, scraper, data)
    @hash = {}
    @data_source_url = data_source_url
    parsed_doc = Nokogiri::HTML.parse(response_body)
    mubgshot_url = parsed_doc.at_xpath("//div[@id='mugShot']/div/div[1]/div/img/@src").value
    inmate_row_data = []
    parsed_doc.xpath("//div[@id='mugShot']/div/div[2]/div[@class='row']/div").each do |row|
      inmate_row_data << row.text.split(":")
    end
    arrest_status_tag = parsed_doc.xpath("//div[@class='default-hcso-bg bordered pt-4 pb-4 pr-4 pl-4']")[0]
    address_tag       = parsed_doc.xpath("//div[@class='default-hcso-bg bordered pt-4 pb-4 pr-4 pl-4']")[1]
    alias_array       = parsed_doc.xpath("//table/tbody/tr").map{|tr| tr.xpath("./td").map(&:text)}
    arrest_tag        = parsed_doc.xpath("//div[@class='default-hcso-bg bordered pt-4 pb-4 pr-4 pl-4']")[2]
    charge_tags       = parsed_doc.xpath("//div[@class='default-hcso-bg bordered pt-4 pb-4 pr-4 pl-4 mb-5']")
    inmate_data(data)
    inmate_id_data(inmate_row_data)
    mugshot_data(mubgshot_url, scraper)
    additional_data(inmate_row_data)
    arrest_data(arrest_status_tag, inmate_row_data, arrest_tag)
    address_data(address_tag)
    alias_data(alias_array)
    charge_data(charge_tags)
    @hash.dup
  end

  def inmate_data(data)
    logger.debug "PARSED=======#{data[:booking_number]}=======#{data[:booking_name]}"
    @full_name = data[:booking_name]
    @release_date = Date.strptime(data[:release_date], '%m/%d/%Y') rescue nil
    dob = Date.strptime(data[:dob], '%m/%d/%Y') rescue nil
    @bk_date = Date.strptime(data[:booking_date], '%m/%d/%Y') rescue nil
    @hash['FlHillsboroughInmate'] = {
      data_source_url: @data_source_url,
      full_name: @full_name,
      race: data[:race],
      sex: data[:sex],
      birthdate: dob
    }
  end

  def mugshot_data(mubgshot_url, scraper)
    org_link = nil
    aws_link = nil
    if mubgshot_url
      org_link = mubgshot_url.match(/(\/ArrestInquiry.*)&k1=/)[1]
      org_link = "#{Scraper::HOST}#{org_link}"
      real_link = "#{Scraper::HOST}#{mubgshot_url}"
      aws_link = scraper.upload_to_aws(real_link, @full_name, @inmate_id)
    end    
    @hash['FlHillsboroughMugshot'] = {
      aws_link: aws_link,
      original_link: org_link,
      data_source_url: @data_source_url
    }
  end

  def inmate_id_data(inmate_row_data)
    soid = @get_info.call(inmate_row_data, 'soid')
    @inmate_id = soid[1].match(/(\d+)/)[1]
    @hash['FlHillsboroughInmateId'] = {
      type: 'SOID',
      number: @inmate_id,
      data_source_url: @data_source_url
    }
  end

  def additional_data(inmate_row_data)
    height = @get_info.call(inmate_row_data, 'height')
    @hash['FlHillsboroughInmateAdditionalInfo'] = {
      height: get_field_value(inmate_row_data, 'height'),
      weight: get_field_value(inmate_row_data, 'weight'),
      hair_color: get_field_value(inmate_row_data, 'hair'),
      eye_color: get_field_value(inmate_row_data, 'eye'),
      age: get_field_value(inmate_row_data, 'age'),
      ethnicity: get_field_value(inmate_row_data, 'ethnicity'),
      complexion: get_field_value(inmate_row_data, 'build'),
      data_source_url: @data_source_url
    }
  end

  def arrest_data(arrest_status_tag, inmate_row_data, arrest_tag)
    ar_date = get_field_value(inmate_row_data, 'arrest date')
    ar_date = Date.strptime(ar_date, '%m/%d/%Y') rescue nil
    arrest_status_row_data = arrest_status_tag.xpath("./div/div").map{|col| col.text.split(':')}
    status = get_field_value(arrest_status_row_data, 'status').split(" - ").last.gsub('*', '')
    @bond = get_field_value(arrest_status_row_data, 'bond')
    facility = get_field_value(arrest_status_row_data, 'facility')
    arrest_row_data = arrest_tag.xpath("./div/div").map{|col| col.text.split(':')}
    booking_agency = get_field_value(arrest_row_data, 'arrest agency')
    book_date = get_field_value(arrest_row_data, 'book date')
    @hash['FlHillsboroughArrest'] = {
      status: status,
      arrest_date: ar_date,
      booking_number: get_field_value(inmate_row_data, 'booking number'),
      booking_date: @bk_date,
      booking_agency: booking_agency,
      data_source_url: @data_source_url
    }
    if facility || @release_date
      @hash['FlHillsboroughHoldingFacility'] = {
        facility: get_field_value(arrest_status_row_data, 'facility'),
        actual_release_date: @release_date,
        data_source_url: @data_source_url
      }
    end
  end

  def address_data(address_tag)
    address_row_data = address_tag.xpath("./div/div").map{|col| col.text.split(':')}
    @hash['FlHillsboroughInmateAddresses'] = {
      street_address: get_field_value(address_row_data, 'street'),
      city: get_field_value(address_row_data, 'city'),
      state: get_field_value(address_row_data, 'state'),
      zip: get_field_value(address_row_data, 'zip'),
      data_source_url: @data_source_url
    }
  end

  def alias_data(alias_array)
    @hash['FlHillsboroughInmateAlias'] = []
    alias_array.each do |alias_name|
      full_name = alias_name[0].strip
      @hash['FlHillsboroughInmateAlias'] << {
        full_name: full_name,
        data_source_url: @data_source_url
      }
    end
  end

  def charge_data(charge_tags)
    @hash['FlHillsboroughCharge'] = []
    charge_tags.each_with_index do |charge_tag, ind|
      charge_row_data = charge_tag.xpath("./div").map{|col| [col.at_xpath("./div[1]/label")&.text, col.at_xpath("./div[2]")&.text || col.at_xpath("./div[1]/p")&.text]}
      offense_date = get_field_value(charge_row_data, 'offense date')
      offense_date = Date.strptime(offense_date, '%m/%d/%Y') rescue nil
      @arrest_agency = @arrest_agency || get_field_value(charge_row_data, 'agency:')
      @hash['FlHillsboroughCharge'] << {
        disposition: get_field_value(charge_row_data, 'disp:'),
        description: "Charge ##{ind+1}: #{get_field_value(charge_row_data, 'description')}",
        offense_type: get_field_value(charge_row_data, 'charge type:'),
        offense_date: offense_date,
        docket_number: get_field_value(charge_row_data, 'report number'),
        crime_class: get_field_value(charge_row_data, 'class:'),
        counts: get_field_value(charge_row_data, 'charge count:'),
        data_source_url: @data_source_url,
        court_hearing_data: {
          court_name: get_field_value(charge_row_data, 'court:'),
          case_number: get_field_value(charge_row_data, 'ct-case:'),
          data_source_url: @data_source_url
        },
        bond_data: {
          bond_amount: get_field_value(charge_row_data, 'bond:'),
          data_source_url: @data_source_url
        },
        additional_data: charge_additional_data(charge_row_data)
      }
    end
    @hash['FlHillsboroughArrest'][:booking_agency] = @arrest_agency
  end

  def charge_additional_data(charge_row_data)
    data = []
    keys = %w[BP Fine Custody\ Days OBTS\ Number Charge\ Code CRA\ Number Remark]
    keys.each do |k|
      if get_field_value(charge_row_data, k).presence
        data << {
          key: k,
          value: get_field_value(charge_row_data, k).split(' ').join(' ')[0..250],
          data_source_url: @data_source_url
        }
      end
    end
    data
  end

  private

  def get_field_value(array, field)
    field_value = @get_info.call(array, field)
    field_value[1]&.strip&.presence if field_value
  end
end
