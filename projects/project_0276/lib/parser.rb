class Parser  < Hamster::Parser

  def fetch_outer_page_info(html)
    data_array = []
    doc = parsing(html)
    doc.css('#filedReports tbody tr').each do |record|
      data_hash = {}
      data_hash[:first_name], data_hash[:middle_name] = splitting_name(record.css('td')[0].text)
      data_hash[:last_name] = valid_last_name(record.css('td')[1].text.squish)
      data_hash[:full_name] = "#{data_hash[:first_name]} #{data_hash[:middle_name]} #{data_hash[:last_name]}"
      data_hash[:office], data_hash[:filer_type] = splitting_office(record.css('td')[2].text)
      data_hash[:report_type] = record.css('td')[3].text
      data_hash[:date_received_filed] =  date_conversion(record.css('td')[4].text)
      data_hash[:data_source_url]  = 'https://efdsearch.senate.gov' + record.css('a')[0]['href']
      data_hash = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array
  end

  def parse_annual_page(inner_page, data_hash, run_id)
    doc = parsing(inner_page)
    year = fetch_year(doc)
    data_array = []
    data_array = get_transaction(doc, data_hash, run_id, 'Periodic Transaction Report Summary', year)
    data_array = data_array + get_transaction(doc, data_hash, run_id, 'Part 4b. Transactions', year)
    data_array
  end

  def parse_peridoic_page(html, outer_data, run_id)
    doc = parsing(html)
    year = fetch_year(doc)
    hashes_array = []
    headers = doc.css('table.table-striped thead tr').first.css('th').map { |e| e.text } rescue []
    data_array   =  doc.css('table.table-striped tbody tr')
    data_array.each do |data|
      hashes_array << create_hash(outer_data, data, headers, run_id, year)
    end
    hashes_array
  end

  private

  def valid_last_name(last_name)
    (!last_name.nil? && last_name.squish.last == ',') ? last_name.squish[0..-2].squish : last_name
  end

  def fetch_year(doc)
    year = doc.css('p.font-weight-bold').text.split('@')[0].split.last rescue nil
    year = doc.css('strong.noWrap').text.split('@')[0].split.last if year.nil? rescue nil
    (year.include? '/') ? year.split('/').last : year unless year.nil?
  end

  def create_hash(data_hash, data, headers, run_id, year)
    data_hash[:year]                = year
    transaction_date                = get_data(data, headers, 'Transaction Date')
    data_hash[:transaction_date]    = date_conversion(transaction_date)
    data_hash[:owner]               = get_data(data, headers, 'Owner')
    data_hash[:ticker]              = get_data(data, headers, 'Ticker')
    asset                           = get_data(data, headers, 'Asset Name')
    data_hash[:asset_name], data_hash[:rate_coupon], data_hash[:matures] = get_asset_info(asset)
    data_hash[:asset_name] = (data_hash[:asset_name].nil?) ? nil : data_hash[:asset_name].force_encoding('utf-8')
    data_hash[:asset_type]          = get_data(data, headers, 'Asset Type')
    data_hash[:type]                = get_data(data, headers, 'Type')
    data_hash[:amount]              = get_data(data, headers, 'Amount')
    data_hash[:comments]            = get_data(data, headers, 'Comment')
    data_hash[:run_id]              = run_id
    data_hash[:touched_run_id]      = run_id
    data_hash[:last_scrape_date]    = Date.today
    data_hash[:next_scrape_date]    = Date.today.next_day
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    mark_empty_as_nil(data_hash)
  end

  def get_asset_info(asset)
    return [nil, nil ,nil] if asset.nil?
    asset = asset.split('Rate/Coupon:')
    asset_name = asset[0].squish
    asset = asset[1]
    rate_coupon = asset[1].split('Matures:')[0].gsub('%', '').to_f/100 rescue nil
    matures = Date.strptime(asset[1].split('Matures:')[1].squish, "%m/%d/%Y") rescue nil
    [asset_name, rate_coupon, matures]
  end

  def get_data(data, headers, key)
    data.css("td")[headers.index key].text.squish rescue nil
  end

  def get_transaction(doc, data_hash, run_id, search_key, year)
    data = doc.css('section').select {|e| e.text.include? search_key}[0].css('tbody tr') rescue []
    headers = doc.css('section').select {|e| e.text.include? search_key}[0].css('thead th').map { |e| e.text } rescue []
    data_array = []
    data.each do |record|
      data_array << create_hash(data_hash, record, headers, run_id, year)
    end
    data_array
  end

  def parsing(html)
    Nokogiri::HTML(html.force_encoding("utf-8")) 
  end

  def date_conversion(date)
    DateTime.strptime(date, '%m/%d/%Y').to_date unless date.nil?
  end

  def splitting_name(name)
    first_name = name.split[0]
    middle_name = name.split[1] rescue nil
    [first_name, middle_name]
  end

  def splitting_office(row)
    data = row.split('(')
    office = data[0].squish
    filer_type = data[1].split(')').join rescue nil
    [office, filer_type]
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s == '--' || value.to_s.squish.empty?) ? nil : value}
  end

  def create_md5_hash(data_hash)
    data_string = data_hash[:full_name].to_s + data_hash[:office].to_s + data_hash[:filer_type].to_s + data_hash[:report_type].to_s + data_hash[:date_received_filed].to_s + data_hash[:transaction_date].to_s + data_hash[:owner].to_s + data_hash[:ticker].to_s + data_hash[:asset_name].to_s + data_hash[:asset_type].to_s + data_hash[:type].to_s + data_hash[:amount].to_s + data_hash[:comments].to_s + data_hash[:data_source_url]
    Digest::MD5.hexdigest data_string
  end
end
