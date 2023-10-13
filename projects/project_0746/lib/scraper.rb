class Scraper < Hamster::Scraper

  def main_page_request
    connect_to('http://www.doc.state.co.us/oss/')
  end

  def inner_page_request(cookie, name_flag, key, start)
    first_name = nil
    last_name = nil
    name_flag ? first_name = key : last_name = key
    url = "http://www.doc.state.co.us/oss/controller/ctl_ajax.php"
    body = "docno=&lnam=#{last_name}&fnam=#{first_name}&gender=ALL&sec=list_offenders&search=true&start=#{start}&order_col=undefined&order_dir=undefined" if start == 0
    body = "docno=&lnam=#{last_name}&fnam=#{first_name}&gender=ALL&sec=list_offenders&search=false&start=#{start}&order_col=offender_name&order_dir=ASC" unless start == 0
    headers = get_headers(cookie)
    connect_to(url, headers: headers, req_body:body, method: :post)
  end

  def get_data_page(id, cookie)
    url = "http://www.doc.state.co.us/oss/controller/ctl_ajax.php"
    body = "docno=#{id}&sec=offender_profile"
    headers = get_headers(cookie)
    connect_to(url, headers: headers, req_body:body, method: :post)
  end

  def get_headers(cookie)
     {
      "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8",
      "Accept" => "text/javascript, text/html, application/xml, text/xml, */*",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cookie" => cookie,
      "Origin" => "http://www.doc.state.co.us",
      "Proxy-Connection" => "keep-alive",
      "Referer" => "http://www.doc.state.co.us/oss/",
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
