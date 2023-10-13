require 'socksify/http'
class Scraper < Hamster::Scraper

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def initialize
    super
  end

  def fetch_main_page
    connect_to('https://elicense.ohio.gov/OH_HomePage')
  end

  def auth_page_request
    connect_to('https://elicense.ohio.gov/oh_verifylicense?board=Cosmetology+and+Barber+Board&firstName=&lastName=&licenseNumber=&searchType=individual')
  end

  def data_request(board, search_type, authorization, first_name, last_name)
    connect_to(url: "https://elicense.ohio.gov/apexremote", headers: request_headers, req_body: request_body(board, search_type, authorization, first_name, last_name) , method: :post)
  end

  def request_headers
    {
      "Content-Type": "application/json",
      "Origin": "https://elicense.ohio.gov",
      "Referer": "https://elicense.ohio.gov/oh_verifylicense?board=Cosmetology+and+Barber+Board&firstName=&lastName=&licenseNumber=&searchType=individual",
    }
  end

  def request_body(board, search_type, authorization, first_name, last_name)
    business_name = ''
    business_board = ''
    if search_type == 'business'
      business_name = "#{first_name}#{last_name}"
      business_board = board
      first_name = last_name = board = ''
    end
    [{"action":"OH_VerifyLicenseCtlr","method":"fetchmetadata","data":["#{board}",""],"type":"rpc","tid":2,"ctx":{"csrf": "#{authorization[2]}","vid":"066t0000000L0A9","ns":"","ver":41,"authorization": "#{authorization[0]}"}},{"action":"OH_VerifyLicenseCtlr","method":"findLicensesForOwner","data":[{"firstName":"#{first_name}","lastName":"#{last_name}","middleName":"","contactAlias":"","board":"#{board}","licenseType":"","licenseNumber":"","city":"","state":"none","county":"","businessBoard":"#{business_board}","businessLicenseType":"","businessLicenseNumber":"","businessCity":"","businessState":"none","businessCounty":"","businessName":"#{business_name}","dbafileld":"","searchType":"#{search_type}"}],"type":"rpc","tid":3,"ctx":{"csrf":"#{authorization[3]}","vid":"066t0000000L0A9","ns":"","ver":41,"authorization":"#{authorization[1]}"}}].to_json
  end

  private

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block) 
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

end
