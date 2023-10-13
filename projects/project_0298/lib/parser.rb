require 'roo'

class Parser < Hamster::Parser
  def fetch_links(response)
    meta_links = []
    pp = fetch_nokogiri(response)
    pp.css('#main-content-normal').css('a').select { |e| e.text.include? 'Report of Registration' }.map { |e| meta_links << e['href'] }
    meta_links.select { |e| e.include? (Date.today.year).to_s }
  end

  def xlsx_links(response)
    parsed_page        = fetch_nokogiri(response)
    day, month, year   = fetch_date(parsed_page)
    all_matching_texts = parsed_page.css("ul.blts.dblSpc").css("li").select{|s| s.text == "Registration by County (PDF) | (XLS)"}
    file_link = all_matching_texts[0].css("a").select{|s| s[:href].include? "xlsx"}
    link      = file_link[0][:href]
    file_name = "#{link.split("/")[-2].gsub('-','_')}_#{day}_#{month}_#{year}"
    [file_name, link]
  end

  def process_hash(data_hash, row)
    data_hash.keys.each_with_index do |key, index|
      data_hash[key] = row[index]
    end
    data_hash
  end

  def process_file(link, file_name, path, run_id)
    hash_array = []
    xlsx_file = Roo::Spreadsheet.open(path)
    sheet_name = xlsx_file.sheets.first
    xlsx_file.sheet(sheet_name).each_with_index do |row, indx|
      next if (row.include? "County") || (row.include? "Percent") || (row.include? "State Total") || (row.include? nil)

      hash_array << parse_data(row, indx, link, file_name, run_id)
    end
    hash_array
  end

  private

  def parse_data(row, indx, link, file_name, run_id)
    data_hash = {:county => "", :eligible => "", :total_registered => "", :democratic => "", :republican => "", 
      :american_independent => "", :green => "", :libertarian => "", :peace_and_freedom => "", :unknown => "", 
      :other => "", :no_party_preference => ""
    }
    data_hash                    = process_hash(data_hash, row)
    data_hash                    = mark_empty_as_nil(data_hash)
    data_hash[:link]             = link
    data_hash[:run_id]           = run_id
    data_hash[:last_scrape_date] = Date.today
    data_hash[:next_scrape_date] = Date.today.next_week
    data_hash[:day], data_hash[:month], data_hash[:year] = parse_date(file_name)
    data_hash
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end

  def parse_date(fila_name)
    date = fila_name.split('_')
    year = date.last.split('.').first
    month = date[-2]
    day = date[-3]
    [day, month, year]
  end

  def fetch_nokogiri(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def fetch_date(parsed_page)
    get_date = parsed_page.css("#page-heading-inner h1").text
    get_date = get_date.split('-')[1].strip
    day = get_date.split(',')[0].split[1]
    month = get_date.split[0]
    year = get_date.split[-1]
    [day, month, year]
  end
end
