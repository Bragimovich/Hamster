require 'creek'
class Parser < Hamster::Parser

  def parse_html(response)
    Nokogiri::HTML(response.body.force_encoding('utf-8'))
  end

  def fetch_inspection_link(page)
    page.css("#exp-dt1")[0]['href']
  end

  def fetch_citation_link(page)
    link = page.css("#exp-dt3")[0]['href']
    (link.include? "https://datadashboard.fda.gov/") ? link : "https://datadashboard.fda.gov/ora/cd/#{link}"
  end

  def parse_citations(row, run_id, md5_array, hash_array, index_no)
    data_hash = {}
    data_hash[:year] = row["D#{index_no+1}"].to_date.year
    data_hash[:inspection_id] = row["A#{index_no+1}"].strip
    data_hash[:fei_number] = row["B#{index_no+1}"].strip
    data_hash[:legal_name] = row["C#{index_no+1}"].strip
    data_hash[:inspection_end_date] = row["D#{index_no+1}"].to_date
    data_hash[:program_area] = row["E#{index_no+1}"]
    data_hash[:act_cfr_number] = row["F#{index_no+1}"]
    data_hash[:short_description] = row["G#{index_no+1}"]
    data_hash[:long_description] = row["H#{index_no+1}"]
    data_hash[:firm_profile] = "https://datadashboard.fda.gov/ora/firmprofile.htm?FEIi=#{data_hash[:fei_number]}"
    md5_array << create_md5_hash(data_hash)
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash = mark_empty_as_nil(data_hash)
    hash_array << data_hash
    [hash_array, md5_array]
  end

  def parse_inspections(row, run_id, md5_array, hash_array, index_no)
    data_hash = {}
    data_hash[:fei_number] = row["A#{index_no+1}"]
    data_hash[:legal_name] = row["B#{index_no+1}"].strip
    data_hash[:city] = row["C#{index_no+1}"].strip
    data_hash[:state] = row["D#{index_no+1}"].strip
    data_hash[:zip_code] = row["E#{index_no+1}"]
    data_hash[:country] = row["F#{index_no+1}"]
    data_hash[:year] = row["G#{index_no+1}"]
    data_hash[:inspection_id] = row["H#{index_no+1}"]
    data_hash[:posted_citations] = row["I#{index_no+1}"]
    data_hash[:inspection_end_date] = row["J#{index_no+1}"].to_date rescue nil
    data_hash[:classification] = row["K#{index_no+1}"]
    data_hash[:project_area] = row["L#{index_no+1}"]
    data_hash[:product_type] = row["M#{index_no+1}"]
    data_hash[:firm_profile] = "https://datadashboard.fda.gov/ora/firmprofile.htm?FEIi=#{data_hash[:fei_number]}"
    md5_array << create_md5_hash(data_hash)
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash = mark_empty_as_nil(data_hash)
    hash_array << data_hash
    [hash_array, md5_array]
  end

  def read_file(file)
    doc = Creek::Book.new(file, with_headers: true)
    sheet = doc.sheets[0]
    sheet.rows
  end

  private

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end
end
