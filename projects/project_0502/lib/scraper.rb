class Scraper < Hamster::Scraper
  attr_accessor :response, :cookies, :arguments

  def initialize(scraper_name = 'vyacheslav pospelov')
    super
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
      hammer.close
      puts e.message
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
      hammer.close
    end
    body
  end

  def hammer_browser(*arguments)
    close_browser if @browser

    url = arguments.first.is_a?(String) ? arguments.shift : arguments.first[:url]
    sleep = arguments.first[:sleep]
    expected_css = arguments.first[:expected_css]
    save_path = arguments.first[:save_path]
    headless = arguments.first[:headless]
    timeout = arguments.first[:timeout]

    options = { using: :hammer }
    options.merge!( save_path: save_path) if save_path
    options.merge!( headless: headless) if headless
    options.merge!( timeout: timeout) if timeout

    @dasher = Dasher.new(options)

    retries = 0
    begin
      @browser = @dasher.connect
      user_agent = FakeAgent.new.any
      @browser.headers.set(
        "User-Agent" => user_agent
      )
      @browser.go_to(url)
      # for ajax use @browser.network.wait_for_idle(60)

      if sleep && expected_css
        wait_css_with_refresh(expected_css, sleep)
        if @browser.at_css(expected_css).nil?
          raise "Waited css not found. Retry ##{retries}"
        end
      elsif sleep
        @browser.wait_for_reload(60)
        sleep(sleep)
      end
    rescue => e
      puts e.full_message
      retries += 1
      retry if retries < 10
    end
    @browser
  end

  def wait_css(expected_css, sleep)
    start_time = Time.now
    if @browser.at_css(expected_css).nil? && (Time.now - start_time) < sleep
      sleep(0.5)
    end
  end

  def wait_file_with_refresh(sleep, path, url)
    @browser.wait_for_reload(sleep)
    begin
      return unless  Dir.empty?(path)

      @browser.refresh
      @browser.wait_for_reload(sleep)
      sleep(2)
    rescue
      # Ignored
    end
    begin
      return unless  Dir.empty?(path)

      @browser.back
      sleep(2)
      #@browser.wait_for_reload(60)
      sleep(2)
      @browser.forward
      @browser.wait_for_reload(sleep)
      sleep(2)
    rescue
      # Ignored
    end
    begin
      return unless  Dir.empty?(path)

      @browser.create_page do |page|
        page.go_to(url)
        puts "download url=#{url}"
        sleep(sleep)
        page.body
      end

      sleep(sleep)

      return unless  Dir.empty?(path)
    rescue
      # Ignored
    end
  end

  def wait_css_with_refresh(expected_css, sleep)
    @browser.wait_for_reload(60)
    wait_css(expected_css, sleep)
    if @browser.at_css(expected_css).nil?
      @browser.refresh
      @browser.wait_for_reload(60)
      wait_css(expected_css, sleep)
    end
    if @browser.at_css(expected_css).nil?
      @browser.back
      sleep(2)
      @browser.forward
      @browser.wait_for_reload(60)
      wait_css(expected_css, sleep)
    end
    sleep(sleep)
  end

  def close_browser
    @dasher.close
  end

  def get_pdf(*arguments)
    url = arguments.first.is_a?(String) ? arguments.shift : arguments.first[:url]
    arguments = arguments.first.dup
    path = "#{storehouse}store/pdf"
    Dir.mkdir path unless File.exists?(path)
    FileUtils.rm_rf("#{path}/.", secure: true)
    if arguments[:use_browser]
      retries = 0
      begin
        @browser = hammer_browser(
          url: url,
          sleep: 5,
          save_path: path,
          headless: false
        )
        #@browser.pdf(path: path)
        wait_file_with_refresh(15, path, url)
        #@browser.network.wait_for_idle

        raise "PDF not downloading" if Dir.empty?(path)

        file_path = Dir.glob("#{path}/*").first
        puts "file_path= #{file_path}"
        start_time = Time.now
        while file_path.include?(".crdownload")
          sleep(0.5)
          break if Time.now - start_time >= 600
        end

        raise "PDF not downloading" if file_path.include?(".crdownload")

      rescue => error
        puts error.full_message
        retries += 1
        retry if retries < 10 && error.message.include?("PDF not downloading")
      end
    else
      file_path = arguments[:file_name].blank? ? nil : "#{path}#{arguments[:file_name]}"
      connect_to(url, method: :get_file, filename: file_path)
    end
    #sleep(10)
    content = File.read(file_path) if file_path
    FileUtils.rm_rf("#{path}/.", secure: true)
    content
  end

  def body_connect_to(*arguments, &block)
    retries = 0
    begin
      @response = connect_to(*arguments, &block)&.body
      retries =+ 1
    rescue => e
      puts e.full_message
      Hamster.report(
        to: @scraper_name,
        message: "project-#{Hamster::project_number} --download: \n body_connect_to args = #{arguments} \n error = #{e.full_message}",
        use: :both
      ) if retries > 7
      sleep(20)
      retries < 10 ? retry : return
    end
    @response
  end

  def connect_to_set_cookie(*arguments, &block)
    @response = connect_to(*arguments, &block)
    set_cookie
    @response
  end

  def connect_to(*arguments, &block)
    @response = nil
    safe_connection {
      10.times do
        @response = super(*arguments, &block)
        break if @response&.status && [200, 302, 304].include?(@response&.status)
      end
    }
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

  def safe_connection
    begin
      yield if block_given?
    rescue ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout => e
      begin
        ActiveRecord::Base.establish_connection(Storage.use(host: :db02, db: :mysql)).connection.reconnect!
        puts "#{e.message}"
        puts '*'*77, "Reconnect!", '*'*77
        Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} connect_to Reconnecting..."
        sleep 10
      rescue => e
        puts e.full_message
        sleep 10
        retry
      end
      retry
    end
  end
end