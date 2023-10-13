# frozen_string_literal: true

require_relative '../models/new_jersey_state_campaign_contributions_csv'

class Scraper <  Hamster::Scraper

  SOURCE = "https://www.elec.state.nj.us/publicinformation/contrib_quickdownload.htm"
  SUBFOLDER = 'new_jersey_state_campaign_contributions/'
  BASE_URL = "https://www.elec.state.nj.us"

  def initialize
    super  
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def connect_to(url)
    retries = 0

    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter )
      reporting_request(response) 
      retries += 1
    end until response&.status == 200 or retries == 10
    response 
  end

  def scraper     
    response = connect_to(SOURCE)
    document = Nokogiri::HTML(response.body)
    document = document.css("div#page-content")
    folders = document.css("h5")[1..-1].reject{|e| e.text.include? "All"}
    folders.each do |folder|
      files_links = []
      @folder_name = folder.text.split.join("_")
      table = folder.next_element
      p folder.text
      files_links = table.css("tr").map{|tr|  tr.css("td a").reject{|e| e.attr("href").to_s.include? "txt"}.map{|td| BASE_URL + td.attr("href").gsub("..", "")} }.flatten
      download(files_links) 
    end 
  end

  def download(files_links)
    files_links.each do |link|
      source = connect_to(link)
      result = source&.body
      save_xlsx(result, link)
    end
  end

  def save_xlsx(xlsx, link)
    FileUtils.mkdir_p "#{storehouse}store/#{SUBFOLDER}"
    year = link.split(".")[-2][-4..-1]
    type = link.split(".")[-1]
    xlsx_storage_path = "#{storehouse}store/#{SUBFOLDER}#{@folder_name}_#{year}.#{type}"
    File.open(xlsx_storage_path, "w") do |f|
      f.write(xlsx)
    end
  end

  def reporting_request(response)
    # unless @silence
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
    # end
  end
end
