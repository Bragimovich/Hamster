# frozen_string_literal: true
require_relative '../lib/manager'

class Parser < Hamster::Parser

  BASE_URL = "http://www.ctinmateinfo.state.ct.us/"

  def initialize
    super
    # code to initialize object
  end

  def get_inmates_links(response)
    html = Nokogiri::HTML response.body
    html.xpath("//table[@summary='Result.']//tr")[1..-1].xpath(".//td//a//@href").map{|e| BASE_URL + e.value}
  end

  def parse_inmate(file, content, run_id)

    data_hash = {}
    id, tr = parse_tr(file, content)

    full_name = get_td_text(tr, "Inmate Name:")
    splited_names = split_name(full_name) rescue nil
    return {} if splited_names.nil?
    dob = Date.strptime( get_td_text(tr, "Date of Birth:"), '%m/%d/%Y').to_s rescue nil

    data_hash = {
      full_name: full_name,
      first_name: splited_names[:first_name],
      middle_name: splited_names[:middle_name],
      last_name: splited_names[:last_name],
      birthdate: dob,
      data_source_url: "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_inmate_ids(inmate_id, file, content, run_id)

    id = file.gsub(".gz", "").strip()
    data_hash = {}

    data_hash = {
      inmate_id: inmate_id,
      number: id,
      type: "Inmate Number",
      data_source_url: "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{id}"
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
    id, tr = parse_tr(file, content)

    data_hash = {
      inmate_id: inmate_id,
      current_location: get_td_text(tr, "Current Location:"),
      data_source_url: "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_statuses(inmate_id, file, content, run_id)

    data_hash = {}
    id, tr = parse_tr(file, content)

    data_hash = {
      inmate_id: inmate_id,
      status: get_td_text(tr, "Status:"),
      date_of_status_change: Date.today,
      data_source_url: "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parser_arrests(inmate_id, file, content, run_id)

    data_hash = {}
    id, tr = parse_tr(file, content)
    ad = Date.strptime(get_td_text(tr, "Latest Admission Date:"), '%m/%d/%Y').to_s rescue nil

    data_hash = {
      inmate_id: inmate_id,
      status: get_td_text(tr, "Status:"),
      arrest_date: ad,
      data_source_url: "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_arrests_additional(arrest_id, file, content, run_id)

    data_hash = {}
    id, tr = parse_tr(file, content)

    data_hash = {
      arrest_id: arrest_id,
      key: "Detainer",
      value: get_td_text(tr, "Detainer:"),
      data_source_url: "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_charges(arrest_id, file, content, run_id)

    data_hash = {}
    id, tr = parse_tr(file, content)

    data_hash = {
      arrest_id: arrest_id,
      crime_class: get_td_text(tr, "Controlling Offense*:"),
      data_source_url: "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_bonds(charge_id, arrest_id, file, content, run_id)

    data_hash = {}
    id, tr = parse_tr(file, content)

    data_hash = {
      arrest_id: arrest_id,
      charge_id: charge_id,
      bond_amount: get_td_text(tr, "Bond Amount:"),
      data_source_url: "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{id}"
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
    id, tr = parse_tr(file, content)

    dos = Date.strptime( get_td_text(tr, "Date of Sentence:"), '%m/%d/%Y').to_s rescue nil

    data_hash = {
      charge_id: charge_id,
      court_date: dos,
      sentence_lenght: get_td_text(tr, "Maximum Sentence:"),
      data_source_url: "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{id}"
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
    id, tr = parse_tr(file, content)

    mrd = Date.strptime( get_td_text(tr, "Maximum Release Date:"), '%m/%d/%Y').to_s rescue nil
    erd = Date.strptime( get_td_text(tr, "Estimated Release Date:"), '%m/%d/%Y').to_s rescue nil

    data_hash = {
      arrest_id: arrest_id,
      max_release_date: mrd,
      planned_release_date: erd,
      facility: get_td_text(tr, "Current Location:"),
      data_source_url: "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{id}"
    }

    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def parse_parole_booking_dates(inmate_id, file, content, run_id)

    data_hash = {}
    id, tr = parse_tr(file, content)

    date = Date.strptime( get_td_text(tr, "Special Parole End Date:"), '%m/%d/%Y').to_s rescue nil
    return {} if date.nil?
    data_hash = {
      inmate_id: inmate_id,
      date: date,
      event: "Special Parole End Date",
      data_source_url: "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{id}"
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

  def parse_tr(file, content)
    id = file.gsub(".gz", "").strip()
    data_hash = {}

    begin
        html = Nokogiri::HTML content
    rescue StandardError => e
      hamster.logger.debug e
    end

    tr = html.xpath("//table[@summary='Result.']//tr")

    return [id, tr]
  end


  def split_name(name)
    # Split the name by comma and remove leading/trailing whitespaces
    name_parts = name.split(',').map(&:strip)

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
    tr.select{|e| e.xpath("./td").text.include? title}.first.xpath(".//td")[1].text.squish rescue nil
  end


  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| value.to_s.empty? || value == 'null' ? nil : value }
  end

end

