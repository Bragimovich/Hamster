require_relative '../models/all_states'
require_relative '../models/all_cities'
class Parser
  BASE_URL = "http://rijrs.courts.ri.gov/rijrs"

  def get_all_records(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//table[@class='displayTable']/tbody"
    parsed_page.xpath(xpath).children
  end
  
  def parse_rows(rows)
    records = []
    rows.each do |row|
      if row.is_a?(Nokogiri::XML::Element)
        hash = {}
        cols = row.children.select { |c| c.is_a?(Nokogiri::XML::Element) }
        hash['href']  = cols[0].children[1]['href']
        hash['data_source_url'] = BASE_URL + hash['href'][1..-1]
        hash['bar_number'] = hash['href'].match(/\d{3,}/).to_s
        hash['md5_hash'] = Digest::MD5.hexdigest(hash['data_source_url'])
        full_name = cols[0].children[1].text
        hash['name'] = full_name
        name_prefix_pattern = /JR\.?,|jr\.?,|Jr\.?,|\sI\.?\s|III\,?|II\,?|\sIV,/

        title = full_name.match(name_prefix_pattern)&.to_s
        hash['name_prefix'] =  title
        # @last_name ,@remaining_name = full_name.split(',')
        # @last_name = @last_name.gsub(name_prefix_pattern," ")
        # @first_name , @middle_name = @remaining_name.split(' ')

        # @last_name , @first_name ,@middle_name = full_name.gsub(name_prefix_pattern,"").split(' ')
        # if @first_name&.nil? or @first_name&.empty?
        #   @first_name = @last_name
        #   @last_name = @middle_name
        #   @middle_name = nil
        # end
        # hash['first_name'] =  @first_name&.sub(",","")
        # hash['last_name'] = @last_name&.sub(",","")
        # hash['middle_name'] = @middle_name&.sub(".","")
        # hash['address'] = cols[1].text
        hash['email'] = cols[2].text
        hash['phone'] = cols[3].text
        records << hash
      end
    end
    records
  end

  def parse_inner_page(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    hash = {}
    table_rows = parsed_page.css('.table').xpath('tr')
    law_firm_city_state_zip_regex = /\w.+,\s{1,}\w{2,}\s{1,}\d{1,}-?\d+/

    law_firm_city_state_zip = nil
    table_rows.each do |row|
      match = row.text.match(law_firm_city_state_zip_regex) 
      if match
        law_firm_city_state_zip  = row.text
        break
      end
    end

    if table_rows[1]&.text&.match(/\d/).present?
      hash['raw_name_or_address'] = nil
      ind = 1
      # hash['law_firm_address'] = table_rows[1].text + ' ' + table_rows[2].text 
    else
      hash['raw_name_or_address'] = table_rows[1].text
      ind = 2
      # hash['law_firm_address'] = table_rows[2].text
    end

    temp_address = ""
    
    table_rows[ind..5].each do |row|
      if row.text.match(law_firm_city_state_zip_regex)
        break
      else
        temp_address += row.text + ' '
      end
    end
    
    hash['raw_address2'] = temp_address
    hash['law_firm_city_state_zip'] = law_firm_city_state_zip
    
    city , state_zip = hash['law_firm_city_state_zip']&.split(',')
    state , zip = state_zip&.split(' ')
    
    hash['law_firm_city'] = city
    hash['law_firm_state'] = state
    hash['law_firm_zip'] = zip
    hash['registration_status'] = table_rows[10].text
    hash['date_admited'] = table_rows[7].text
    hash
  end

  def extract_state(address)
    if address.present?
      all_states = AllStates.pluck(:short_name)
      all_states.each do |state|
        if address.downcase.split(' ').include?(state.downcase)
          return state
        end
      end
    end
    nil
  end

  def extract_city(address)
    all_cities = AllCities.pluck(:short_name).uniq
    if address.present?
      all_cities.each do |city|
        if address.downcase.include?(city.downcase)
          return city
        end
      end
      all_cities.each do |city|
        if address.downcase.split(' ').include?(city.downcase)
          return city
        end
      end
    end
    nil
  end

end