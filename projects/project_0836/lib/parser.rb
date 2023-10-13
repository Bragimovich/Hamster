# frozen_string_literal: true

class Parser < Hamster::Parser

  def initialize
    super
    @aws_s3 = AwsS3.new(bucket_key = :hamster, account = :hamster)
  end

  def initialize_values(page_body, run_id)
    @run_id = run_id
    @page = parse_page(page_body)
    @result_divs = page.css('#resultspage div').reject{ |e| e['id'].nil? }.select{ |e| e['id'].include? 'allresults' }
  end

  def get_xisi_value(response)
    page = parse_page(response.body)
    page.css('#xisi').first['value']
  end

  def parse_inmates_data
    data_array = []
    md5_array = []
    result_divs.each do |div|
      headers = div.css('strong')
      data_hash = {}
      full_name                               = get_value(headers, 'name')
      first_name,middle_name,last_name,suffix = name_split(full_name)
      data_hash[:full_name]                   = full_name
      data_hash[:first_name]                  = first_name
      data_hash[:middle_name]                 = middle_name
      data_hash[:last_name]                   = last_name
      data_hash[:suffix]                      = suffix
      data_hash[:race]                        = get_value(headers, 'race')
      data_hash[:birthdate]                   = get_date_required_format(get_value(headers, 'dob'))
      data_hash[:sex]                         = get_value(headers, 'gender')
      data_hash[:md5_hash]                    = create_md5_hash(data_hash)
      data_hash[:run_id]                      = run_id
      data_hash[:touched_run_id]              = run_id
      data_hash[:data_source_url]             = 'https://www3.pbso.org/blotter/index.cfm'
      data_hash                               = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  def parse_mugshots(db_inmate_ids)
    data_array = []
    md5_array = []
    result_divs.each_with_index do |div,div_index|
      image_url = div.css('#person').first['src']
      next unless image_url.include? 'data'
      decoded_image = decode_base64_image(image_url)
      file_name = Digest::MD5.hexdigest image_url
      aws_link = upload_image_to_aws(decoded_image, file_name)
      data_hash = {}
      data_hash[:inmate_id]       = db_inmate_ids[div_index]
      data_hash[:aws_link]        = aws_link
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash[:run_id]          = run_id
      data_hash[:touched_run_id]  = run_id
      data_hash[:data_source_url] = 'https://www3.pbso.org/blotter/index.cfm'
      data_hash                   = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  def parse_inmates_id_data(db_inmate_ids)
    data_array = []
    md5_array = []
    result_divs.each_with_index do |div,div_index|
      headers = div.css('strong')
      data_hash = {}
      data_hash[:inmate_id]       = db_inmate_ids[div_index]
      data_hash[:number]          = get_value(headers, 'jacket number')
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash[:run_id]          = run_id
      data_hash[:touched_run_id]  = run_id
      data_hash[:data_source_url] = 'https://www3.pbso.org/blotter/index.cfm'
      data_hash                   = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  def parse_address_data(db_inmate_ids)
    data_array = []
    md5_array = []
    result_divs.each_with_index do |div,div_index|
      headers = div.css('strong')
      data_hash = {}
      data_hash[:inmate_id]         = db_inmate_ids[div_index]
      data_hash[:full_address]      = get_value(headers, 'address')
      data_hash[:md5_hash]          = create_md5_hash(data_hash)
      data_hash[:run_id]            = run_id
      data_hash[:touched_run_id]    = run_id
      data_hash[:data_source_url]   = 'https://www3.pbso.org/blotter/index.cfm'
      data_hash                     = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  def parse_facility_data(db_arrest_ids)
    data_array = []
    md5_array = []
    result_divs.each do |div|
      headers = div.css('strong')
      release_date = get_value(headers, 'release date')
      required_date = release_date.scan(/\d{2}\/\d{2}\/\d{2}/)
      data_hash = {}
      data_hash[:facility]            = get_value(headers, 'facility')
      data_hash[:facility_type]       = get_value(headers, 'facility')
      data_hash[:actual_release_date] = (required_date.empty?) ? release_date : get_date_required_format(required_date.first)
      data_hash[:md5_hash]            = create_md5_hash(data_hash)
      data_hash[:run_id]              = run_id
      data_hash[:touched_run_id]      = run_id
      data_hash[:data_source_url]     = 'https://www3.pbso.org/blotter/index.cfm'
      data_hash                       = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    grouped_arrest_array = get_grouped_array(db_arrest_ids)
    data_array = get_facilty_array(data_array, grouped_arrest_array)
    [data_array,md5_array]
  end

  def parse_arrests_data(db_inmate_ids)
    data_array = []
    md5_array = []
    result_divs.each_with_index do |div,div_index|
      headers = div.css('strong')
      booking_agency = get_value(headers, 'arresting agency')
      inner_divs = div.css('> div').select{ |e| e['class'].nil? }
      inner_divs.each do |inner_div|
        inner_headers = inner_div.css('strong')
        data_hash = {}
        data_hash[:inmate_id]       = db_inmate_ids[div_index]
        data_hash[:booking_agency]  = booking_agency 
        data_hash[:arrest_date]     = get_value(inner_headers, 'booking date')
        data_hash[:booking_number]  = get_value(inner_headers, 'booking number')
        data_hash[:md5_hash]        = create_md5_hash(data_hash)
        data_hash[:run_id]          = run_id
        data_hash[:touched_run_id]  = run_id
        data_hash[:data_source_url] = 'https://www3.pbso.org/blotter/index.cfm'
        data_hash                   = mark_empty_as_nil(data_hash)
        data_array << data_hash
        md5_array << data_hash[:md5_hash]
      end
    end
    [data_array,md5_array]
  end

  def parse_additional_obts(db_inmate_ids)
    data_array = []
    md5_array = []
    result_divs.each_with_index do |div,div_index|
      headers = div.css('strong')
      data_hash = {}
      data_hash[:inmate_id]       = db_inmate_ids[div_index]
      data_hash[:key]             = 'obts_number'
      data_hash[:value]           = get_value(headers, 'obts number')
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash[:run_id]          = run_id
      data_hash[:touched_run_id]  = run_id
      data_hash[:data_source_url] = 'https://www3.pbso.org/blotter/index.cfm'
      data_hash                   = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  def parse_additional_agencies(db_inmate_ids)
    data_array = []
    md5_array = []
    result_divs.each_with_index do |div,div_index|
      headers = div.css('strong')
      data_hash = {}
      data_hash[:inmate_id]       = db_inmate_ids[div_index]
      data_hash[:key]             = 'holds_for_other_agencies'
      data_hash[:value]           = get_value(headers, 'holds for other agencies')
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash[:run_id]          = run_id
      data_hash[:touched_run_id]  = run_id
      data_hash[:data_source_url] = 'https://www3.pbso.org/blotter/index.cfm'
      data_hash                   = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  def parse_charges_data(db_arrest_ids)
    charges_array = []
    data_array = []
    md5_array = []
    result_divs.each do |div|
      inner_divs = div.css('> div').select{ |e| e['class'].nil? }
      inner_divs.each do |inner_div|
        charges_divs = inner_div.css('div').reject{ |e| e['style'].nil? }.select{ |e| e['style'].include? '#CCC' }
        charges_divs.each do |charge_div|
          data_hash = {}
          data_hash[:offence_type]    = charge_div.css('div').first.text.to_s.squish
          data_hash[:name]            = charge_div.css('div').last.text.to_s.squish
          data_hash[:md5_hash]        = create_md5_hash(data_hash)
          data_hash[:run_id]          = run_id
          data_hash[:touched_run_id]  = run_id
          data_hash[:data_source_url] = 'https://www3.pbso.org/blotter/index.cfm'
          data_hash                   = mark_empty_as_nil(data_hash)
          data_array << data_hash
          md5_array << data_hash[:md5_hash]
        end
        charges_array << data_array
        data_array = []
      end
    end
    grouped_arrest_array = get_grouped_array(db_arrest_ids)
    data_array = get_charges_array(charges_array, grouped_arrest_array.flatten)
    [data_array,md5_array]
  end

  def parse_bonds_data(db_charge_and_arrest_ids)
    bonds_array = []
    bond_types = ['Original Bond','Current Bond']
    data_array = []
    md5_array = []
    result_divs.each do |div|
      inner_divs = div.css('> div').select{ |e| e['class'].nil? }
      inner_divs.each do |inner_div|
        bonds_divs = inner_div.css('> div').select{ |e| e['style'].nil? }
        bonds_divs.each do |bond_div|
          bond_types.each_with_index do |bond_type,index|
            data_hash = {}
            data_hash[:bond_type]       = bond_type
            data_hash[:bond_amount]     = (index == 0) ? get_bond_type(bond_div, 'original') : get_bond_type(bond_div, 'current')
            data_hash[:md5_hash]        = create_md5_hash(data_hash)
            data_hash[:run_id]          = run_id
            data_hash[:touched_run_id]  = run_id
            data_hash[:data_source_url] = 'https://www3.pbso.org/blotter/index.cfm'
            data_hash                   = mark_empty_as_nil(data_hash)
            data_array << data_hash
            md5_array << data_hash[:md5_hash]
          end
        end
        bonds_array << data_array
        data_array = []
      end
    end
    data_array = get_bonds_array(bonds_array, db_charge_and_arrest_ids)
    [data_array,md5_array]
  end

  private

  attr_reader :page, :run_id, :result_divs, :aws_s3

  def get_bond_type(bond_div, key)
    bond_div.css('div').select{|e| e.text.to_s.downcase.include? key}.first.text.squish.split(':').last.gsub('Bond Information','').strip
  end

  def decode_base64_image(image_url)
    encoded_data = image_url.split(',')[1]
    Base64.decode64(encoded_data)
  end

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def get_value(headers, key)
    required_header = headers.select{ |e| e.text.to_s.downcase.include? key }.first
    required_header.parent.text.squish.gsub("#{required_header.text.to_s.squish}", "").squish
  end

  def get_date_required_format(date)
    DateTime.strptime(date,"%m/%d/%Y").to_date rescue nil
  end

  def name_split(full_name)
    comma_splited_names = full_name.split(',')
    space_splited_names = comma_splited_names.last.squish.split
    last_name = comma_splited_names.first.to_s.squish
    if (space_splited_names.count == 1)
      middle_name = nil
      suffix = nil
      first_name = space_splited_names.first.to_s.squish
    elsif (space_splited_names.count == 2)
      middle_name = space_splited_names.last.to_s.squish
      first_name = space_splited_names.first.to_s.squish
      suffix = nil
    elsif (space_splited_names.count == 3)
      middle_name = space_splited_names[-2].to_s.squish
      first_name = space_splited_names.first.to_s.squish
      suffix = space_splited_names.last.to_s.squish
    end
    [first_name,middle_name,last_name,suffix]
  end

  def upload_image_to_aws(content, file_name)
    aws_s3.put_file(content, "inmates/fl/palmbeach/#{file_name}.jpg")
  end

  def get_grouped_array(ids_array)
    required_array = ids_array.group_by(&:first).values.map do |group|
      if group.size > 1
        group.map(&:last)
      else
        group.first.last
      end
    end
    required_array
  end

  def get_facilty_array(data_array, ids_array)
    required_data_array = []
    ids_array.each_with_index do |element,outer_index|
      if element.is_a?(Array)
        element.each do |nested_element|
          data_hash = data_array[outer_index].merge(:arrest_id => nested_element)
          md5_hash = create_md5_hash(data_hash)
          required_data_array << data_hash.merge(:md5_hash => md5_hash)
        end
      else
        data_hash = data_array[outer_index].merge(:arrest_id => element)
        md5_hash = create_md5_hash(data_hash)
        required_data_array << data_hash.merge(:md5_hash => md5_hash)
      end
    end
    required_data_array
  end

  def get_charges_array(charges_array, ids_array)
    required_data_array = []
    charges_array.each_with_index do |element,outer_index|
      if element.is_a?(Array)
        element.each do |nested_element|
          data_hash = nested_element.merge(:arrest_id => ids_array[outer_index])
          md5_hash = create_md5_hash(data_hash)
          required_data_array << data_hash.merge(:md5_hash => md5_hash)
        end
      else
        data_hash = element.merge(:arrest_id => ids_array[outer_index])
        md5_hash = create_md5_hash(data_hash)
        required_data_array << data_hash.merge(:md5_hash => md5_hash)
      end
    end
    required_data_array
  end

  def get_bonds_array(bonds_array, ids_array)
    required_data_array = []
    bonds_array.each_with_index do |element,outer_index|
      if element.is_a?(Array)
        element.each do |nested_element|
          inner_hash = {:arrest_id => ids_array[outer_index].first, :charge_id => ids_array[outer_index].last}
          data_hash = nested_element.merge(inner_hash)
          md5_hash = create_md5_hash(data_hash)
          required_data_array << data_hash.merge(:md5_hash => md5_hash)
        end
      else
        inner_hash = {:arrest_id => ids_array[outer_index].first, :charge_id => ids_array[outer_index].last}
        data_hash = element.merge(inner_hash)
        required_data_array << element.merge(:arrest_id => ids_array[outer_index])
        md5_hash = create_md5_hash(data_hash)
        required_data_array << data_hash.merge(:md5_hash => md5_hash)
      end
    end
    required_data_array
  end

end
