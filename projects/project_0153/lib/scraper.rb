# frozen_string_literal: true

require_relative '../models/north_dakota'
require_relative '../models/north_dakota_runs'
require_relative '../models/usa_administrative_division_states'

class Scraper <  Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @run_object = RunId.new(NorthDakotaRuns)
    @processed_hash = NorthDakota.pluck(:md5_hash)
    @states_array = USAStates.all().map { |row| row[:short_name] }
  end

  def store
    html = connect_to("https://www.ndcourts.gov/lawyers/GetLawyers")
    json_hash = JSON.parse(html.css("p").text)
    File.open("#{storehouse}store/lawers.json","w") do |f|
      f.write(JSON.pretty_generate(json_hash))
    end
  end

  def parser
    hash_array = []
    file       = File.read("#{storehouse}store/lawers.json")
    json_hash  = JSON.parse(file)
    json_hash.each do |hash|
      bar_number     = hash["BarNum"]
      name           = get_full_name(hash).squish
      law_firm_city  = hash["City"].squish
      law_firm_state = hash["State"].upcase
      link = "https://www.ndcourts.gov/lawyers/#{bar_number}"
      html = connect_to(link)
      data_tag            = html.css("#collapseOne")
      law_firm_name       = get_value(data_tag, "Law Firm")
      law_firm_address    = get_value(data_tag, "Business Address")
      law_firm_zip        = law_firm_address.split("\n").last.scan(/\d+-\d+|\d+/).last rescue nil
      law_firm_zip        = get_zip(law_firm_zip)
      phone               = get_phone(get_value(data_tag, "Phone"))
      email               = get_value(data_tag, "Email")
      date_admitted       = Date.strptime(get_value( data_tag, "Admitted in N.D."),"%m/%d/%Y").to_date rescue nil
      registration_status = get_value(data_tag, "Status")
      law_school          = get_value(data_tag, "Law School")
      data_hash  = {}
      data_hash[:bar_number]          = bar_number
      data_hash[:name]                = name
      data_hash[:law_firm_name]       = law_firm_name
      data_hash[:registration_status] = registration_status
      data_hash[:link]                = link
      data_hash[:law_firm_address]    = law_firm_address
      data_hash[:phone]               = phone
      data_hash[:email]               = email
      data_hash[:date_admitted]       = date_admitted
      data_hash[:law_school]          = law_school
      data_hash = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash]            = create_md5_hash(data_hash)
      data_hash[:law_firm_zip]        = law_firm_zip
      data_hash[:law_firm_city]       = law_firm_city
      data_hash[:law_firm_state]      = law_firm_state
      data_hash[:run_id]              = @run_object.run_id
      data_hash = check_state(data_hash)
      next if @processed_hash.include? data_hash[:md5_hash]
      hash_array.push(data_hash)
      if hash_array.count > 100
        NorthDakota.insert_all(hash_array)
        hash_array = []
      end
    end
    NorthDakota.insert_all(hash_array) unless hash_array.empty?
    mark_deleted
    @run_object.finish
  end

  private

  def check_state(data_hash)
    unless @states_array.include? data_hash[:law_firm_state].upcase
      data_hash[:law_firm_state] = nil
      data_hash[:law_firm_city]  = nil
      data_hash[:law_firm_zip]   = nil
    end
    data_hash
  end

  def get_value(data, title)    
    values = data.css("dt").select{|e| e.text.downcase.include? "#{title}".downcase}
    if values.empty?
      value = nil
    elsif title == 'Business Address'
      value = values[0].next_element.to_html.gsub("<br>","\n").gsub("</dd>","").gsub("<dd>","").to_s
    else
      value = values[0].next_element.text.squish rescue nil
    end
    value
  end
  
  def get_full_name(data_hash)
    data_hash["MiddleName"] == "" ? ([data_hash["FirstName"], data_hash["LastName"]].join(" ")) : ([data_hash["FirstName"], data_hash["MiddleName"], data_hash["LastName"]].join(" "))
  end

  def get_zip(zip_value)
    (zip_value.nil? || zip_value.length < 4) ? nil : zip_value
  end

  def get_phone(phone_value)
    (phone_value.nil?) || (phone_value.count("0-9")) < 1 ? nil : phone_value
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
    md5_hash
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.squish.empty? ? nil : value}
  end

  def mark_deleted
    records = NorthDakota.where(:deleted => 0).group(:bar_number).having("count(*) > 1")
    records.each do |record|
      record.update(:deleted => 1)
    end
  end

  def connect_to(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
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
