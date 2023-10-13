class Scraper <  Hamster::Scraper

  def alpha_page_request(url, search_params)
    body = "g-recaptcha-response=&search=#{search_params}&layout=list"
    connect_request(url, body)
  end

  def second_alpha_page_request(url, search_params, alphabet)
    body = "g-recaptcha-response=&search=#{search_params}#{alphabet}&layout=list"
    connect_request(url, body)
  end

  def third_alpha_page_request(url, search_params, alphabet, alpha)
    body = "g-recaptcha-response=&search=#{search_params}#{alphabet}#{alpha}&layout=list"
    connect_request(url, body)
  end

  private

  def connect_request(url, body)
    connect_to(url: url, req_body: body, headers: post_headers, method: :post)
  end

  def post_headers
    {
      "Accept"          => '*/*',
      "Accept-Language" => 'en-US,en;q=0.9',
      "Host"            => 'find.pitt.edu',
      "Origin"          => 'https://find.pitt.edu',
      "Referer"         => 'https://find.pitt.edu/'
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
