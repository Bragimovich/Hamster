class Parser < Hamster::Parser
  def fetch_csv_links(response)
    meta_links = []
    names = []
    response = fetch_nokogiri(response)
    response.css('table').first.css('td a').select{|e| e.text.include? 'CSV'}.map { |e| meta_links << e['href'] }
    response.css('table').first.css('tbody tr').map{ |r| names << r.css('td').first.text }
    [meta_links, names]
  end

  def fetch_name(name)
    month = name.split.first
    year = name.split[1]
    "#{month}_#{year}"
  end

  def process_file(link, file_name, path, run_id)
    date = ''
    county = ''
    hash_array = []
    month = file_name.split('_').first
    csv = CSV.parse(File.read(path), headers: true)
    csv.each do |row|
      row = row.to_ary.flatten.reject(&:nil?).reject{ |e| e.include? 'REPORT'}
      row.select{|e| e.include? month}.map { |e| date = e }
      next if (row.size < 7) || (row.include? 'County')
      break if row.include? 'District'

      county = (row[0].tr("^0-9", '').empty?) ? row.delete_at(0) : county
      hash_array << parse_data(row, date, link, run_id, county)
    end
    hash_array
  end

  private

  def parse_data(row, date, link, run_id, county)
    row.insert(0, nil) if row.length == 5
    row.insert(-1, nil) if row.length == 6
    row.insert(3, nil) if row.length == 7
    data_hash = {:precinct => "", :date_period => "", :democratic => "", :green => '', :libertarian => "", 
      :republican => "", :other => "", :total => ""
    }
    data_hash                    = process_hash(data_hash, row)
    data_hash[:county]           = county
    data_hash                    = mark_empty_as_nil(data_hash)
    data_hash[:link]             = link
    data_hash[:run_id]           = run_id
    data_hash[:last_scrape_date] = Date.today
    data_hash[:next_scrape_date] = Date.today.next_week
    data_hash[:month], data_hash[:day], data_hash[:year] = fetch_date(date)
    data_hash
  end

  def process_hash(data_hash, row)
    data_hash.keys.each_with_index do |key, indx|
      data_hash[key] = row[indx].nil? ? nil: row[indx].gsub(',','')
    end
    data_hash
  end

  def fetch_nokogiri(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def fetch_date(date)
    date.split('-').last.strip.gsub(',','').split
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end
end
