# frozen_string_literal: true

class Connector
  COOKIE_ATTRIBUTES = %w[path domain expires secure httponly samesite]

  def initialize(connector_options = {})
    @random = Random.new(Time.current.to_i)
    set_connector_options(connector_options)
    reset_cookies
    reset_proxies
  end

  def get(url, request_options = {}, &block)
    rest(url, :get, request_options, &block)
  end

  def post(url, req_body, request_options = {}, &block)
    rest(url, :post, request_options.merge(req_body: req_body), &block)
  end

  def reset_cookies
    @cookies = {}
    @cookies_captured = false
    @fake_agent ||= FakeAgent.new
    @user_agent = @connector_options[:fix_user_agent] || @fake_agent.any
  end

  def reset_proxies
    @current_proxy = nil
    @camouflage = Camouflage.new
    @proxy_filter = ProxyFilter.new

    switch_proxy(false) unless @connector_options[:try_non_proxy]
  end

  def set_connector_options(connector_options = {})
    valid_option_keys = %i[
      delay_connect
      keep_params
      extra_headers
      fix_user_agent
      follow_redirect
      open_timeout
      public_page_url
      rcwsp
      ssl_verify
      timeout
      try_non_proxy
    ]

    valid_options = connector_options.select { |key, _| valid_option_keys.include?(key) }
    @connector_options = default_connector_options.merge(valid_options)
  end

  def switch_proxy(restart_cookies = true)
    @current_proxy = @camouflage.swap
    while @proxy_filter.filter(@current_proxy).nil?
      message('Bad proxy filtered: ', @current_proxy)
      raise 'All proxies banned.' if @camouflage.count <= @proxy_filter.count

      @current_proxy = @camouflage.swap
    end

    reset_cookies if @connector_options[:rcwsp] && restart_cookies
  end

  private

  class SwitchProxyRequiredError < StandardError; end

  class FaradayKeepParamsEncoder
    def self.decode(query)
      return nil if query.nil?
      { whole_params: query }
    end

    def self.encode(params)
      return nil if params.nil?
      return nil unless params.is_a?(Hash)
      params[:whole_params]
    end
  end

  def default_connector_options
    {
      delay_connect:   2,
      keep_params:     false,
      extra_headers:   {},
      fix_user_agent:  nil,
      follow_redirect: true,
      open_timeout:    5,
      public_page_url: nil,
      rcwsp:           true,  # Reset Cookies When Switch Proxy
      ssl_verify:      false,
      timeout:         60,
      try_non_proxy:   true
    }
  end

  def default_header
    {
      'Accept'=> 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language'=> 'en-US,en;q=0.5',
      'Connection' => 'keep-alive',
      'Upgrade-Insecure-Requests' => '1',
      'Sec-Fetch-Dest'=> 'document',
      'Sec-Fetch-Mode' => 'navigate',
      'Sec-Fetch-Site' => 'cross-site',
      'Pragma'=> 'no-cache',
      'Cache-Control'=> 'no-cache (edited)',
    }
  end

  def default_request_options
    {
      rotate_proxy:    true,
      stream_callback: nil,
      user_agent:      nil
    }
  end

  def message(text, proxy, color = :yellow)
    print Time.now.strftime("%H:%M:%S ").colorize(color)
    puts text.colorize(:light_white) + proxy.to_s.colorize(:light_yellow)
  end

  def rest(url, method, request_options = {}, &block)
    valid_option_keys = %i[
      delay_connect
      keep_params
      extra_headers
      follow_redirect
      open_timeout
      public_page_url
      req_body
      rotate_proxy
      ssl_verify
      stream_callback
      timeout
      user_agent
    ]

    valid_options = request_options.select { |key, _| valid_option_keys.include?(key) }
    options = @connector_options.merge(default_request_options).merge(valid_options)

    keep_params     = !!options[:keep_params]
    extra_headers   = options[:extra_headers] || {}
    headers         = default_header.merge(extra_headers)
    ssl_verify      = !!options[:ssl_verify]
    timeout         = options[:timeout] || 60
    open_timeout    = options[:open_timeout] || 5
    follow_redirect = !!options[:follow_redirect]
    rotate_proxy    = !!options[:rotate_proxy]
    delay_connect   = options[:delay_connect] || 2
    delay_connect   = @random.rand * 2 + delay_connect - 1
    delay_connect   = delay_connect < 0 ? 0 : delay_connect
    stream_callback = options[:stream_callback]
    public_page_url = options[:public_page_url]

    sleep(delay_connect) if delay_connect > 0

    rest_response = nil
    begin
      user_agent            = options[:user_agent] || @user_agent
      headers['User-Agent'] = user_agent

      # try to capture cookies in the main page if needed
      capture_cookies = !@cookies_captured
      capture_cookies &&= public_page_url.present?

      if capture_cookies
        encoder_option = keep_params ? { params_encoder: FaradayKeepParamsEncoder } : {}
        faraday_params = {
          proxy:   @current_proxy,
          ssl:     { verify: ssl_verify },
          request: {
            open_timeout: open_timeout,
            timeout:      timeout
          }.merge(encoder_option)
        }

        cc_headers = headers.dup
        cc_headers.delete_if do |k, v|
          %w[
            content_type
            content-type
            content_length
            content-length
            accept
          ].include?(k.to_s.downcase)
        end

        connection =
          Faraday.new(faraday_params) do |c|
            c.headers = cc_headers
            c.use FaradayMiddleware::FollowRedirects if follow_redirect
            c.adapter :net_http
            c.response :logger
          end

        response = connection.get(public_page_url)
        if !response.nil? && response.success?
          set_cookies_from_response(response)
          connection.close
        else
          connection.close
          raise SwitchProxyRequiredError
        end
      end

      if @cookies_captured
        cookie_val = @cookies.map { |key, val| "#{key}=#{val}" }.join('; ')
        headers['Cookie'] = cookie_val
      end

      req_body = options[:req_body] || ''
      headers['Content-Length'] = req_body.length.to_s if method == :post && req_body.length > 0

      encoder_option = keep_params ? { params_encoder: FaradayKeepParamsEncoder } : {}
      faraday_params = {
        proxy:   @current_proxy,
        ssl:     { verify: ssl_verify },
        request: {
          open_timeout: open_timeout,
          timeout:      timeout
        }.merge(encoder_option)
      }

      connection =
        Faraday.new(faraday_params) do |c|
          c.headers = headers
          c.use FaradayMiddleware::FollowRedirects if follow_redirect
          c.adapter :net_http
          c.response :logger
        end

      set_stream_cb = Proc.new do |req|
        if stream_callback.is_a?(Proc)
          req.options.on_data = stream_callback
        end
      end

      response =
        if method == :post
          connection.post(url, req_body, &set_stream_cb)
        else
          connection.get(url, &set_stream_cb)
        end

      success =
        if block_given?
          !response.nil? && yield(response)
        else
          !response.nil? && response.success?
        end

      if success
        set_cookies_from_response(response)

        rest_response =
          if stream_callback.is_a?(Proc)
            response.body # Wait until all data is downloaded

            {
              body:             nil,
              response_headers: response.headers,
              status:           response.status,
              url:              url
            }
          else
            response.to_hash
          end

        connection.close
      else
        connection.close
        raise SwitchProxyRequiredError
      end
    rescue SwitchProxyRequiredError, Faraday::Error, SOCKSError, Net::OpenTimeout => e
      if rotate_proxy
        switch_proxy
        retry
      end
    end

    rest_response
  end

  def set_cookies_from_response(response)
    @cookies_captured = true
    @cookies ||= {}

    return if response.headers['set-cookie'].nil?

    cookies_array = response.headers['set-cookie'].scan(/([^=,;\s]+=[^,;]+)[;,]?/).flatten
    cookies_array.each do |cookie|
      cookie_key_val = cookie.split('=', 2)
      next if COOKIE_ATTRIBUTES.include?(cookie_key_val[0].downcase)

      @cookies[cookie_key_val[0]] = cookie_key_val[1]
    end
  end
end
