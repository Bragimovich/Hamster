# frozen_string_literal: true
class Parser <  Hamster::Scraper

  DOMAIN = "https://linxonline.co.pierce.wa.us"

  def get_links(page)
    page.css("tbody")[2].css("a").map{ |a| a["href"]}
  end

  def parse_html(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def get_inner_links(get_page)
    name_link = get_page.css("table")[2].css("a")[0]["href"] rescue nil
    charge_links = get_page.css("table")[3].css("a").select{ |a| a["href"].include? "charge"}.map{ |a| a["href"]} rescue nil
    [name_link, charge_links]
  end

  def get_arrests_info(page, booking_id, link, run_id, inmate_id)
    array = page.css("table")[2].css("tr").map { |a| a.css("td")[1].text.squish}
    data_hash = {}
    data_hash[:immate_id]      = inmate_id
    data_hash[:booking_number] = booking_id
    data_hash[:booking_agency] = array[-1]
    data_hash[:booking_date]   = get_datetime(array[1].split.first, array[1].split.last)
    data_hash[:status]         = array[2].empty? ? "In custody" : "Not in custody"
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.update(additional_columns(data_hash, run_id, link))
    data_hash
  end

  def get_inmates_info(page, name_page, link, run_id)
    array = page.css("table")[2].css("tr").map { |a| a.css("td")[1].text.squish}
    data_hash = {}
    data_hash[:full_name]      = array[0]
    data_hash.update(name_spliting(name_page.css("h1").text.squish))
    data_hash[:race]           = array[3]
    data_hash[:sex]            = array[5]
    data_hash[:ethnicity]      = array[4]
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.update(additional_columns(data_hash, run_id, link))
    data_hash
  end

  def charges_info(charge_page, inner_page, charge_link, link, run_id, index, arrest_id)
    data_hash = {}
    data_hash[:arrest_id]     = arrest_id
    data_hash[:number]        = inner_page.css("table")[3].css("tr")[(index*2)+(index-1)].css("td")[1].text
    data_hash[:counts]        = inner_page.css("table")[3].css("tr")[(index*2)+(index-1)-1].css("td")[0].text
    data_hash[:description]   = charge_page.css("table")[2].css("tr")[1].text.split(":").last.squish rescue nil
    return nil if data_hash[:description].nil?
    data_hash[:offense_type]  = charge_page.css("table")[2].css("tr")[2].text.split(":").last.squish
    data_hash[:docket_number] = inner_page.css("table")[3].css("tr")[(index*2)+(index-1)].css("td")[3].text
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.update(additional_columns(data_hash, run_id, link))
    data_hash
  end

  def bonds(inner_page, link, run_id, index, arrest_id, charges_id)
    data_hash = {}
    data_hash[:arrest_id]    = arrest_id
    data_hash[:charge_id]    = charges_id
    data_hash[:bond_amount]  = (inner_page.css("table")[3].css("tr")[(index*2)+(index-1)].css("td")[6].text.include? "$") ? inner_page.css("table")[3].css("tr")[(index*2)+(index-1)].css("td")[6].text.split.first : nil
    data_hash[:bond_type]    = inner_page.css("table")[3].css("tr")[(index*2)+(index-1)].css("td")[6].text.split(data_hash[:bond_amount]).last.squish rescue nil
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.update(additional_columns(data_hash, run_id, link))
    data_hash
  end

  def holding_facilities(inner_page, link, run_id, index, arrest_id)
    data_hash = {}
    data_hash[:arrest_id]            = arrest_id
    data_hash[:planned_release_date] = DateTime.strptime(inner_page.css("table")[2].css("tr").map { |a| a.css("td")[1].text.squish}[2], "%m/%d/%Y").to_date rescue nil
    data_hash[:actual_release_date]  = data_hash[:planned_release_date]
    data_hash[:facility]             = inner_page.css("table")[3].css("tr")[(index*2)+(index-1)-1].css("td")[3].text
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.update(additional_columns(data_hash, run_id, link))
    data_hash
  end

  def court_hearings(charge_page, inner_page, charge_link, link, run_id, index, charges_id)
    data_hash = {}
    data_hash[:charge_id]   = charges_id
    data_hash[:court_name]  = charge_page.css("table")[2].css("tr")[3..4].map { |a| a.text.squish}.join("\n")
    data_hash[:case_number] = inner_page.css("table")[3].css("tr")[(index*2)+(index-1)].css("td")[4].text.squish
    data_hash[:court_date]  = inner_page.css("table")[3].css("tr")[(index*2)+(index-1)-1].css("td")[5].text.squish
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.update(additional_columns(data_hash, run_id, link))
    data_hash
  end

  private

  def get_datetime(date, time)
    date = time = nil if date.nil?
    return nil if date.nil? || time.nil?
    time =  time.nil? ? "12:00" : time
    formatted_date = date.include?("/") ? DateTime.strptime(date, '%m/%d/%Y').strftime('%Y-%m-%d') : date
    datetime = DateTime.parse("#{formatted_date} #{time}")
    sql_datetime = datetime.strftime('%Y-%m-%d %H:%M:%S')
    sql_datetime
  end

  def name_spliting(name)
    data_hash = {}
    name_parts = name.split(" ")
    if name_parts.length == 3
      data_hash[:first_name]   = name_parts[0]
      data_hash[:middle_name]  = name_parts[1]
      data_hash[:last_name]    = name_parts[2]
    elsif name_parts.length == 2
      data_hash[:first_name]   = name_parts[0]
      data_hash[:middle_name]  = nil
      data_hash[:last_name]    = name_parts[1]
    elsif name_parts.length > 3
      data_hash[:first_name]   = name_parts[0]
      data_hash[:middle_name]  = name_parts[1]
      data_hash[:last_name]    = name_parts[2..-1].join(' ')
    else
      data_hash[:first_name]   = name_parts[0] rescue nil
      data_hash[:middle_name]  = nil
      data_hash[:last_name]    = nil
    end
    remove_charachters(data_hash)
  end

  def additional_columns(case_information, run_id, link)
    info = {}
    info[:md5_hash]          = create_md5_hash(case_information)
    info[:data_source_url]   = DOMAIN + link
    info[:run_id]            = run_id
    info[:touched_run_id]    = run_id
    info
  end

  def remove_charachters(data_hash)
    data_hash.transform_values{|value| value.to_s.gsub(",", "")}
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == "null") ? nil : value}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
  end
end
