# frozen_string_literal: true

module Hamster
  class Scraper < Hamster::Harvester
    class Dasher < Scraper

      class Hammer < Dasher
        attr_reader :current_proxy, :browser, :cookies, :headers

        def initialize(**params)
          super(super_config: true)
          # parent          = params[:parent] # What is this? (Art. J)
          user_agent      = params[:user_agent] || FakeAgent.new.any
          browser_options = params[:options] || {}
          headless        = params[:headless].nil? ? true : params[:headless]
          save_path       = params[:save_path] || storehouse

          @url            = params[:url]
          @proxy_filter   = params[:proxy_filter].dup || ProxyFilter.new
          @permanent_conn = params[:pc] || 0
          @save_pdf       = params[:save_pdf]
          @pdf_name       = params[:pdf_name]
          @env            = environment ? environment : :local

          set_cookies(params[:cookies])

          chrome         = Hashie::Mash.new(Storage.new.chrome)
          chrome_options = chrome.options
          chrome_options['user-agent'] = user_agent if user_agent
          chrome_options['headless'] = headless
          chrome_options['save_path'] = save_path
          chrome_options['browser_path'] = '/usr/bin/chromium-browser'
          chrome_options[:browser_options]  = browser_options.merge(default_browser_options)

          if @env != :local
            chrome_url = chrome.url
            chrome_url = chrome.urls.sample if chrome_url.nil?
            chrome_options = chrome_options.merge(url: chrome_url )
          end

          @chrome_options = chrome_options

          unused_parameters(params, used_parameters)
        end

        def connect
          close

          proxy             = Camouflage.new(local_chrome: true) # @env == :local
          @current_proxy    = next_proxy(proxy, @proxy_filter)
          current_proxy_uri = proxy.uri(@current_proxy)

          proxy_url       = "#{current_proxy_uri[:scheme]}://#{current_proxy_uri[:host]}:#{current_proxy_uri[:port]}" #
          proxy_username  = current_proxy_uri[:username]
          proxy_password  = current_proxy_uri[:password]

          @chrome_options[:browser_options]['proxy-server'] = proxy_url
          @chrome_options[:proxy] =
            { host: current_proxy_uri[:host],
              port: current_proxy_uri[:port],
              user: current_proxy_uri[:username],
              pasword: current_proxy_uri[:password]
            }

          @browser = Ferrum::Browser.new(@chrome_options)

          @set_cookies.each { |cookie| @browser.cookies.set(**cookie) } unless @set_cookies.empty?

          @browser.network.authorize(
            user: proxy_username,
            password: proxy_password,
            type: :proxy
          ) { |r| r.continue } if @env == :local

          @browser
        end

        def connection
          @browser
        end

        def close
          unless @browser.nil?
            @browser.quit
            Process.waitall
          end
          @browser       = nil
          @current_proxy = nil
          GC.start(immediate_sweep: false)
        end

        def set_cookies(cookies, url=@url)
          @set_cookies = []

          cookies = HTTP::Cookie.cookie_value_to_hash(cookies) if cookies.class == String

          if cookies.class == Hash
            cookies.each_pair { |key, value| @set_cookies.push({name: key, value: value, domain: url}) }
          end
        end

        def get(url, success: nil)
          rest(url, success, :get)
        end

        def post(url, success: nil)
          rest(url, success, :post)
        end

        def get_file(url, filename: nil, success: nil) # does it work?
          @filename = filename
          rest(url, success, :get)
        end

        private

        def used_parameters
          [:parent, :proxy, :user_agent, :options, :using, :method,
           :headless, :pc, :proxy_filter, :save_pdf, :pdf_name, :save_path]
        end

        def default_browser_options
          { 'no-sandbox': nil,
            'disable-back-forward-cache': nil,
            'disable-gpu-program-cache': nil,
            'disable-gpu-shader-disk-cache': nil,
            'gpu-program-cache-size-kb': 0
          }
        end

        def check_response(browser, success)
          return if browser.nil?
          return if browser.network.nil?
          return if browser.network.response.nil?

          headers = browser.network.response.headers
          check_response_general(browser, success, headers)
        end

        def rest(url, success, method)
          @headers = nil
          @cookies = nil

          # the begining of an attemption to go another way
          connect if @permanent_conn.zero? || @browser.nil? || @current_proxy.nil?

          @browser.go_to(url)
          @browser.pdf(path: "#{storehouse}/store/#{@pdf_name}") if @save_pdf

          check_response_answer = check_response(@browser, success)

          ban(@current_proxy) if !@browser&.network&.status&.in? [200,300,301] || !check_response_answer
          # the end of the attention

          # retries       = 0
          # max_retries   = 2
          # browser_ready = false

          # begin
          #   connect if @browser.nil? || @current_proxy.nil?

          #   @browser.go_to(url)
          #   @browser.pdf(path: "#{storehouse}/store/#{@pdf_name}") if @save_pdf

          #   check_response_answer = check_response(@browser, success)

          #   if !@browser&.network&.status&.in? [200,300,301] || !check_response_answer
          #     ban(@current_proxy)
          #     @current_proxy = nil
          #   else
          #     browser_ready = true
          #   end
          # rescue Ferrum::TimeoutError => e
          #   message(e.message, nil, :light_red)
          # ensure
          #   retries += 1
          #   browser_ready = true if retries > max_retries
          # end until browser_ready

          if !@browser.client.nil? && !@browser.network.response.nil?
            body     = @browser.body
            @headers = @browser.network.response.headers
            @cookies = cookie_set_to(@browser.cookies.all)
          end

          close if @permanent_conn.zero?
          body
        end

        def cookie_set_to(cookies_jar)
          cookies = ""
          cookies_jar.each_value do |value|
            new_cook = "#{value.name}=#{value.value}; Domain=#{value.domain}; path=#{value.path}"
            new_cook += "; Expires=#{value.expires.httpdate}" unless value.expires.nil?
            new_cook += "; HttpOnly" if value.httponly?
            new_cook += "; Secure" if value.secure?
            cookies += new_cook + ", "
          end
          cookies[0...-2]
        end
      end
    end
  end
end

