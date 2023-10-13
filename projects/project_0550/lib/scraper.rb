require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  def initialize
    super
    @cookie = 'ASP.NET_SessionId=mk1a1q3hfxgoopjjclvc4ldb'
    proxies = Camouflage.new
    @proxy = proxies.swap
  end

  def generate_session
    url = 'https://www.meganslaw.ca.gov/Disclaimer.aspx'
    resp = connect_to(url: url, proxy: @proxy, ssl_verify: false)
    form_data = Parser.new(resp.body).form_data
    form_data['g-recaptcha-response'] = solve_captcha
    form_data = URI.encode_www_form(form_data)
    
    headers = {
      'Referer' => url,
      'Authority' => 'www.meganslaw.ca.gov',
      'Cookie' => @cookie
    }
    connect_to(url: url, proxy: @proxy, req_body: form_data, headers: headers, method: :post, ssl_verify: false)
  end

  def get_cities()
    url = 'https://www.meganslaw.ca.gov/Search.aspx'
    headers = { 'Cookie' => @cookie }
    resp = connect_to(url: url, proxy: @proxy, headers: headers, ssl_verify: false)
    Parser.new(resp.body).cities
  end

  def get_data_by_city(city)
    payload = { 'City' => city, 'IncludeTransient' => false }.to_json
    url = 'https://www.meganslaw.ca.gov/CASOMA.svc/DoCitySearchLoc'

    response = connect_to(url: url, proxy: @proxy, req_body: payload, headers: headers, method: :post, ssl_verify: false)
    JSON.parse(response.body)['d']['Offenders']
  end

  def get_offender(id)
    payload = { 'OffenderID' => id }.to_json
    url = 'https://www.meganslaw.ca.gov/CASOMA.svc/GetOffenderFull'

    response = connect_to(url: url, proxy: @proxy, req_body: payload, headers: headers, method: :post, ssl_verify: false)
    res = JSON.parse(response.body)['d']
    url = "https://www.meganslaw.ca.gov/PI.ashx?t=f&f=#{res['FCN']}&p=#{res['Path']}"
    res['mugshot_link'] = url
    res['mugshot'] = mugshot(url)
    res
  end

  def mugshot(url)
    headers = {
      'Referer' => 'https://www.meganslaw.ca.gov/Search.aspx',
      'Authority' => 'www.meganslaw.ca.gov',
      'Cookie' => @cookie
    }
    response = connect_to(url: url, proxy: @proxy, headers: headers, ssl_verify: false)
    response.body
  end

  private

  def headers
    {
      'Content-Type' => 'application/json',
      'Referer' => 'https://www.meganslaw.ca.gov/Search.aspx',
      'Authority' => 'www.meganslaw.ca.gov',
      'Cookie' => @cookie
    }
  end

  def solve_captcha
    options = {
      pageurl: 'https://www.meganslaw.ca.gov/Disclaimer.aspx',
      googlekey: '6LeiLSUTAAAAABFTa8CGC4hrKVlydJsTs6p2utO4'
    }
    captcha_client = Hamster::CaptchaAdapter.new(:two_captcha_com, timeout:200, polling:10)

    money = captcha_client.balance
    p money
    if money < 1
      Hamster.report(to: 'Gabriel Carvalho', message: 'Project #550 2captcha balance < 1')
      return nil
    end

    decoded_captcha = captcha_client.decode_recaptcha_v2!(options)
    decoded_captcha.text
  rescue StandardError => e
    p e
    p e.full_message
    Hamster.report(to: 'Gabriel Carvalho', message: "Project #550 solve_captcha:\n#{e}")
    nil
  end
end
