# frozen_string_literal: true
require 'roo'
class IdahoParser < Hamster::Parser
  
  def info_links(body)
    obj = Nokogiri::HTML(body.force_encoding("utf-8"))
    count = obj.css('div.elementor-accordion-item').count
    i = 0
    data_array = []
    while i < count
      if obj.css('div.elementor-accordion-item')[i].css("a")[0].text.to_i == (Date.today - 15).year
        links = obj.css('div.elementor-accordion-item')[i].css("a").select{|a| (a["href"].downcase.include? "partyByCounty".downcase) ||(a["href"].downcase.include? "CountyTotals".downcase)}.map{|a| a["href"]}
        data_array << links
      end
      i = i+1
    end
    data_array.flatten
  end

  def data_split(entry,index)
    entry.css("td")[index].text.split(",").join
  end

  def html_data(body,link,run_id)
    data_array = []
    obj = Nokogiri::HTML(body.force_encoding("utf-8"))
    obj.css("#MainTable tr").each_with_index do |entry,index|
      next if index == 0
      data_hash = {:constitution => "", :democratic => "", :libertarian => "", :republican => "", :unaffiliated => "", :total_registered => ""}
      data_hash.keys.each_with_index do |key, index|
        data_hash[key] = data_split(entry,index+1)
      end
      data_hash[:year]                        = obj.css("#Header").text.split(",").last.squish
      data_hash[:day]                         = obj.css("#Header").text.split(",").first.split.last.squish
      data_hash[:month]                       = obj.css("#Header").text.split(",").first.split[-2]
      data_hash[:county]                      = entry.css("td")[0].text
      data_hash[:data_source_url]             = "https://sos.idaho.gov" + link
      data_hash[:last_scrape_date]            = Date.today
      data_hash[:next_scrape_date]            = Date.today.next_month
      data_hash["run_id"]                     = run_id
      data_array << data_hash
    end    
    data_array
  end

  def excel_data(path,link,run_id)
    xsl = Roo::Spreadsheet.open(path)
    sheet = xsl.as_json
    data_array = []
    sheet.each_with_index do |row,index|
      next if index == 0 || index == 1 || index == sheet.count-1
      data_hash = {}
      data_hash[:year]                      = link.split("_County").first.split("/").last[0..3]
      data_hash[:day]                       = nil
      data_hash[:month]                     = Date::MONTHNAMES[link.split("_County").first.split("/").last[-2..].to_i]
      data_hash[:county]                    = row[0]
      negative_counter = row.count == 8 ? 0 : 1
      data_hash[:constitution]              = row[2-negative_counter]
      data_hash[:democratic]                = row[3-negative_counter]
      data_hash[:libertarian]               = row[4-negative_counter]
      data_hash[:republican]                = row[5-negative_counter]
      data_hash[:unaffiliated]              = row[6-negative_counter]
      data_hash[:total_registered]          = row.count == 8 ? row[1] : row[6]
      data_hash[:data_source_url]           = "https://sos.idaho.gov" + link
      data_hash[:last_scrape_date]          = Date.today
      data_hash[:next_scrape_date]          = Date.today.next_month
      data_hash["run_id"]                   = run_id
      data_array << data_hash
    end
    data_array  
  end
end
