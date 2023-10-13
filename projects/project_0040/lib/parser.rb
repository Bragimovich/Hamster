# frozen_string_literal: true

class Parser <  Hamster::Parser

  def get_total_pages(response)
    page = Nokogiri::HTML(response.body)
    page.css("#pagination-links").text.squish.split("of")[-1].strip.split[0].to_i
  end

  def get_records(response)
    Nokogiri::HTML(response).css('div.col-md-3')
  end

  def scrape_data(row, page_no, run_id, db_processed_md5)
    data_hash = {}
    data_hash[:busines_name] = row.css("div.name h3").text.squish rescue nil
    parsed_row = row.css(".detail")
    data_hash[:license_nr] =  fetch_row_data(parsed_row , "License Number :")
    data_hash[:business_activity] = fetch_row_data(parsed_row , "Business Activity :")
    data_hash[:valid_from] = fetch_row_data(parsed_row , "Valid From :")
    data_hash[:valid_from] = DateTime.strptime(fetch_row_data(parsed_row , "Valid From :") ,"%m-%d-%Y").to_date rescue nil
    data_hash[:valid_to] = fetch_row_data(parsed_row , "Valid To :") 
    (data_hash[:valid_to].include? "--0001") ? data_hash[:valid_to] = data_hash[:valid_to].gsub("--" , "-") : data_hash[:valid_to]
    data_hash[:valid_to] = DateTime.strptime(data_hash[:valid_to],"%m-%d-%Y").to_date rescue nil
    data_hash[:location] = fetch_row_data(parsed_row , "Location :")
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    db_processed_md5.delete data_hash[:md5_hash] if db_processed_md5.include? data_hash[:md5_hash]
    data_hash[:data_source_url] = "https://revenue.delaware.gov/business-license-search/page/#{page_no}/"
    data_hash[:last_scrape_date] = Date.today
    data_hash[:next_scrape_date] = Date.today.next_month
    data_hash[:scrape_frequency] = 'Monthly'
    data_hash[:expected_scrape_frequency] = 'Monthly'
    data_hash[:pl_gather_task_id] = 0

    data_hash[:run_id] = run_id

    [data_hash, db_processed_md5]
  end

  def fetch_row_data(record , title)
    values = record.css("p").select{|e| e.text.downcase.include? "#{title}".downcase}
    if values.empty?
      value = nil
    else
      if title == "Location :"
        value = values[0].text.split(":")[-1].strip 
        if value == ", ," and value != nil
          value = nil
        elsif value.split[0] == ","  
          value = value.split
          value[0] = value[0].gsub("," , "")
          value = value.join(" ").strip
        end
        return value
      end
      value = values[0].text.split(":")[-1].squish rescue nil
    end
    value
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
