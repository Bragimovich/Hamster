# frozen_string_literal: true

class Parser < Hamster::Parser

  def get_years(response)
    page = parse_page(response)
    links = page.css('a').select{|e| e['href'].include? '20'}.map{|e| e['href']}
    start_index = links.index(links.select{|e| e.include? '2016_01'}.first)
    links[start_index..].map{|e| "https://apps.elections.virginia.gov#{e}"}
  end

  def get_csv_links(response)
    page = parse_page(response)
    page.css('a').select{|e| e['href'].include? '20'}.map{|e| "https://apps.elections.virginia.gov#{e['href']}"}
  end

  def parse_data(file,run_id,data_source_url)
    md5_array = []
    data_array = []
    rows = CSV.parse(File.read(file, encoding: "ISO-8859-1"), headers: true, liberal_parsing: true) rescue nil
    return [[],[]] if (rows.nil?)
    rows.each do |row|
      begin
        data_hash = row.to_hash.reject{|e| e.nil?}.transform_keys(&:underscore)
        data_hash = mark_empty_as_nil(data_hash)
        md5_hash = create_md5_hash(data_hash)
        data_hash = data_hash.merge('md5_hash' => md5_hash)
        data_hash = data_hash.merge('run_id' => run_id)
        data_hash = data_hash.merge('touched_run_id' => run_id)
        data_hash = data_hash.merge('data_source_url' => data_source_url)
        data_hash = convert_dates(data_hash)
        data_array << data_hash
        md5_array << md5_hash
      rescue
        next
      end
    end
    [data_array,md5_array]
  end

  private

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def convert_dates(data_hash)
    data_hash.each do |key,value|
      if (value.is_a?(String) && value.match(/\d{1,2}\/\d{1,2}\/\d{4}/))
        data_hash[key] = Date.strptime(value, '%m/%d/%Y').strftime('%Y/%m/%d')
      end
    end
  end

end
