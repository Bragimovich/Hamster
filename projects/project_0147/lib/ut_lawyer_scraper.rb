# frozen_string_literal: true

require_relative '../models/utah'
require_relative '../models/utah_runs'

class Scraper <  Hamster::Scraper
  MAIN_URL = "https://services.utahbar.org/"
  URL_PREFIX = MAIN_URL + "cvweb/cgi-bin/utilities.dll/CustomList?SORT=m.LASTNAME%2C+m.FIRSTNAME&FIRSTFILTER=%7E&LASTFILTER=%7E&RANGE="
  URL_SUFFIX = "&SQLNAME=UTMEMDIR_NEW&SHOWSQL_off=N&WHP=Customer_Header.htm&WBP=Customer_List.htm"
  LINK_PREFIX = MAIN_URL + "cvweb/cgi-bin/memberdll.dll/Info?&customercd="
  LINK_A_SUFFIX = "&wrp=Customer_Profile.htm"
  LINK_B_SUFFIX = "&wmt=none&wrp=CustomerAddressDisp.htm&CustomerAddressList=CustomerAddressListE.htm"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @inserted_records = LawyerStatusUtah.pluck(:md5_hash)
    @run = RunId.new(UtahRuns)
  end
  
  def connect_to(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    return response
  end

  def main
    page_no = 1
    offset = 1
    @limit = 1000
    data_source_url = URL_PREFIX + "#{offset.to_s}/#{@limit.to_s}" + URL_SUFFIX
    response = connect_to(data_source_url)
    document = Nokogiri::HTML(response.body)
    total_pages = document.css("span.nav2 a")[-1].text.to_i
    while page_no <= total_pages
      unless page_no == 1
        data_source_url = URL_PREFIX + "#{offset.to_s}/#{@limit.to_s}" + URL_SUFFIX
        response = connect_to(data_source_url)
        document = Nokogiri::HTML(response.body)
      end
      parser(document, offset, data_source_url)
      offset = @limit*page_no + 1
      page_no += 1
    end
    mark_deleted
  end

  def mark_deleted
    records = LawyerStatusUtah.where.not(md5_hash: nil).where(deleted: 0).group(:bar_number).having("count(*) > 1")
    records.each do |record|
      record.update(:deleted => 1)
    end
  end

  def parser(document, offset, data_source_url)
    lawyer_data_array = []
    lawyers_links = document.css("#myTable tbody tr a").map{|e| "https://services.utahbar.org" + e["href"]}
    lawyers_links.each do |link|
      bar_number = link.split("=")[-1]
      responseA = connect_to(LINK_PREFIX + bar_number + LINK_A_SUFFIX)
      documentA = Nokogiri::HTML(responseA.body)
      responseB = connect_to(LINK_PREFIX + bar_number + LINK_B_SUFFIX)
      documentB = Nokogiri::HTML(responseB.body)
      titles = documentA.css("dl.dl-horizontal dt").map{|e| e.text.downcase.strip}
      values = documentA.css("dl.dl-horizontal dd").map{|e| e.text.strip}
      titles.push(documentB.css("body dt").map{|e| e.text.downcase.strip})
      values.push(documentB.css("body dd").map{|e| e.text.strip})
      titles = titles.flatten
      values = values.flatten
      name_prefix = search_value(titles,values,"prefix")
      first_name = search_value(titles,values,"first name")
      middle_name = search_value(titles,values,"middle name")
      last_name = search_value(titles,values,"last name")
      name = [name_prefix,first_name,middle_name,last_name].reject{|e| e.nil?}.join(" ")
      type = search_value(titles,values,"type")
      status = search_value(titles,values,"status")
      law_school = search_value(titles,values,"law school")
      law_firm_name = search_value(titles,values,"organization")
      law_firm_address = search_value(titles,values,"mailing address")
      law_firm_address_count = search_value(titles,values,"mailing address cont.")
      unless law_firm_address_count.nil?
        law_firm_address = [law_firm_address,law_firm_address_count].join(", ")
      end
      law_firm_city = search_value(titles,values,"city")
      law_firm_state = search_value(titles,values,"state/province")
      law_firm_zip = search_value(titles,values,"zip/postal code")
      country = search_value(titles,values,"country")
      phone = search_value(titles,values,"work phone")
      email = search_value(titles,values,"email address")
      date_admitted = search_value(titles,values,"date admitted")
      date_admitted = DateTime.strptime(date_admitted, "%m/%d/%Y").to_date rescue nil
      lawyer_data_hash = {}
      lawyer_data_hash[:bar_number] = bar_number
      lawyer_data_hash[:name_prefix] = name_prefix
      lawyer_data_hash[:first_name] = first_name
      lawyer_data_hash[:middle_name] = middle_name
      lawyer_data_hash[:last_name] = last_name
      lawyer_data_hash[:status] = status
      lawyer_data_hash[:law_school] = law_school
      lawyer_data_hash[:name] = name
      lawyer_data_hash[:type] = type
      lawyer_data_hash[:date_admitted] = date_admitted
      lawyer_data_hash[:law_firm_name] = law_firm_name
      lawyer_data_hash[:law_firm_address] = law_firm_address
      lawyer_data_hash[:law_firm_city] = law_firm_city
      lawyer_data_hash[:law_firm_zip] = law_firm_zip
      lawyer_data_hash[:law_firm_state] = law_firm_state
      lawyer_data_hash[:country] = country
      lawyer_data_hash[:email] = email
      lawyer_data_hash[:phone] = phone
      lawyer_data_hash[:link] = link
      lawyer_data_hash[:md5_hash] = create_md5_hash(lawyer_data_hash)
      next if @inserted_records.include? lawyer_data_hash[:md5_hash]
      lawyer_data_hash[:data_source_url] = data_source_url
      lawyer_data_hash[:run_id] = @run.run_id
      lawyer_data_array.push(lawyer_data_hash)
      if lawyer_data_array.count > 99
        LawyerStatusUtah.insert_all(lawyer_data_array)
        puts "#{lawyer_data_array.count} records inserted"
        lawyer_data_array = []
      end
    end
    LawyerStatusUtah.insert_all(lawyer_data_array) if !lawyer_data_array.empty?
    puts "#{lawyer_data_array.count} records inserted"
    @run.finish
  end

  def search_value(titles, values, word)
    value = nil
    titles.each_with_index do |title, idx|
      if title == word
        value = values[idx]
        break
      end
    end
    if value == ""
      value = nil
    end
    value
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
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
