
class Parser < Hamster::Parser

  def fetch_file_link(response)
    response = fetch_nokogiri(response) 
    link = response.css('.content2-font a')[2]["href"]
    "https://www.ffiec.gov/craratings/#{link}"
  end

  def fetch_nokogiri(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def process_file(content, run_id, inserted_records)
    array_of_hash = []
    content.each_line do |line|
      row = line.split("\t")
      data_hash = {}
      data_hash[:cra_id] = row[0].to_i
      data_hash[:regulator] = row[1].to_i
      date = row[2]
      date = date_conversion(date)
      data_hash[:exam_date] = date
      data_hash[:bank_name] = row[3]
      data_hash[:city] = row[4]
      data_hash[:state] = row[5]
      data_hash[:assest_size] = row[6].to_i
      data_hash[:exam_method] = row[7].to_i
      data_hash[:rating] = row[8].to_i
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      next if inserted_records.include? data_hash[:md5_hash]
      data_hash.delete(:md5_hash)
      data_hash[:run_id] = run_id
      array_of_hash << data_hash
    end
    array_of_hash
  end

  private
  
  def date_conversion(date)
    date == "" ? nil : date.to_date 
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
