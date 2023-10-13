class Scraper <  Hamster::Scraper
  def initialize
    @hammer = Dasher.new(using: :hammer, pc:1, headless:true)
    @browser = @hammer.connect
  end 

  def get_main_page
    browser.go_to("https://linxonline.co.pierce.wa.us/linxweb/Booking/GetJailRoster.cfm")
    sleep(2)
    str = ""
    browser.page.cookies.all.keys[1..-1].each do |key|
      str = str + key
      str = "#{str}=#{JSON.parse(browser.page.cookies.all[key].to_json)["attributes"]["value"]}; "
    end
    body = browser.body
    captcha = JSON.parse(browser.network.request.to_json)["params"]["request"]["postData"]
    @hammer.close
    [body, captcha, str[0..-2]]
  end

  def get_inner_page(link, captcha_response, cookie)
    connect_to(url: ("https://linxonline.co.pierce.wa.us" + link), headers: get_headers("https://linxonline.co.pierce.wa.us" + link, cookie), req_body: captcha_response, method: :post)
  end

  private

  def get_headers(url, cookie)
    {
      "Cookie" => cookie,
      "Origin" => "https://linxonline.co.pierce.wa.us",
      "Referer" => url
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304, 302, 500].include?(response.status)
    end
    response
  end

  attr_accessor :browser
end
