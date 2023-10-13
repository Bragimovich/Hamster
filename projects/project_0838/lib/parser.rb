# frozen_string_literal: true
require_relative '../lib/manager'

class Parser < Hamster::Parser

  BASE_URL = "https://jimspub.riversidesheriff.org"

  def initialize
    super
    # code to initialize object
  end

  def get_inmates_links(response)
    html = Nokogiri::HTML response
    html.xpath("//table//tr")[2..-1].xpath(".//td//a//@href").map{|e| BASE_URL + e.value.gsub("..","")}
  end
  def get_inmates_table(content_page)
    html = Nokogiri::HTML content_page
    html.xpath("//table//tr")[5..-1]
  end

  def get_id(tr)
    tr.xpath("./td")[0].text.strip()
  end

  def parse_inmate_statuses(inmate_id, tr, run_id)
    data_hash = {}

    id = tr.xpath("./td")[0].text.strip()
    status = tr.xpath("./td")[-1].text.strip()

    if status == 'Y'
      status = 'In Custody'
    elsif status == 'N'
      status = 'Not In Custody'
    end

    data_hash = {
      inmate_id: inmate_id,
      status: status,
      date_of_status_change: Date.today,
      data_source_url: "https://jimspub.riversidesheriff.org/cgi-bin/iisinfo.acu?bkno=#{id}G"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_inmate(content, file, run_id)

    data_hash = {}
    id, html = parse_html(file, content)

    name = html.xpath("//td[b[text()='Name']]/following-sibling::td[1]").text rescue nil
    return {} if name.nil?
    splited_names = split_name(name)
    sex = html.xpath("//td[b[text()='Sex']]/parent::tr/following-sibling::tr[1]/td[1]").text
    race = html.xpath("//td[b[text()='Race']]/parent::tr/following-sibling::tr[1]/td[2]").text
    dob =  Date.strptime(html.xpath("//td[b[text()='DOB']]/parent::tr/following-sibling::tr[1]/td[3]").text, '%m/%d/%Y').to_s rescue nil

    data_hash = {
      full_name: name,
      first_name: splited_names[:first_name],
      middle_name: splited_names[:middle_name],
      last_name: splited_names[:last_name],
      sex: sex,
      race: race,
      birthdate: dob,
      data_source_url: "https://jimspub.riversidesheriff.org/cgi-bin/iisinfo.acu?bkno=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_inmate_additional_info(inmate_id, file, content, run_id)

    data_hash = {}
    id, html = parse_html(file, content)

    height = html.xpath("//td[b[text()='Height']]/parent::tr/following-sibling::tr[1]/td[4]").text
    weight = html.xpath("//td[b[text()='Weight']]/parent::tr/following-sibling::tr[1]/td[5]").text
    hair_color = html.xpath("//td[b[text()='Hair']]/parent::tr/following-sibling::tr[1]/td[2]").text
    eye_color = html.xpath("//td[b[text()='Eyes']]/parent::tr/following-sibling::tr[1]/td[3]").text
    current_location = html.xpath("//td[b[text()='Current Facility']]/following-sibling::td[1]").text

    data_hash = {
      inmate_id: inmate_id,
      height: height,
      weight: weight,
      hair_color: hair_color,
      eye_color: eye_color,
      current_location: current_location,
      data_source_url: "https://jimspub.riversidesheriff.org/cgi-bin/iisinfo.acu?bkno=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end


  def parse_inmate_arrests(inmate_id, file, content, run_id)

    data_hash = {}
    id, html = parse_html(file, content)
    ad = DateTime.strptime(html.xpath("//td[b[text()='Arrest Date/Time']]/parent::tr/following-sibling::tr[1]/td[1]").text,"%d/%m/%Y %H:%M") rescue nil
    bd = DateTime.strptime(html.xpath("//td[b[text()='Booked Date/Time']]/parent::tr/following-sibling::tr[1]/td[1]").text,"%d/%m/%Y %H:%M") rescue nil
    ba = html.xpath("//td[b[text()='Arresting Agency']]/parent::tr/following-sibling::tr[1]/td[2]").text

    data_hash = {
      inmate_id: inmate_id,
      booking_number: id,
      arrest_date: ad,
      booking_date: bd,
      booking_agency: ba,
      data_source_url: "https://jimspub.riversidesheriff.org/cgi-bin/iisinfo.acu?bkno=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_inmate_arrests_additional(arrest_id, file, content, run_id)

    data_array = []
    id, html = parse_html(file, content)

    for i in 1..2
      data_hash = {}
      if i == 1
        al = html.xpath("//td[b[text()='Arresting Location']]/parent::tr/following-sibling::tr[1]/td[3]").text
        next if al == ""
        data_hash = {
          arrest_id: arrest_id,
          key: "Arresting Location",
          value: al,
          data_source_url: "https://jimspub.riversidesheriff.org/cgi-bin/iisinfo.acu?bkno=#{id}"
        }
      else
        cn = html.xpath("//td[b[text()='Case No.']]/parent::tr/following-sibling::tr[1]/td[2]").text
        next if cn == ""
        data_hash = {
          arrest_id: arrest_id,
          key: "Case No.",
          value: cn,
          data_source_url: "https://jimspub.riversidesheriff.org/cgi-bin/iisinfo.acu?bkno=#{id}"
        }
      end

      data_hash = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_array << data_hash
    end
    data_array
  end

  def parse_charges(arrest_id, file, content, run_id)

    data_hash = {}
    id, html = parse_html(file, content)
    table = html.xpath("//td[contains(., 'Charges')]/following::table[1]")
    data_array = []
    table.xpath(".//tr")[1..-1].each do |tr|
      desc = tr.xpath(".//td[3]").text.force_encoding('ISO-8859-1').encode('UTF-8')
      data_hash = {}
      data_hash = {
        arrest_id: arrest_id,
        description: desc,
        disposition: tr.xpath(".//td[5]").text,
        offense_type: tr.xpath(".//td[2]").text,
        crime_class: tr.xpath(".//td[1]").text,
        data_source_url: "https://jimspub.riversidesheriff.org/cgi-bin/iisinfo.acu?bkno=#{id}"
      }

      data_hash = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_array << data_hash
    end
    data_array
  end

  def parse_charges_additional(charge_id, file, content, run_id, ind)

    data_hash = {}
    id, html = parse_html(file, content)
    table = html.xpath("//td[contains(., 'Charges')]/following::table[1]")
    val = table.xpath(".//tr")[ind+1].xpath(".//td[6]").text
    data_hash = {}
    data_hash = {
      charge_id: charge_id,
      key: "Booking Type",
      value: val,
      data_source_url: "https://jimspub.riversidesheriff.org/cgi-bin/iisinfo.acu?bkno=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_bonds(charge_id, arrest_id, file, content, run_id, ind)

    data_hash = {}
    id, html = parse_html(file, content)
    table = html.xpath("//td[contains(., 'Charges')]/following::table[1]")
    val = table.xpath(".//tr")[ind+1].xpath(".//td[4]").text

    data_hash = {
      arrest_id: arrest_id,
      charge_id: charge_id,
      bond_type: "Bail",
      bond_amount: val,
      data_source_url: "https://jimspub.riversidesheriff.org/cgi-bin/iisinfo.acu?bkno=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_court_hearings(charge_id, file, content, run_id)

    data_hash = {}
    id, html = parse_html(file, content)
    datetime = html.xpath("//td[contains(., 'Next Court')]/parent::tr/following-sibling::tr[1]/td[1]").text.gsub("Charges","")

    doc = Date.strptime(datetime.split(" ").first, '%m/%d/%Y').to_s rescue nil
    next_court_time = datetime.split(" ").last

    data_hash = {
      charge_id: charge_id,
      court_name: html.xpath("//td[b[text()='Court Name']]/parent::tr/following-sibling::tr[1]/td[2]").text,
      next_court_date: doc,
      next_court_time: next_court_time,
      data_source_url: "https://jimspub.riversidesheriff.org/cgi-bin/iisinfo.acu?bkno=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_holding_facilities(arrest_id, file, content, run_id)

    data_hash = {}
    id, html = parse_html(file, content)

    ard = Date.strptime(html.xpath("//td[b[text()='Release Date']]/parent::tr/following-sibling::tr[1]/td[3]").text, '%m/%d/%Y').to_s rescue nil


    data_hash = {
      arrest_id: arrest_id,
      actual_release_date: ard,
      facility: html.xpath("//td[b[text()='Current Facility']]/following-sibling::td[1]").text,
      data_source_url: "https://jimspub.riversidesheriff.org/cgi-bin/iisinfo.acu?bkno=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_holding_facilities_additional(holding_facility_id, file, content, run_id)

    data_hash = {}
    id, html = parse_html(file, content)
    val = html.xpath("//td[b[text()='Housing Unit']]/following-sibling::td[1]").text

    return {} if val == ""
    data_hash = {
      holding_facility_id: holding_facility_id,
      key: "Housing Unit",
      value: val,
      data_source_url: "https://jimspub.riversidesheriff.org/cgi-bin/iisinfo.acu?bkno=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end


  private

  def parse_html(file, content)
    id = file.gsub(".gz", "").strip()

    begin
        html = Nokogiri::HTML content
    rescue StandardError => e
      hamster.logger.debug e
    end
    return [id, html]
  end


  def split_name(name)
    # Split the name by comma and remove leading/trailing whitespaces
    name_parts = name.split(',').map(&:strip) rescue nil
    
    if name_parts.nil?
      return {
        first_name: nil,
        middle_name: nil,
        last_name: nil
      }
    end

    # Extract the last name from the first part
    last_name = name_parts.first

    # Extract the first name and middle name from the second part
    first_name, middle_name = name_parts.last.split(' ')

    # Return the split name as a hash
    {
      first_name: first_name,
      middle_name: middle_name,
      last_name: last_name
    }
  end


  def get_td_text(tr, title)
    td = tr.select{|e| e.xpath("./td").text.include? title}.first
    td.xpath(".//td")[1].text.squish
  end


  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| value.to_s.empty? || value == 'null' ? nil : value }
  end

end

