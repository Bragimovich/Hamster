class Scraper < Hamster::Scraper

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def fetch_main_page
    connect_to('https://elicense.az.gov/ARDC_LicenseSearch#')
  end

  def fetch_search_page(values, cookie,type, board = '', state = '', city = '', zip = '',retries = 30)
    headers = {}
    headers['Cookie'] = cookie
    if type == 'individual'
      body = form_body_data(values, state, board, city, zip)
    elsif  type == 'business'
      body = form_business_data(values, state, board, city, zip)
    else
      body = switch_to_business(values)
    end
    connect_to(url: 'https://elicense.az.gov/ARDC_LicenseSearch#', headers: headers, req_body: body, method: :post, proxy_filter: @proxy_filter)
  rescue => exception
    raise if retries <= 1
    fetch_search_page(values, cookie, board, state, city = '', zip = '',type ,retries - 1)
  end

  def get_inner_response(link)
    connect_to(link)
  end

  def fetch_cookie
    fetch_main_page.headers['set-cookie']
  end

  private

  def form_body_data(values, state, board, city, zip)
   string =  "j_id0%3Aj_id61%3Aj_id62%3Aj_id64=j_id0%3Aj_id61%3Aj_id62%3Aj_id64&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ALastName=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3AFirstName=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ACity=#{city}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3AState=#{state}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3AZipCode=#{zip}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3Aj_id95=#{board}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3Aj_id97=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ALicenseNumber=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ADBA=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3Aj_id101=j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3Aj_id101&com.salesforce.visualforce.ViewState=#{CGI.escape values[0]}&com.salesforce.visualforce.ViewStateVersion=#{CGI.escape values[1]}&com.salesforce.visualforce.ViewStateMAC=#{CGI.escape values[2]}" rescue nil
   if string.nil?
    values = values[0]
    string =  "j_id0%3Aj_id61%3Aj_id62%3Aj_id64=j_id0%3Aj_id61%3Aj_id62%3Aj_id64&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ALastName=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3AFirstName=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ACity=#{city}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3AState=#{state}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3AZipCode=#{zip}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3Aj_id95=#{board}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3Aj_id97=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ALicenseNumber=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ADBA=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3Aj_id101=j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3Aj_id101&com.salesforce.visualforce.ViewState=#{CGI.escape values[0]}&com.salesforce.visualforce.ViewStateVersion=#{CGI.escape values[1]}&com.salesforce.visualforce.ViewStateMAC=#{CGI.escape values[2]}"
  end
  string
  end

  def switch_to_business(values)
    string = "AJAXREQUEST=j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3Aj_id65&j_id0%3Aj_id61%3Aj_id62%3Aj_id64=j_id0%3Aj_id61%3Aj_id62%3Aj_id64&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ALastName=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3AFirstName=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ACity=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3AState=%20&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3AZipCode=#&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3Aj_id95=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3Aj_id97=_%01_&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3Aj_id97=_%01_&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ALicenseNumber=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ADBA=&com.salesforce.visualforce.ViewState=#{CGI.escape values[0]}&com.salesforce.visualforce.ViewStateVersion=#{CGI.escape values[1]}&com.salesforce.visualforce.ViewStateMAC=#{CGI.escape values[2]}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3Amenu1%3Aj_id70=j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3Amenu1%3Aj_id70&" rescue nil
    if string.nil?
      values = values[0]
      string = "AJAXREQUEST=j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3Aj_id65&j_id0%3Aj_id61%3Aj_id62%3Aj_id64=j_id0%3Aj_id61%3Aj_id62%3Aj_id64&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ALastName=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3AFirstName=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ACity=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3AState=%20&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3AZipCode=#&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3Aj_id95=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3Aj_id97=_%01_&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3Aj_id97=_%01_&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ALicenseNumber=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3AIndividuals%3ADBA=&com.salesforce.visualforce.ViewState=#{CGI.escape values[0]}&com.salesforce.visualforce.ViewStateVersion=#{CGI.escape values[1]}&com.salesforce.visualforce.ViewStateMAC=#{CGI.escape values[2]}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3Amenu1%3Aj_id70=j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3Amenu1%3Aj_id70&" rescue nil
    end
    string
  end

  def form_business_data(values, state, board, city, zip)
    "j_id0%3Aj_id61%3Aj_id62%3Aj_id64=j_id0%3Aj_id61%3Aj_id62%3Aj_id64&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3ABusiness%3ALastName=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3ABusiness%3ACity=#{city}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3ABusiness%3AState=#{state}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3ABusiness%3AZipCode=#{zip}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3ABusiness%3Aj_id83=#{board}&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3ABusiness%3Aj_id85=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3ABusiness%3ALicenseNumber=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3ABusiness%3ADBA=&j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3Aj_id101=j_id0%3Aj_id61%3Aj_id62%3Aj_id64%3AMenu%3Aj_id101&com.salesforce.visualforce.ViewState=#{CGI.escape values[0]}&com.salesforce.visualforce.ViewStateVersion=#{CGI.escape values[1]}&com.salesforce.visualforce.ViewStateMAC=#{CGI.escape values[2]}"
  end
  
  def fetch_body(values)
    {
      'com.salesforce.visualforce.ViewState' => "#{CGI.escape values[0]}",
      'com.salesforce.visualforce.ViewStateMAC' => "#{CGI.escape values[2]}",
      'com.salesforce.visualforce.ViewStateVersion' => "#{CGI.escape values[1]}",
      'j_id0:ARDC_SiteLogin:loginComponent:loginForm' => 'j_id0:ARDC_SiteLogin:loginComponent:loginForm',
      'j_id0:ARDC_SiteLogin:loginComponent:loginForm:loginButton' => 'Login',
      'j_id0:ARDC_SiteLogin:loginComponent:loginForm:password' => 'Peter901010!',
      'j_id0:ARDC_SiteLogin:loginComponent:loginForm:username' => 'owen.wang@locallabs.com'
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)

    end
    response
  end

end
