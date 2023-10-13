require 'uri'

class Parser

  def get_table_rows(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//div[@id='department-list']/a"
    parsed_page.xpath(xpath)
  end
  
  def get_all_states(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//*[@id='id_state']/option"
    all_options = parsed_page.xpath(xpath)
    all_states = all_options.map{|x| x.attributes["value"].value}
    all_states.reject!(&:empty?)
    all_states
  end

  def get_url_from_row(file_content)
    file_content.attributes["href"].value
  end

  def get_user_id_and_name_from_row(row)
    row.children[1].children[0].values
  end

  def get_info_from_details_page(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//dl[@class='DefList']"
    parsed_page.xpath(xpath)
  end

  def get_title_from_from_page(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//h1[@class='Article-p Article-p--heading']"
    parsed_page.xpath(xpath)&.first&.text
  end
  
  def get_info_from_hash(file_content)
    hash = {}
    keys, values = [] ,[]
    file_content.elements.each_with_index do |element,index|
      # put first element in key and second in value and so on
      if index % 2 == 0
        keys << element.children[0].text.strip
      else
        values << element.children.text.strip
      end
    end
    # convert keys and values to hash
    keys.zip(values).each do |key,value|
      # remove spaces and convert to lower case
      # remove anydigit from key
      key = key.downcase.gsub(/\d/,"")
      key = key.strip.gsub(":","").gsub("#","").strip.gsub(" ","_")
      hash[key] = value
    end
    hash
  end
end