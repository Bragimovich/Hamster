# frozen_string_literal: true

class MNBizLicensesParser < Hamster::Harvester
  attr_reader :document, :business_search, :search_details, :company_details, :company_address, :company_id
  
  def initialize
    @business_search = {
      scheme: 'https',
      host:   'mblsportal.sos.state.mn.us',
      path:   '/Business/BusinessSearch',
      query:  {
        BusinessName:      '',
        IncludePriorNames: 'False',
        Status:            'Active',
        Type:              'BeginsWith'
      }
    }
    @search_details  = @business_search.merge(
      {
        path:  "/Business/SearchDetails",
        query: { filingGuid: '' }
      }
    )
  end
  
  def document=(val)
    ; @document = Nokogiri::HTML(val)
  end
  
  def business_search=(val)
    ; @business_search[:query][:BusinessName] = val
  end
  
  def search_details=(val)
    @company_id                          = val
    @search_details[:query][:filingGuid] = val
  end
  
  def alert
    @document.css('.alert').text
  end
  
  def table_size
    @document.css('table.table tr').size - 1
  end
  
  def table_empty?
    table_size.zero?
  end
  
  def company_url
    Hamster.assemble_uri(@search_details)
  end
  
  def company_ids
    detail_links = []
    @document.css('table.table tr').each do |tr|
      tr.css('td').css('a').map { |a| detail_links << a[:href].match(%r{.+filingGuid=(?<id>.+)$})[:id] }
    end
    detail_links.uniq
  end
  
  def gather_company_info
    data_fix = -> s { s.gsub(/(\d{1,2})\/(\d{1,2})\/(\d{4})/, '\3-\1-\2').strip unless s.nil? }
    
    @company_details = {}
    @company_address = {}
    
    @company_details[:business_name] = clean(@document.css('.business-name .navbar-brand').inner_html.split(/<[\/a-z]+>/).delete_if { |el| el.empty? || el =~ /^\s+$/i }.join(' ').strip.squeeze(' '))
    
    @document.css('#filingSummary dl').each do |dl|
      
      detail = symbolize(dl.css('dt').text)
      
      if dl.css('address').empty?
        @company_details[detail]                 = clean(data_fix[dl.css('dd').text])
        @company_details["#{detail}_raw".to_sym] = clean(dl.css('dd').text) if detail.match?(/_date\b/)
      else
        gather_address(dl.css('dd'), detail)
      end
    
    end
    
    gather_table_address unless @document.css('#filingSummary table').empty?
  end
  
  private
  
  def gather_address(node, detail)
    @company_address[detail] ||= []
    current_address          = {}
    
    node.each do |dd|
      current_address[:name] = dd.text if dd.css('address').empty?
      
      dd.css('address').each do |raw_address|
        address = raw_address.inner_html.split(/<[\/a-z]+>/).delete_if { |el| el.empty? || el =~ /^\s+$/i }
        
        next if address.empty?
        
        current_address[:raw_address] = clean(raw_address.inner_html)
        
        current_address.merge!(parse_address(address))
      end
    
    end
    
    @company_address[detail] << current_address
  end
  
  def parse_address(address)
    parsed_address = {}
    zip_re         = '(?<zip>(?>\[?\d{5}\]?(?> ?[-–] ?\[?\d{4}\]?)?)|(?>[0-9a-z]{3}\s?[-–0-9a-z]{3,4}))' # it finds US, UK and Canadian zips
    location_re    = %r{(?<city>.+), (?<state>[-() a-z]+) #{zip_re}(?>, (?<country>[ a-z]+))?$}i
    
    if address.is_a?(Array) && address.size > 0
      parsed_address[:address1] = clean(address.shift.strip) unless address.first.match?(location_re) || address.size == 1
      
      country, location         =
        if address.last.match?(location_re)
          [nil, address.pop.match(location_re)]
        elsif address.size > 1
          [address.pop.strip, address.pop.match(location_re)]
        else
          [address.pop.strip, nil]
        end
      
      parsed_address[:address2] = clean(address.first.strip) if address.size > 0
    else
      location = address.strip.match(location_re)
      if location
        country = location[:country]
        city    = location[:city].split(',')
        
        city.pop
        
        parsed_address[:address1] = clean(city.shift.strip) unless city.empty?
        parsed_address[:address2] = clean(city.join(', ').squeeze(' ').strip) unless city.empty?
      else
        country, location = nil, nil
      end
    end
    
    parsed_address[:city]    = clean(location[:city].split(',').pop.strip) if location && location[:city]
    parsed_address[:state]   = clean(location[:state]) if location && location[:state]
    parsed_address[:zip]     = clean((location[:zip].match?(/\d{5}[^\d]+\d{4}/) ? location[:zip].split(/[^\d]/).join('-').squeeze('-') : location[:zip])) if location && location[:zip]
    parsed_address[:country] = clean(country) if country
    
    parsed_address
  end
  
  def gather_table_address
    header = []
    rows   = []
    
    @document.css('#filingSummary thead th').each { |th| header << th.text }
    
    @document.css('#filingSummary tbody tr').each { |tr| rows << tr.css('td').to_a.map(&:inner_html) }
    
    detail = symbolize(header.first)
    
    @company_address[detail] ||= []
    
    rows.each do |row|
      current_address               = {}
      current_address[:name]        = clean(row.first.strip)
      current_address[:raw_address] = clean(row.last)
      
      current_address.merge!(parse_address(row.last))
      
      @company_address[detail] << current_address
    end
  end
  
  def symbolize(str)
    str.match(/([a-z ]+)(?>[^a-z ]+)?([a-z ]+)/i).to_a.map.with_index { |e, i| e unless i.zero? }.join.downcase.split.join('_').to_sym
  end
  
  def clean(text)
    text.gsub(%r{[^-.,:;?!@#$%^&*()+=®©™\\|/\]\[\}\{<>~`[:word:] ]+}, '').squeeze(' ').strip
  end

end
