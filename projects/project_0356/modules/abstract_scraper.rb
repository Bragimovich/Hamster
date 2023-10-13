module ExtConnectTo
  attr_reader :raw_content, :cookie

  def init_var
    @cookie = {} #An object with cookies
    @headers = {
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
      'Accept-Language' => 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
      'Connection' => 'keep-alive'
    } #An object with header parameters
  end

  def cookies
    @cookie.map { |key, value| "#{key}=#{value}" }.join(';')
  end

  def connect_to(*arguments, &block)
    arguments.first.merge!({ cookies: { 'cookie' => cookies }, headers: @headers }) unless @cookie.empty?
    @raw_content   = Hamster.connect_to(*arguments, &block)
    raw_set_cookie = @raw_content.headers["set-cookie"]
    set_cookie(raw_set_cookie)
    url                       = arguments.first[:url]
    @headers['Referer']       = url
    base_url_uri              = URI.parse(url)
    base_url                  = "#{base_url_uri.scheme}://#{base_url_uri.host}"
    arguments.first[:cookies] = { 'cookie' => cookies } unless @cookie.empty?

    if @raw_content.status == 302
      location                  = @raw_content.headers['location']
      arguments.first[:headers] = @headers
      arguments.first[:url]     = "#{base_url}/#{location}"
      @raw_content              = Hamster.connect_to(*arguments, &block)
    end
    @raw_content
  end

  def set_cookie(raw_cookie)
    return if raw_cookie.nil?
    raw = raw_cookie.split(';').map do |item|
      if item.include?('Expires=')
        item.split('=')
        ''
      else
        item.split(',')
      end
    end
    raw.flatten.each do |item|
      if !item.include?('Path') && !item.include?('HttpOnly') && !item.include?("Secure") && !item.include?("secure") && !item.include?("Domain") && !item.include?("path") && !item.empty?
        name, value = item.split('=')
        @cookie.merge!({ "#{name}" => value })
      end
    end
  end
end
