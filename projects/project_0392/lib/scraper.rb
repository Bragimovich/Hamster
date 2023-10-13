require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
    @host = 'www.iowacourts.state.ia.us'
  end

  def cookie
    url = 'https://www.iowacourts.state.ia.us/ESAWebApp/DefaultFrame'
    hamster = Hamster.connect_to(url, proxy_filter: @proxy_filter)
    raise if hamster.status != 200
    hamster.headers['set-cookie'].to_s
  rescue
    puts 'cookie retry'
    retry
  end

  def items(req, cookie)
    url = 'https://www.iowacourts.state.ia.us/ESAWebApp/AViewSearchResultsAdv'
    hamster = Hamster.connect_to(url, proxy_filter: @proxy_filter,
                                        headers: headers_items(cookie), req_body: req,
                                        method: :post, iteration: 9)
    return if hamster.status != 200
    Parser.new.items(hamster)
  end

  def headers_items(cookie)
    {
      'content_type' => 'text/html; =;charset=ISO-8859-1',
      'Cache-Control' => 'max-age=0',
      'Upgrade-Insecure-Requests' => '1',
      'Origin' => 'https://www.iowacourts.state.ia.us',
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.109 Safari/537.36 OPR/84.0.4316.31',
      'Accept'=>'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
      'Sec-Fetch-Site' => 'same-origin',
      'Sec-Fetch-Mode' => 'navigate',
      'Sec-Fetch-Dest' => 'frame',
      'Referer' => 'https://www.iowacourts.state.ia.us/ESAWebApp/ACaseAdvanced',
      'Accept-Language' => 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
      'Cookie' => cookie
    }
  end

  def summary(case_id, cookie)
    url = "https://www.iowacourts.state.ia.us/ESAWebApp/AViewCase?caseid=#{case_id}&screen=null"
    hamster = Hamster.connect_to(url, proxy_filter: @proxy_filter, headers: headers_case(cookie), iteration: 9)
    raise if hamster.status != 200
    hamster
  rescue
    puts 'summary retry'
    retry
  end

  def long(case_id, cookie)
    url = "https://www.iowacourts.state.ia.us/ESAWebApp/AViewLongTitle?caseid=#{case_id}&screen=null"
    hamster = Hamster.connect_to(url, proxy_filter: @proxy_filter, headers: headers_case(cookie), iteration: 9)
    raise if hamster.status != 200
    hamster
  rescue
    puts 'long retry'
    retry
  end

  def docket(case_id, cookie)
    url = "https://www.iowacourts.state.ia.us/ESAWebApp/AViewDocket?caseid=#{case_id}&screen=null"
    hamster = Hamster.connect_to(url, proxy_filter: @proxy_filter, headers: headers_case(cookie), iteration: 9)
    raise if hamster.status != 200
    hamster
  rescue
    puts 'docket retry'
    retry
  end

  def parties(case_id, cookie)
    url = "https://www.iowacourts.state.ia.us/ESAWebApp/AViewParties?caseid=#{case_id}&screen=null"
    hamster = Hamster.connect_to(url, proxy_filter: @proxy_filter, headers: headers_case(cookie), iteration: 9)
    raise if hamster.status != 200
    Parser.new.parties(hamster)
  rescue
    puts 'parties retry'
    retry
  end

  def headers_case(cookie)
    {
      'content_type' => 'text/html; =;charset=ISO-8859-1',
      'Cache-Control' => 'max-age=0',
      'Upgrade-Insecure-Requests' => '1',
      'Origin' => 'https://www.iowacourts.state.ia.us',
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.109 Safari/537.36 OPR/84.0.4316.31',
      'Accept'=>'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
      'Sec-Fetch-Site' => 'same-origin',
      'Sec-Fetch-Mode' => 'navigate',
      'Sec-Fetch-Dest' => 'frame',
      'Referer' => 'https://www.iowacourts.state.ia.us/ESAWebApp/AIndexTopFrm',
      'Accept-Language' => 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
      'Cookie' => cookie
    }
  end

  def party(url, cookie)
    hamster = Hamster.connect_to(url, proxy_filter: @proxy_filter, headers: headers_party(cookie), iteration: 9)
    raise if hamster.status != 200
    hamster
  rescue
    puts 'party retry'
    retry
  end

  def headers_party(cookie)
    {
      'content_type' => 'text/html; =;charset=ISO-8859-1',
      'Cache-Control' => 'max-age=0',
      'Upgrade-Insecure-Requests' => '1',
      'Origin' => 'https://www.iowacourts.state.ia.us',
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.109 Safari/537.36 OPR/84.0.4316.31',
      'Accept'=>'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
      'Sec-Fetch-Site' => 'same-origin',
      'Sec-Fetch-Mode' => 'navigate',
      'Sec-Fetch-Dest' => 'document',
      'Referer' => 'https://www.iowacourts.state.ia.us/ESAWebApp/AViewParties',
      'Accept-Language' => 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
      'Cookie' => cookie
    }
  end
end
