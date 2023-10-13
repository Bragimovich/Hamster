# frozen_string_literal: true

require_relative '../models/FSCALPdfs'

class Scraper <  Hamster::Scraper

  MAIN_URL = "http://onlinedocketssc.flcourts.org"  
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def initialize
    super  
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed = FSCALPdfs.pluck(:data_source_url)
  end

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
  end

  def connect_to_pdf(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter, ssl_verify:{:verify => true})
      retries += 1
    end until response&.status == 200 or retries == 10
    response
  end

  def scraper
    start_date = FSCALPdfs.limit(1).order("id desc").pluck(:created_at)[0].to_date
    end_date = start_date + 7
    while true  
      break if end_date > Date.today
      p start_date
      p end_date
      p "----------------------------------------"
      url = prepare_url(start_date , end_date)
      body = connect_to(url)
      parser(body)  
      start_date = end_date + 1
      end_date = end_date + 7
    end
  end

  def parser(body)
    all_links = body.css("#vprint table[border='1'] tr")[1..-1].map{|e| MAIN_URL +  e.css("td").first.css("a.hyperText").attr("href").value}
    all_dates = body.css("#vprint table[border='1'] tr")[1..-1].map{|e| e.css("td")[3].text.squish rescue nil}
    all_case_number = body.css("#vprint table[border='1'] tr")[1..-1].map{|e| e.css("td").first.css("a.hyperText").text.squish}

    all_links.each_with_index do |link , i|
      p case_no = all_case_number[i]
      case_date_docketed = Date.strptime(all_dates[i] , "%m/%d/%Y") rescue nil
      next if @already_processed.include? link
      inner_body = connect_to(link)
      data_source_url = link
      required_data = inner_body.css("table[border='1'] tr")[1..-1].select{|e| e.css("td")[3].text.downcase.include? "ACKNOWLEDGMENT LETTER".downcase}
      next if required_data.empty?
      data_array = []

      required_data.each do |data|
        pdf_date_docketed = Date.strptime(data.css("td")[1].text.squish , "%m/%d/%Y") rescue nil
        pdf_url = data.css("td").first.css("a").attr("href").value rescue nil
        next if pdf_url.nil?
        download( pdf_url, case_no)
        data_hash = {
          case_date_docketed: case_date_docketed,
          case_no: case_no,
          pdf_date_docketed: pdf_date_docketed,
          pdf_link_on_aws: pdf_url,
          data_source_url: data_source_url
        }
        data_array.push(data_hash)
      end
      begin
      FSCALPdfs.insert_all(data_array) if !data_array.empty?
      rescue 
       sleep(10)
       FSCALPdfs.insert_all(data_array) if !data_array.empty?
      end 
    end
  end
 
  def prepare_url(start_date , end_date)
    start_day = prepare_digit(start_date.day)
    start_month = prepare_digit(start_date.month)
    start_year = start_date.year
    end_day = prepare_digit(end_date.day)
    end_month = prepare_digit(end_date.month)
    end_year = end_date.year 
    url = "http://onlinedocketssc.flcourts.org/DocketResults/CaseDate?Searchtype=Date+Filed&Status=All+Cases&DocketType=All&CaseTypeSelected=All&FromDate=#{start_month}%2F#{start_day}%2F#{start_year}&ToDate=#{end_month}%2F#{end_day}%2F#{end_year}"
    return url
  end

  def prepare_digit(digit)
    if digit.to_s.length == 1 
      return ("0"+ digit.to_s)
    else
      return digit
    end
  end

  def download(pdf_url , case_no)
    response = connect_to_pdf(pdf_url)
    file_name = pdf_url.split("/").last.gsub(".pdf", "_#{case_no.split.join("_")}")
    save_pdf(response&.body , file_name)
    pdf_url
  end

  def save_pdf(pdf , file_name)
    pdf_storage_path = "#{storehouse}store/#{file_name}.pdf"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(pdf)
    end
  end
end
