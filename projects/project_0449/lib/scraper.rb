class Scraper < Hamster::Scraper
  attr_accessor :response, :cookies, :arguments

  def initialize
    super
    @cookies = {}
  end

  def body(*arguments, &block)
    use = arguments.first.is_a?(Hash) ? arguments.first[:use] : arguments.last[:use]
    case use
    when 'connect_to'
      body_connect_to(*arguments, &block)
    when 'hammer'
      body_hammer(*arguments)
    when 'get_pdf'
      get_pdf(*arguments)
    end
  end

  def body_hammer(*arguments)
    url = arguments.first.is_a?(String) ? arguments.shift : arguments.first[:url]
    sleep = arguments.first[:sleep]
    hammer = Hamster::Scraper::Dasher.new(using: :hammer)
    page = nil
    begin
      page = hammer.get(url)
      sleep(sleep) if sleep
    rescue => e
      puts e.message
    ensure
      hammer.close
    end
    page
  end

  def get_pdf(*arguments)
    url = arguments.first.is_a?(String) ? arguments.shift : arguments.first[:url]
    path = "#{storehouse}store/pdf/"
    Dir.mkdir path unless File.exists?(path)
    arguments = arguments.first.dup
    path = "#{path}#{arguments[:file_name]}"
    connect_to(url, method: :get_file, filename: path)
    File.exists?(path) ? File.read(path) : nil
  end

  def body_connect_to(*arguments, &block)
    @response = connect_to(*arguments, &block)&.body
  end

  def connect_to_set_cookie(*arguments, &block)
    @response = connect_to(*arguments, &block)
    set_cookie
    @response
  end

  def connect_to(*arguments, &block)
    @response = nil
    10.times do
      @response = super(*arguments, &block)
      break if @response&.status && [200, 302, 304].include?(@response&.status)
    end
    @response
  end

  def set_cookie
    unless @cookies.empty?
      @cookies.map { |key, value| "#{key}=#{value}" }.join(";")
      @arguments.first&.merge!(cookies: {"cookie" => @cookies})
    end
    cookie = @response&.headers["set-cookie"]
    return if cookie.nil?
    raw = cookie.split(";").map do |item|
      if item.include?("Expires=")
        item.split("=")
        ""
      else
        item.split(",")
      end
    end.flatten
    raw.each do |item|
      unless item.include?("Path") && item.include?("HttpOnly") && item.include?("Secure") && item.empty?
        name, value = item.split("=")
        @cookies.merge!({ "#{name}" => value })
      end
    end
    @cookies
  end
end