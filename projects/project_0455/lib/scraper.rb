class Scraper < Hamster::Scraper
  attr_accessor :response, :cookies, :arguments

  def initialize(scraper_name = 'vyacheslav pospelov')
    safe_connection { super }
    @scraper_name = scraper_name
    @cookies = {}
  end


  def body(*arguments, &block)
    use = arguments.first.is_a?(Hash) ? arguments.first[:use] : arguments.last[:use]
    safe_connection {
      case use
      when 'connect_to'
        body_connect_to(*arguments, &block)
      when 'hammer'
        body_hammer(*arguments)
      when 'get_pdf'
        get_pdf(*arguments)
      end
    }
  end

  def body_hammer(*arguments)
    url = arguments.first.is_a?(String) ? arguments.shift : arguments.first[:url]
    hammer = Hamster::Scraper::Dasher.new(using: :hammer)
    page = nil
    begin
      page = hammer.get(url)
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
    File.read(path)
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
      if !item.include?("Path") && !item.include?("HttpOnly") && !item.include?("Secure") && !item.empty?
        name, value = item.split("=")
        @cookies.merge!({ "#{name}" => value })
      end
    end
    @cookies
  end

  def safe_connection
    begin
      Thread.abort_on_exception = true
      result = nil
      thread1 = Thread.new do
        result = yield if block_given?
      end
      thread2 = Thread.new do
        raise_time = 1.minutes.after
        sleep(1) while Time.now < raise_time
        if Time.now > raise_time
          Thread.kill thread1
          raise 'Connection Error!'
        end
      end
      thread1.join
      Thread.kill thread2
      result
    rescue ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout,
      RuntimeError => e
      begin
        puts "#{e.message}"
        puts '*'*77, "Reconnect!", '*'*77
        Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} connect_to Reconnecting..."
      rescue => e
        puts e.full_message
        sleep 10
        retry
      end
      retry
    end
  end
end