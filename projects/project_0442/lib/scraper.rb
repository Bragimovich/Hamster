class Scraper < Connect
  attr_writer :javax_faces_main_p, :google_key, :javax_faces, :service_arr
  def initialize(args)
    super
    @service_arr = @service.clone if @service_arr.nil? || @service_arr.empty? 
  end
  
  def main_page
    delete_cookie
    header({ accept: "html" })
    @link = "https://circuitclerk.lakecountyil.gov/publicAccess/html/common/index.xhtml"
    @url = 'https://circuitclerk.lakecountyil.gov/publicAccess/html/common/selectCase.xhtml'
    connect(url: @link)
    @javax_faces_main_p = @content_html.css("input[name='javax.faces.ViewState']").first.attr("value")
    @content_html
  end

  def search(let_first_name, let_last_name, business_name, first_year, last_year, case_number )
    @let_first_name = let_first_name
    @let_last_name = let_last_name
    @business_name = business_name
    @case_number = case_number
    @first_year = first_year
    @last_year = last_year
    
    if @business_name.empty? && @case_number.empty?
      @type_selector = "P"
      @type_selector_input = "Person"
    elsif @case_number.empty?
      @type_selector = "B"
      @type_selector_input = "Business"
    elsif @business_name.empty?
      @type_selector = "C"
      @type_selector_input = "Case Number"
    end

    send_request

    @google_key = @content_html.css(".g-recaptcha").first.attr("data-sitekey") rescue nil
    @javax_faces = @content_html.css("input[name='javax.faces.ViewState']").first.attr("value")
    @content_html
  end

  def send_request
    search_params = {
      "searchPanel"=> "searchPanel",
      "searchPanel:searchTypeSelector"=> @type_selector,
      "searchPanel:searchTypeSelectorInput"=> @type_selector_input,
      "searchPanel:firstNameInput"=> @let_first_name,
      "searchPanel:lastNameInput"=> @let_last_name,
      "searchPanel:businessNameInput"=> @business_name,
      "searchPanel:dobInput1"=> "",
      "searchPanel:caseNumberInput"=> @case_number,
      "searchPanel:caseGroupSelector"=> "D",
      "searchPanel:caseGroupSelectorInput"=> "All",
      "searchPanel:caseStatusSelector"=> "D",
      "searchPanel:caseStatusSelectorInput"=> "All",
      "searchPanel:fromDateInputInputDate"=> @first_year,
      "searchPanel:fromDateInputInputCurrentDate"=> (Time.now).strftime("%m/%Y").to_s,
      "searchPanel:toDateInputInputDate"=> @last_year,
      "searchPanel:toDateInputInputCurrentDate"=> (Time.now).strftime("%m/%Y").to_s,
      "searchPanel:acceptTerms"=> "on",
      "searchPanel:secureText"=> "true",
      "searchPanel:submitButton"=> "SUBMIT",
      "javax.faces.ViewState"=>  @javax_faces_main_p
    }
    @logger.debug(@business_name)
    req_body = search_params.map {|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
    header({ accept: "url_post" })
    connect(url: @link, req_body: req_body, method: :post)
    @javax_faces_search_p = @content_html.css("input[name='javax.faces.ViewState']").first.attr("value")
    @content_html
  end

  def num_records
    @content_html.css("span[id='caseSelectPanel:label-title2']").text.scan(/(\d)/).join.to_i rescue nil
  end

  def index_page
    request_query = {
      'caseSelectPanel' => 'caseSelectPanel',
      'caseSelectPanel:secureText' => 'true',
      'javax.faces.ViewState' => @javax_faces_search_p,
      'javax.faces.source' => 'caseSelectPanel:caseDetailsTableHeader:ds',
      'javax.faces.partial.event' => 'rich:datascroller:onscroll',
      'javax.faces.partial.execute' => 'caseSelectPanel:caseDetailsTableHeader:ds @component',
      'javax.faces.partial.render' => '@component',
      'caseSelectPanel:caseDetailsTableHeader:ds:page' => 'next',
      'org.richfaces.ajax.component' => 'caseSelectPanel:caseDetailsTableHeader:ds',
      'caseSelectPanel:caseDetailsTableHeader:ds' => 'caseSelectPanel:caseDetailsTableHeader:ds',
      'rfExt' => 'null',
      'AJAX:EVENTS_COUNT' => '1',
      'javax.faces.partial.ajax' => 'true'
    }
    req_body = request_query.map {|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
    header({ accept: "url_post" })
    connect(url: @url, req_body: req_body, method: :post)
    @content_html

  end

  def url_encoded_query(num)
    return nil if @google_key.nil?
    captcha
    req_src = {
      "caseSelectPanel" => "caseSelectPanel",
      "caseSelectPanel:secureText" => "true",
      "g-recaptcha-response" => @capcha_text,
      "caseSelectPanel:submitButton" => "SUBMIT",
      "selectCaseRadio" => num.to_s,
      "javax.faces.ViewState" => @javax_faces
      }

    @logger.debug('Business:' + @business_name)
    @logger.debug('Case:' + @case_number)
    @logger.debug('Person:' + @let_first_name + @let_last_name)
    @logger.debug('Record:' + num.to_s)
    @logger.debug('Captcha:' + @capcha_text)

    request = req_src.map {|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
    connect(url: @url, method: :post, req_body: request)
    if @business_name.empty? && @case_number.empty?
      peon.put(file: "#{@let_first_name}-#{@let_last_name}_#{num}.html", content: @raw_content.body)
      return [@content_html, "#{@let_first_name}-#{@let_last_name}_#{num}.html"]
    elsif @case_number.empty?
      peon.put(file: "#{@business_name.gsub("%","_")}#{num}.html", content: @raw_content.body)
      return [@content_html, "#{@business_name.gsub("%","_")}#{num}.html"]
    elsif @business_name.empty?
      peon.put(file: "case_#{@case_number.gsub(' ','')}.html", content: @raw_content.body)
      return [@content_html, "case_#{@case_number.gsub(' ','')}.html"]
    end
  end

  def captcha
    counts_captcha = 5
    service = @service_arr.sample
    begin
      @logger.debug("captcha start")
      client = Hamster::CaptchaAdapter.new(service, timeout:200, polling:10)
      @logger.debug(service)
      @logger.debug(@service_arr)
      raise "Low Balance" if client.balance < 1
        options = {
          pageurl: @link,
          googlekey: @google_key
        }
      unless (options[:pageurl] && options[:googlekey]).nil?
          decoded_captcha = client.decode_recaptcha_v2(options)
        if decoded_captcha.text.nil?
          @logger.debug("Error: Balance Captcha: " + client.balance)
          @logger.error("Error: Balance Captcha: " + client.balance)
          raise "Decode text Null"
        end
        @capcha_text = decoded_captcha.text
      end
    rescue
      @logger.debug("Error: Balance Captcha: " + client.balance.to_s )
      @logger.error("Error: Balance Captcha: " + client.balance.to_s )
      retry if (counts_captcha -=1) >= 0
      if client.balance < 1
        @service_arr.delete_at(@service_arr.index(service))
        counts_captcha = 5
        service = @service_arr.first
        retry unless @service_arr.empty?
      end
    end
    @logger.debug("Balance Captcha: " + client.balance.to_s)
    @logger.debug("captcha end")
    client.balance.to_f
  end
end
