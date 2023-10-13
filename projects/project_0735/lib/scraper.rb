class Scraper < Hamster::Scraper

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def connect_main_page
    connect_to('http://www.gwinnettcountysheriff.com/smartwebclient/')
  end

  def connect_page(generator_values, last_name, first_name)
    body = form_body(generator_values, last_name, first_name)
    connect_to('http://www.gwinnettcountysheriff.com/smartwebclient/' ,headers: get_headers, req_body: body, method: :post)
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

  def form_body(generator_values, last_name, first_name)
    "ScriptManager1=ScriptManager1%7CbtnSumit&__EVENTTARGET=&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape generator_values[1]}&__VIEWSTATEGENERATOR=#{CGI.escape generator_values[2]}&__EVENTVALIDATION=#{CGI.escape generator_values[0]}&txbLastName=#{CGI.escape last_name}&txbFirstName=#{CGI.escape first_name}&txbMiddleName=&tbBeginDate=&tbEndDate=&tbBeginReleaseDate=&tbEndReleaseDate=&TypeSearch=2&SearchSortOption=0&SearchOrderOption=0&txtUserName=&txtPassword=&__ASYNCPOST=true&btnSumit=Submit"
  end

  def get_headers
    {
     "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8",
     "Accept-Language" => "en-US,en;q=0.9",
     "Cache-Control" => "no-cache",
     "Connection" => "keep-alive,",
     "Origin" => "http://www.gwinnettcountysheriff.com",
     "Pragma" => "no-cache",
     "Referer" => "http://www.gwinnettcountysheriff.com/smartwebclient/",
    }
  end

end
