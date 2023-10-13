class Scraper < Hamster::Scraper
  attr_accessor :response, :cookies, :arguments

  def initialize(scraper_name = 'vyacheslav pospelov')
    safe_connection { super }
    @scraper_name = scraper_name
    @cookies = {}
  end


  def body(*arguments, &block)
    use = arguments.first.is_a?(Hash) ? arguments.first[:use] : arguments.last[:use]
    url = arguments.first.is_a?(String) ? arguments.shift : arguments.first[:url]

    return if url.blank?
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
    sleep = arguments.first[:sleep]
    wait_css = arguments.first[:wait_css]
    retries = 0
    begin
      hammer = Hamster::Scraper::Dasher.new(using: :hammer)
      retries =+ 1
      body = hammer.get(url)
    rescue => e
      hammer&.close
      Hamster.logger.info e.message
      Hamster.report(
        to: @scraper_name,
        message: "project-#{Hamster::project_number} --download: \n class = #{e.class} \n url = #{url} \n error = #{e.full_message}",
        use: :both
      ) if retries > 7
      sleep(20)
      retries < 10 ? retry : return
    ensure
      start_time = Time.now
      if sleep && wait_css
        while hammer.browser.at_css(wait_css) && (Time.now - start_time) < sleep
          sleep(0.5)
        end
      elsif sleep
        sleep(sleep)
      end
      hammer&.close
    end
    body
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
      unless item.include?("Path") && item.include?("HttpOnly") && item.include?("Secure") && item.empty?
        name, value = item.split("=")
        @cookies.merge!({ "#{name}" => value })
      end
    end
    @cookies
  end

  def safe_connection(retries = 15)
    begin
      yield if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        Hamster.logger.info "#{e.class}"
        sleep 100
        Hamster.report(to: @scraper_name, message: "project-#{Hamster::project_number} Scraper: Reconnecting...")
        ActiveRecord::Base.establish_connection(Storage.use(host: :db02, db: :mysql)).connection.reconnect!
        PaidProxy.connection.reconnect!
        UserAgent.connection.reconnect!
      rescue *connection_error_classes => e
        sleep 100
        retry if retries > 0
      end
      retry if retries > 0
    end
  end

  def connection_error_classes
    [
      ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout
    ]
  end
end