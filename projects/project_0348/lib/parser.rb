# frozen_string_literal: true

class Parser < Hamster::Scraper
 
  DOMAIN = "https://myhealthycommunity.dhss.delaware.gov"
  def initialize
    super
  end
  
  def fetch_csv_url(response)
    html = Nokogiri::HTML(response.body)
    DOMAIN + html.css("a").select{|e| e.text == 'Download all coronavirus data for State of Delaware in one file'}.first['href']
  end

  def parser(run_id)
    csv_data = []
    files = peon.give_list
    files.each do |file|
      next if !file.include? Date.today.to_s
      content = peon.give(file: file)
      csv_data = CSV.parse(content, :headers => true , :liberal_parsing => true).map(&:to_hash)
      csv_data.each do |data|
        month = prepare_digit(data["month"])
        day = prepare_digit(data["day"])
        hash_str = ""
        hash_str = data["location"].to_s
        hash_str = hash_str + data["county"].to_s
        hash_str = hash_str + data["statistic"].to_s
        hash_str = hash_str + data["year"].to_s
        hash_str = hash_str + month.to_s 
        hash_str = hash_str + day.to_s  
        hash_str = hash_str + data["unit"].to_s
        md5_hash = Digest::MD5.hexdigest hash_str
        data.store("md5_hash" , md5_hash)
        data.store("run_id" , run_id)
      end
    end
    csv_data
  end

  def prepare_digit(digit)
    if digit.to_s.length == 1
      digit = "0" + digit.to_s
    end 
    digit
  end
   
end

