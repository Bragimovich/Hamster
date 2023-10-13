# frozen_string_literal: true

require_relative '../models/va_office_reports'
require_relative '../models/va_office_reports_locations'

class Scraper <  Hamster::Scraper
  MAIN_URL = "https://www.va.gov/oig/apps/info/OversightReports.aspx?RPP=100&RS="

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_reports = VaReports.pluck(:data_source_url)
  end
  
  def connect_to(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter)
      reporting_request(response) 
      retries += 1 
    end until response&.status == 200  or retries == 10
    return response
  end

  def main
    @flag = false
    page_no = 1
    while true
      data_source_url = MAIN_URL + page_no.to_s 
      response = connect_to(data_source_url)
      document = Nokogiri::HTML(response.body) 
      parser(document)
      break if @flag == true
      page_no += 1
    end
  end

  def parser(document)
    summary_links = document.css("div.report-list div.report a.report__meta--summary-link").map{|e| e["href"]}
    
    summary_links.each do |link|
      if @already_fetched_reports.include? link  
        @flag = true 
        next
      end
      
      request_retry = 0
      while request_retry < 5
        response = connect_to(link)
        summary_doc = Nokogiri::HTML(response.body)
        table_rows = summary_doc.css("table.report_summary tr")
        break if !(table_rows.empty?)
        request_retry += 1 
      end
       
      if table_rows.empty?
        VaReports.create(data_source_url: link)
      else
      	summary = search_table(table_rows, "Summary:").css("td").to_s
      	summary = summary.gsub("<br>","\n")
      	summary = Nokogiri::HTML(summary).text.strip	

        has_location = 0
        date = search_table(table_rows, "Issue Date:").css("td").text.strip 
        date = DateTime.strptime(date, "%m/%d/%Y").to_date 
        city_state = search_table(table_rows, "City/State:").css("td").to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>)/) rescue ""
        link_to_report = search_table(table_rows, "Report Number:").css("a")[0]["href"] rescue ""

        if city_state != "" and !(city_state.empty?)
          has_location = 1
        end
        
        hash_report = {
          title: search_table(table_rows, "Title:").css("td").text.strip,
          has_location: has_location,
          link_to_report: link_to_report,
          date: date,
          report_number: search_table(table_rows, "Report Number:").css("td").text.strip.split[0].strip,
          va_office: search_table(table_rows, "VA Office:").css("td").to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>)/).join("\n"),
          report_author:search_table(table_rows, "Report Author:").css("td").to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>)/).join("\n"),
          report_type: search_table(table_rows, "Report Type:").css("td").to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>)/).join("\n"),
          release_type: search_table(table_rows, "Release Type:").css("td").text.strip,
          summary: summary,
          data_source_url: link
        }
        VaReports.insert(hash_report) 
      
        if has_location == 1
          va_locations_array = []
          va_office_reports_id = VaReports.limit(1).where(:data_source_url => link).pluck(:id)[0]
	  
          city_state.each do |cs|
            hash_va_locations = {
              va_office_reports_id: va_office_reports_id,
              city: cs[0].split(",").first.strip,
              state: cs[0].split(",").last.strip,
              data_source_url: link
            }
            va_locations_array.push(hash_va_locations)
          end
          VaLocations.insert_all(va_locations_array) 
        end
      end
    end
  end

  def search_table(table_rows, word)
    value = ""
    table_rows.each do |key|
      if key.css("th").text.strip == word 
        value = key
        break
      end
    end
    return value
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
