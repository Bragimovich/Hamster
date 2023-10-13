require_relative '../models/all_states'
require_relative '../models/all_cities'
require 'uri'

class Parser

  def initialize
    @all_states = AllStates.pluck(:short_name)
    @all_cities = AllCities.pluck(:short_name).uniq
  end

  def get_required_form_data_variables(file_content)
    script_manager_tsm = get_script_manager_tsm(file_content)
    data = Nokogiri::HTML(file_content)
    __VIEWSTATE = data.css("#__VIEWSTATE")[0]["value"]
    __VIEWSTATEGENERATOR = data.css("#__VIEWSTATEGENERATOR")[0]["value"]
    __pageInstanceKey = data.css("#PageInstanceKey")[0]["value"]
    __RequestVerificationToken = data.css("#__RequestVerificationToken")[0]["value"]
    __ClientContext = data.css("#__ClientContext")[0]["value"]

    # hard coded below for the first request of submit action
    __EVENTTARGET = "ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$Sheet0$SubmitButton"
    manager = 'ctl01$TemplateBody$WebPartManager1$gwpciAttorneySearch$ciAttorneySearch$ResultsGrid$Sheet0$SubmitButton'
    {
      view_state: __VIEWSTATE,
      view_state_gen: __VIEWSTATEGENERATOR,
      page_instance_key: __pageInstanceKey,
      event_target: __EVENTTARGET,
      request_verification_token: __RequestVerificationToken,
      client_context: __ClientContext,
      manager: manager,
      script_manager_tsm: script_manager_tsm
    }
  end
  
  def parse_html_constants(body)
    view_state_index = body.index('__VIEWSTATE|')
    view_state_body = body[view_state_index+12..-1]
    view_state_index = view_state_body.index('|')
    view_state = view_state_body[0...view_state_index]
    
    view_state_generator_index = body.index('__VIEWSTATEGENERATOR|')
    view_state_generator_body = body[view_state_generator_index+21..-1]
    view_state_generator_index = view_state_generator_body.index('|')
    view_state_generator = view_state_generator_body[0...view_state_generator_index]

    r_token_index = body.index('__RequestVerificationToken|')
    r_token_body = body[r_token_index+27..-1]
    r_Token_index = r_token_body.index('|')
    request_verification_token = r_token_body[0...r_Token_index]

    [view_state,view_state_generator, request_verification_token]
  end

  def get_event_target_given_page_number(body,page_number)
    str = "Go to page #{page_number}"
    # from this till last
    unless body.index(str).nil?
      temp = body[body.index(str)..-1]
      _temp = temp[temp.index("javascript:__doPostBack(")..-1].split(")")[0]
      return _temp.split(";")[1].split("&")[0]
    else
      nil
    end
  end

  def get_script_manager_tsm(body)
    str = "/Telerik.Web.UI.WebResource.axd?_TSM_HiddenField_="
    end_str = 'type="text/javascript"></script>'
  
    unless body.index(str).nil?
      temp = body[body.index(str) + str.length..-1]
      _pub = temp.split(end_str)[0].gsub(" ","").gsub("\"",'')
      remove_str = 'ctl01_ScriptManager1_TSM&amp;compress=1&amp;_TSM_CombinedScripts_='
      pub = URI.decode(_pub)
      pub[remove_str] = ""
      return pub
    end
    nil
  end
  
  def get_page_instance_key(body)
    ind = body.index("PageInstanceKey|")
    body[ind+16..-1].split('|')[0]
  end

  def get_table_rows(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//div[@id='ctl01_TemplateBody_WebPartManager1_gwpciAttorneySearch_ciAttorneySearch_ResultsGrid_Grid1']/table/tbody/tr"
    parsed_page.xpath(xpath)
  end

  def get_user_id_and_name_from_row(row)
    row.children[1].children[0].values
  end

  def get_info_from_details_page(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//div[@id='ctl01_TemplateBody_WebPartManager1_gwpciAttorneySearchContact_ciAttorneySearchContact_ListerPanel']"
    xpath = "//table[@class='rgMasterTable CaptionTextInvisible']"
    parsed_page.xpath(xpath)
  end
  
  def parse_user_details(grid)
    table_body = grid.xpath("tbody")
    rows = table_body.children[1].children
    {
      full_name: rows[1].children.text,
      full_address:rows[2].children.text,
      current_status:rows[3].children.text,
      admisson_date: rows[4].children.text
    }
  end

  def get_next_page(body)
    str = "Next Pages"
    unless body.index(str).nil?
      temp = body[body.index(str)..-1]
      _temp = temp[temp.index("javascript:__doPostBack(")..-1].split(")")[0]
      return _temp.split(";")[1].split("&")[0]
    else
      nil
    end
  end

  def extract_state(address)
    if address.present?
      @all_states.each do |state|
        if address.downcase.gsub(/\.|,/,"").split(' ').include?(state.downcase)
          return state
        end
      end
    end
    nil
  end

  def extract_city(address)
    if address.present?
      @all_cities.each do |city|
        if address.downcase.split(' ').include?(city.downcase)
          return city
        end
      end
      @all_cities.each do |city|
        if address.downcase.include?(city.downcase)
          return city
        end
      end
    end
    nil
  end

  def extract_zip(address)
    address.match('\d+')&.to_s
  end
end