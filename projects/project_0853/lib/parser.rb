# frozen_string_literal: true
require_relative 'connector'
class Parser < Hamster::Parser
  def initialize
    @code_list = {
      'DR' => 'Death Row',
      'LW' => 'Life Without Parole',
      'LB' => 'Life & Barred from Parole',
      'LP' => 'Life with Parole Possible',
      'BP' => 'Barred from Parole'
    }
    @hash     = {}
    @aws_s3   = AwsS3.new(:hamster, :hamster)
    @get_info = ->(array, key) { array.select{|item| item[0].match(/#{key}/i)}.first }
    @connector = AlInmateConnector.new('http://www.doc.state.al.us')
    super
  end

  def search_form_data(response_body, letter, page)
    form_data = hidden_field_data(response_body)
    if page > 0
      form_data['ctl00$MainContent$gvInmateResults$ctl28$btnNext.x'] = rand(3..63)
      form_data['ctl00$MainContent$gvInmateResults$ctl28$btnNext.y'] = rand(2..43)
    else
      form_data['ctl00$MainContent$txtFName'] = letter
      form_data['ctl00$MainContent$btnSearch'] = 'Search'
    end
    form_data
  end

  def hidden_field_data(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    form_data = {}
    parsed_doc.xpath("//input[@type='hidden']").each do |input_tag|
      form_data[input_tag.at_xpath("./@name").value] = input_tag.at_xpath("./@value").value
    end
    form_data
  end

  def inmate_list(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    data = []
    cur_page = nil
    total_page = nil
    parsed_doc.xpath("//table/tr[not(contains(@class, 'MYTABLE'))]").each do |tr|
      if tr.xpath("./td").count != 8
        cur_page = tr.at_xpath("./td/span[1]").text
        total_page = tr.at_xpath("./td/span[2]").text
      else
        data << {
          ais: tr.at_xpath("./td[1]").text.strip,
          href: tr.at_xpath("./td[2]/a/@href").text.match(/\('(ctl.*InmateName)'.*'\)/i)[1],
          inmate_name: tr.at_xpath("./td[2]/a").text.strip,
          race: tr.at_xpath("./td[3]").text.strip,
          sex: tr.at_xpath("./td[4]").text.strip,
          birth_year: tr.at_xpath("./td[5]").text.strip,
          institution: tr.at_xpath("./td[6]").text.strip,
          release_date: tr.at_xpath("./td[7]").text.strip,
          code: tr.at_xpath("./td[8]").text
        }
      end
    end
    [data, cur_page == total_page]
  end

  def parse_detail_page(response_body, data)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    @data_source_url = "http://www.doc.state.al.us/InmateHistory?ais=#{data[:ais]}"
    @hash = {}
    mugshot_url = parsed_doc.at_xpath("//img[@id='MainContent_imgInmate']/@src").value
    alias_info = parsed_doc.xpath("//div[@class='col-lg-3 col-md-3 col-sm-6 col-xs-12'][3]/span").map{|sp| sp.text}
    additional_info = parsed_doc.xpath("//table[@id='MainContent_DetailsView1']/tr").map{|tr| [tr.at_xpath("./td[1]")&.text, tr.at_xpath("./td[2]")&.text]}
    body_modification_raw = parsed_doc.xpath("//div[@class='col-lg-3 col-md-3 col-sm-6 col-xs-12'][4]/span").map{|sp| sp.text}.join('; ')
    arrest_tags = parsed_doc.xpath("//table[@id='MainContent_gvSentence']/tr[not(contains(@style, 'color:White;background-color:#2255AA;'))]")

    inmate_data(data)
    inmate_id_data(data)
    mugshot_data(mugshot_url)
    inmate_status_data(data)
    alias_data(alias_info)
    additional_data(additional_info, body_modification_raw)
    arrest_data(arrest_tags)
    @hash.dup
  end

  def inmate_data(data)
    @full_name = data[:inmate_name]
    dob = Date.new(data[:birth_year].to_i) rescue nil
    @current_location = data[:institution].strip
    @hash['AlInmate'] = {
      data_source_url: @data_source_url,
      full_name: @full_name,
      race: data[:race],
      sex: data[:sex],
      birthdate: dob&.strftime("%Y-%m-%d")
    }
  end

  def inmate_id_data(data)
    @inmate_id = data[:ais]
    @hash['AlInmateId'] = {
      type: 'AIS',
      number: @inmate_id,
      data_source_url: @data_source_url
    }
  end

  def inmate_status_data(data)
    code = data[:code].strip.presence

    return unless code

    @hash['AlInmateStatus'] = {
      status: code_detail(code),
      date_of_status_change: Date.today&.strftime("%Y-%m-%d")
    }
  end

  def mugshot_data(mugshot_url)
    return unless mugshot_url

    org_link = "#{Scraper::HOST}/#{mugshot_url.gsub("\\","/")}"
    aws_link = upload_to_aws(org_link, @full_name, @inmate_id)
    @hash['AlMugshot'] = {
      aws_link: aws_link,
      original_link: org_link,
      data_source_url: @data_source_url
    }
  end

  def alias_data(alias_info)
    data = []
    alias_info.each do |alias_name|
      next if alias_name.include?('No known Aliases')

      data << {
        full_name: alias_name,
        data_source_url: @data_source_url
      }
    end
    @hash['AlInmateAlias'] = data
  end

  def additional_data(info, body_modification_raw)
    data = {
      height: get_field_value(info, 'height'),
      weight: get_field_value(info, 'weight'),
      hair_color: get_field_value(info, 'hair color'),
      eye_color: get_field_value(info, 'eye color'),
      current_location: @current_location,
      body_modification_raw: body_modification_raw.to_s[0..1020],
      risk_level: get_field_value(info, 'custody'),
    }
    @hash['AlInmateAdditionalInfo'] = data
  end

  def arrest_data(arrest_tags)
    @hash['AlArrest'] = []
    facility_data = nil
    ind = 1
    arrest_tags.each do |tr|
      if tr.xpath("./td").count > 10
        tds = tr.xpath("./td")
        facility_data = tds.map(&:text)
      end

      if tr.xpath("./td").count == 1
        charge_table = tr.xpath("./td/div/div/table")
        charges = charges_data(charge_table)

        @hash['AlArrest'] << {
          data_source_url: "#{@data_source_url}?ind=#{ind}##{facility_data[0]}",
          charges: charges,
          facility: holding_facility_data(facility_data)
        }
        ind += 1
      end
    end
  end

  def charges_data(charge_table)
    data = []
    charge_table_data = []
    charge_table.xpath("./tr").each do |tr|
      tr_data = []
      tr.xpath("./td").each do |td|
        tr_data << td.xpath("./span").map(&:text).join.strip
      end
      charge_table_data << tr_data
    end
    charge_table_data.each do |tr|
      next if tr.empty?

      court_date = Date.strptime(tr[1], '%m/%d/%Y')
      data << {
        'AlCharge' => {
          docket_number: tr[0].presence,
          offense_type: tr[2].presence,
          data_source_url: @data_source_url
        },
        'AlCourtAddress' => {
          county: tr[7].presence
        },
        'AlCourtHearing' => {
          court_date: court_date&.strftime("%Y-%m-%d"),
          sentence_lenght: tr[3].presence,
          sentence_type: tr[6].presence,
          case_number: tr[0].presence,
          data_source_url: @data_source_url
        },
        'AlCourtHearingsAdditional' => hearing_additional_data(tr),
      }      
    end
    data
  end

  def hearing_additional_data(tr)
    [
      {key: 'Jail Credit', value: tr[4].strip.presence, data_source_url: @data_source_url},
      {key: 'Pre Time Served', value: tr[5].strip.presence, data_source_url: @data_source_url}
    ]
  end

  def holding_facility_data(facility_data)
    start_date = Date.strptime(facility_data[1], '%m/%d/%Y') rescue nil
    release_date = Date.strptime(facility_data[7], '%m/%d/%Y') rescue nil
    {
      start_date: start_date&.strftime("%Y-%m-%d"),
      planned_release_date: release_date&.strftime("%Y-%m-%d"),
      total_time: facility_data[2],
      data_source_url: @data_source_url,
      additional_data: holding_facilities_additional(facility_data)
    }
  end

  def holding_facilities_additional(facility_data)
    [
      {key: 'Time Served', value: facility_data[3].strip.presence, data_source_url: @data_source_url},
      {key: 'Jail Credit', value: facility_data[4].strip.presence, data_source_url: @data_source_url},
      {key: 'Good Time Received', value: facility_data[5].strip.presence, data_source_url: @data_source_url},
      {key: 'Good Time Revoked', value: facility_data[6].strip.presence, data_source_url: @data_source_url},
      {key: 'Parole Consideration Date', value: facility_data[8].strip.presence, data_source_url: @data_source_url},
      {key: 'Parole Status', value: facility_data[9].strip.presence, data_source_url: @data_source_url},
    ]
  end

  private
  
  def code_detail(code)
    @code_list[code]
  end

  def get_field_value(info, field)
    field_value = @get_info.call(info, field)
    field_value[1].gsub("\r\n", "").strip.presence if field_value
  end

  def upload_to_aws(photo_url, full_name, inmate_id)
    return unless photo_url
    return if photo_url.include?('notfound.jpg')

    begin
      content  = @connector.do_connect(photo_url)
      key      = "inmates/al/#{full_name.parameterize.underscore}_#{inmate_id}.jpg"
      @aws_s3.put_file(content.body, key) if content
    rescue => e
      logger.info "------404 not found mugshot--#{photo_url}----"
      logger.info e.full_message

      return
    end
  end
end
