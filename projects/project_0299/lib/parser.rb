require 'creek'
class Parser < Hamster::Parser

  def get_links(html)
    doc = Nokogiri::HTML(html)
    doc.css("div[data-label='All reports'] a").map { |e| e['href']}
  end

  def get_parsed_data(file, link, run_id)
    doc = Creek::Book.new file
    sheet = doc.sheets[-2]
    data_array = []
    headers = sheet.rows.select{|a| a["A4"].include? "County" rescue nil}.first
    ind =  headers.keys.first.scan(/\d+/).first.to_i
    column_array = get_hash
    sheet.rows.each_with_index do |row, index|
      next if index < ind.to_i
      data_hash = {}
      column_array.each do |key, value|
        header_extract = get_header(headers, value)
        cell = header_extract.keys.first
        digit = cell.scan(/\d+/).first.to_i + index-ind+1
        cell = cell.gsub(cell.scan(/\d+/).first, digit.to_s)
        data_hash[:"#{key}"] = row[cell]
      end
      data_hash[:year] = link.split("/")[0]
      data_hash[:month] = file.split("/").last.gsub(".xlsx","").squish
      data_hash[:data_source_url] = "https://www.sos.state.co.us/pubs/elections/VoterRegNumbers/#{link}"
      data_hash[:pl_gather_task_id] = 174073858
      data_hash[:scrape_frequency] = "Monthly"
      data_hash[:last_scrape_date] = "#{Date.today}"
      data_hash[:next_scrape_date] = "#{Date.today >> 1}"
      data_hash[:expected_scrape_frequency] = "Monthly"	
      data_hash[:dataset_name_prefix] = "colorado_voter_registrations"
      data_hash[:scrape_status] = "Live"
      data_hash[:scrape_dev_name] = "Adeel"
      data_hash[:run_id] = run_id
      data_array << data_hash
    end
    data_array
  end

  private

  def get_header(headers, search_header)
    headers.select{|k, v| v if v == search_header}
  end

  def get_hash
    {
      "county" => "County",
      "uaf_acn" => "ACN",
      "uaf_apv" => "APV",
      "uaf_dem" => "DEM",
      "uaf_grn" => "GRN",
      "uaf_libl" => "LIB",
      "uaf_rep" => "REP",
      "uaf_uni" => "UNI",
      "uaf_total" => "Total",
    }
  end
end
