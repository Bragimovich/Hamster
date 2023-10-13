# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    super
  end

  def page(page)
    @doc = Nokogiri::HTML(page)

    self
  end

  def date_format(text)
    return unless text
    existing_format = '%m/%d/%Y' 
    existing_format = '%m/%d/%y' if text.length < 10
    date =  Date.strptime(text, existing_format) rescue nil
    
    date = date.strftime('%Y-%m-%d').to_s if date
  end

  def inmates_ids
    list = []
    @doc.css('tr.body td a.underlined').each do |a|
      link = a.attr('href')[/\((.*?)\)/, 1].gsub("'",'')
      list.push(link.split(",")) unless link.nil?
    end

    list
  end

  def current_start
    @doc.at_css('form[name=nextSearch] input[name=currentStart]').attr("value") rescue nil
  end

  def last_page
    @doc.at_css('form[name=lastSearch] input[name=currentStart]').attr("value") rescue nil
  end

  def parse_inmates
    {
      inmate: inmate,
      inmate_additional_info: inmate_additional_info,
      arrest_info: arrest_info,
      inmate_ids_additional: inmate_ids_additional,
      holding_facilities: holding_facilities,
      court_hearings: court_hearings,
      bonds: bonds,
      charges: charges,
      inmate_aliases: inmate_aliases
    }
  end

  def inmate
    full_name = @doc.at_css('font[text()="Name: "]')&.next_element&.text.strip
    name = split_name(full_name)
    name.merge({
      full_name: full_name,
      sex: td_get_text("Sex:"),
      birthdate: date_format(td_get_text("DOB:")),
      race: td_get_text("Race:"),
    })
  end

  def inmate_aliases
    tr = @doc.at_css("td[text()='Last Name']")&.parent&.next_element
    data = []
    until tr.nil?
      name = {
        first_name: tr.css('td:nth-child(1)').text&.strip,
        last_name: tr.css('td:nth-child(2)').text&.strip,
        middle_name: tr.css('td:nth-child(3)').text&.strip
      }
      name.merge!(full_name: [name[:first_name],name[:middle_name],name[:last_name]].compact.reject(&:blank?).join(" "))
      data.push(name)
      tr= tr.next_element
    end

    data
  end

  def split_name(full_name)
    name_arr = full_name.split(" ")
    first_name = name_arr.first
    middle_name = last_name = nil
    if name_arr.count > 1      
      last_name = name_arr.last
      if name_arr.count > 2
        middle_name = name_arr[1...-1].join(" ")
      end
    end
    {
    first_name: first_name,
    middle_name: middle_name,
    last_name: last_name
    }
  end

  def inmate_additional_info
    {
      height: td_get_text("Height:"),
      weight: td_get_text("Weight:"),
      hair_length: td_get_text("Hair Length:"),
      hair_color: td_get_text("Hair Color:"),
      complexion: td_get_text("Complexion:"),
      eye_color: td_get_text("Eye Color:"),
      ethnicity: td_get_text("Ethnicity:"),
      marital_status: td_get_text("Marital Status:"),
      citizen: td_get_text("Citizen:"),
      county_of_birth: td_get_text("Country of Birth:")
    }
  end

  def arrest_info
    {
      booking_number: td_get_text("Booking #:"),
      actual_booking_number: td_get_text("Permanent ID #:")
    }
  end

  def inmate_ids_additional
    {
      state_id: td_get_text("State ID:"),
      police_or_county_id: td_get_text("Police/County ID:"),
      fbi: td_get_text("FBI #:"),
      ice: td_get_text("ICE #:"),
    }
  end
  
  def holding_facilities
    {
      full_address: [td_get_text('Current Housing Section:'),td_get_text('Current Housing Block:'),td_get_text('Current Housing Cell:'),td_get_text('Current Housing Bed: '),td_get_text('County:')].compact.reject(&:blank?).join(","),
      facility_type: td_get_text('Current Location:'),
      # county: td_get_text('County:'),
      start_date: date_format(td_get_text('Commitment Date:')),
      planned_release_date: date_format(@doc.at_css("td[text()*='Release Date:']")&.next_element&.text&.strip)
    }
  end

  def court_hearings
    tr = @doc.at_css("td[text()='Comp No']")&.parent&.next_element
    data = []
    until tr.nil?
      data.push({
        case_number: tr.css('td:nth-child(1)').text&.strip,
        court_name: tr.css('td:nth-child(2)').text&.strip,
        set_by: tr.css('td:nth-child(3)').text&.strip,
        next_court_date: date_format(td_get_text("Next Court Date:"),'%m/%d/%Y %H:%M'),
        next_court_time: date_time_format(td_get_text("Next Court Date:"),'%m/%d/%Y %H:%M')
      })
      tr= tr.next_element
    end

    data
  end

  def bonds
    data = []

    td = @doc.css("td[text()='Case #:']")
    td.each_with_index do |el,n|
      data.push({
        bond_number: el.next_element&.text&.strip,
        bond_type: nil,
        bond_amount: nil,
        bond_category: nil,
        percent: nil,
        posted_by: nil,
        additional: nil,
        post_date: nil,
        bond_total: nil
      })
    end

    td = @doc.css("td[text()='Bond Type:']")
    td.each_with_index do |el,n|
      data[n][:bond_type] = el.next_element&.text&.strip
    end
    bond_selectors = [
      {selector: "td[text()='Amount:']", key: :bond_amount},
      {selector: "td[text()='Status:']", key: :bond_category},
      {selector: "td[text()='Percent:']", key: :percent},
      {selector: "td[text()='Posted By:']", key: :posted_by},
      {selector: "td[text()='Additional:']", key: :additional},
      {selector: "td[text()='Post Date:']", key: :post_date},
      {selector: "td[text()='Total:']", key: :bond_total}
    ]
    bond_selectors.each do |d|
      td = @doc.css(d[:selector])
      td.each_with_index do |el,n|
        data[n][d[:key]] = el.next_element&.text&.strip
        if d[:key] == :post_date && data[n][d[:key]].empty?
          data[n][d[:key]] = date_format(data[n][d[:key]])
        end
      end
    end
    
    data
  end

  def charges
    tr = @doc.at_css("td[text()='Case #']")&.parent&.next_element
    data = []
    until tr.nil?
      data.push({
        docker_number: tr.css('td:nth-child(1)').text&.strip,
        offense_date: tr.css('td:nth-child(2)').text&.strip,
        disposition: tr.css('td:nth-child(3)').text&.strip,
        description: tr.css('td:nth-child(4)').text&.strip,
        offense_type: tr.css('td:nth-child(5)').text&.strip,
        offense_degree: tr.css('td:nth-child(6)').text&.strip
      })
      tr= tr.next_element
    end

    data
  end

  def td_get_text(search_text)
    @doc.at_css("td[text()='#{search_text}']")&.next_element&.text&.strip
  end
  
  def valid_inmate_page?
    !@doc.at_css('td[text()="Inmate Information"]').nil?
  end
  
  def date_format(text, from = '%m/%d/%Y' )
    return unless text
    existing_format = from
    existing_format = '%m/%d/%y' if text.length < 10
    date =  Date.strptime(text, existing_format) rescue nil
    
    date = date.strftime('%Y-%m-%d').to_s if date
  end

  def date_time_format(text, from = '%m/%d/%Y %H:%M' )
    return unless text
    existing_format = from
    existing_format = '%m/%d/%y' if text.length < 10
    date =  Date.strptime(text, existing_format) rescue nil
    
    date = date.iso8601 if date
  end

end
