# frozen_string_literal: true
require 'roo'
class FloridaParser < Hamster::Parser
  def info_links(body)
    data_array = []
    obj = Nokogiri::HTML(body.force_encoding("utf-8"))
    obj.css("a").select{|e| e.text.include? "County and Party - Excel"}[0]['href']
  end

  def date_split(data,index)
    data.split("/")[index]
  end
  
  def excel_data(path,link,run_id)
    xsl = Roo::Spreadsheet.open(path)
    data_array = []
    xsl.sheets.each_with_index do |value,index_1|
      month_check = Date::MONTHNAMES.select{|a| a == value }
      unless month_check.empty?
        next if Date::MONTHNAMES.index(month_check[0]) >= Date.today.month
        xsl.default_sheet = xsl.sheets[index_1]
        data = xsl.as_json
        index_2 = 1
        date_hash                     = {}
        date                          = data[index_2][0].split(" ")[-1]
        date_hash[:date]              = date
        date_hash[:month]             = date_split(date,0)
        date_hash[:year]              = date_split(date,-1)
        date_hash[:day]               = date_split(date,1)
        date_hash[:data_source_url]   = "https://dos.myflorida.com" + link
        date_hash[:run_id]            = run_id
        date_hash[:last_scrape_date]  = Date.today
        date_hash[:next_scrape_date]  = Date.today.next_month
        data.each_with_index do |data_1,index_3|
          next if index_3 <= 3 || index_3 == data.count-1
          data_hash = {:county => "", :republican_party_of_florida => "", :democratic_party_of_florida => "", :minor_party => "", :no_party_affiliation => "", :total => ""}
          data_hash.keys.each_with_index do |key, index_4|
            data_hash[key]            = data_1[index_4]
          end
          unless data_hash[:total].nil?
            data_array << data_hash.update(date_hash)
          else
            next
          end
        end
      end
    end
    data_array
  end
end
