# frozen_string_literal: true

class Parser < Hamster::Parser

  def get_total_pages(response)
    page = parse_json(response)
    page['page_data']['total_pages']
  end

  def parse_district_data(body,run_id)
    page = parse_json(body)
    rows = page['rows']
    data_array = []
    md5_array = []
    rows.each do |row|
      data_hash = {}
      data_hash[:year] = row[0]['value']
      data_hash[:usd_number] = row[1]['value']
      data_hash[:district] = row[2]['value']
      data_hash[:first_name] = row[3]['value']
      data_hash[:last_name] = row[4]['value']
      data_hash[:position] = row[5]['value']
      data_hash[:total_pay] = row[6]['value']
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:data_source_url] = 'https://www.kansasopengov.org/kog/databank'
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  def parse_college_data(body,run_id)
    page = parse_json(body)
    rows = page['rows']
    data_array = []
    md5_array = []
    rows.each do |row|
      data_hash = {}
      data_hash[:year] = row[0]['value']
      data_hash[:community_college] = row[1]['value']
      data_hash[:first_name] = row[2]['value']
      data_hash[:last_name] = row[3]['value']
      data_hash[:position] = row[4]['value']
      data_hash[:total_pay] = row[5]['value']
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:data_source_url] = 'https://www.kansasopengov.org/kog/databank'
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  private

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def parse_json(body)
    JSON.parse(body)
  end

end
