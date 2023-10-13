# frozen_string_literal: true

module Hamster
  class Scraper < Hamster::Harvester
    class Dasher < Scraper
      
      class Hammer < Dasher
        attr_reader :current_proxy, :browser, :cookies, :headers, :body, :context

        def initialize(**params)
          super(super_config: true)
          parent          = params[:parent]
          user_agent      = params[:user_agent]   || FakeAgent.new.any
          browser_options = params[:options]      || {}
          headless        = params[:headless].nil? ? true : params[:headless]

          @url            = params[:url]
          @proxy_filter   = params[:proxy_filter].dup || ProxyFilter.new
          @permanent_conn = params[:pc]     || 0

          @env            = environment ? environment : :local

          set_cookies(params[:cookies])

          chrome         = Hashie::Mash.new Storage.new.chrome

          chrome_options = chrome.options
          chrome_options['user-agent'] = user_agent if user_agent
          chrome_options['headless'] = headless
          chrome_options['save_path'] = storehouse
          chrome_options[:browser_options]  = browser_options

          if @env != :local
            chrome_url = chrome.url
            chrome_url = chrome.urls.sample if chrome_url.nil?
            chrome_options = chrome_options.merge(url: chrome_url )
          end

          @chrome_options = chrome_options

          unused_parameters(params, used_parameters)
        end

        def new_browser
          close_browser
          proxy         = Camouflage.new(local_chrome: true) #@env == :local
          @current_proxy = next_proxy(proxy, @proxy_filter)
          current_proxy_uri = proxy.uri(@current_proxy)

          proxy_url       = "#{current_proxy_uri[:scheme]}://#{current_proxy_uri[:host]}:#{current_proxy_uri[:port]}" #
          proxy_username  = current_proxy_uri[:username]
          proxy_password  = current_proxy_uri[:password]
          #@chrome_options[:browser_options]['proxy-server'] = proxy_url

          #@chrome_options[:proxy] = { host: current_proxy_uri[:host], port: current_proxy_uri[:port],
          #                            user: current_proxy_uri[:username], pasword: current_proxy_uri[:password] }

          @chrome_options[:proxy] = { server: true }

          @browser = Ferrum::Browser.new(@chrome_options)
          unless @set_cookies.empty?
            @set_cookies.each do |cookie|
              @browser.cookies.set(**cookie)
            end
          end
          #@browser.network.authorize(user: proxy_username, password: proxy_password, type: :proxy) { |r| r.continue } if @env == :local
          @browser
        end

        def connect
          close
          new_browser if @browser.nil?

          proxy         = Camouflage.new(local_chrome: true) #@env == :local
          @current_proxy = next_proxy(proxy, @proxy_filter)
          current_proxy_uri = proxy.uri(@current_proxy)

          @browser.proxy_server.rotate(host: current_proxy_uri[:host], port: current_proxy_uri[:port],
                                       user: current_proxy_uri[:username], password: current_proxy_uri[:password])
          @context = @browser.contexts.create
          @context.create_page
        end

        def connection
          @page
        end

        def close
          @context.dispose unless @context.pages.empty? unless @context.nil?
          @context = nil
        end

        def close_browser
          close
          @browser.quit if !@browser.client.nil? unless @browser.nil?
          @browser = nil
        end

        def set_cookies(cookies, url=@url)
          @set_cookies = []
          if cookies.class == String
            cookies = HTTP::Cookie.cookie_value_to_hash(cookies)
          end

          if cookies.class == Hash
            cookies.each_pair do |key, value|
              @set_cookies.push(
                {name: key, value: value, domain: url}
              )
            end
          end
        end

        def get(url, success: nil)
          rest(url, success, :get)
        end

        def post(url, success: nil)
          rest(url, success, :post)
        end

        def get_file(url, filename: nil, success: nil)
          @filename = filename
          rest(url, success, :get)
        end

        private

        def used_parameters
          [:parent, :proxy, :user_agent, :options, :using, :method, :headless, :pc]
        end

        def check_response(browser, success)
          return if browser.network.response.nil?
          headers = browser.network.response.headers
          check_response_general(browser, success, headers)
        end

        def rest(url, success, method)
          retries = 0
          max_retries = 5
          browser_ready = false

          begin
            connect if @permanent_conn == 0 || @browser.nil? || @current_proxy.nil? || @context.nil?

            @page = @context.create_page
            @page.go_to(url)
            check_response_answer = check_response(@page, success)

            if !@page.network.status.in? [200,300,301] || !check_response_answer
              ban(@current_proxy)
              @current_proxy = nil
            else
              browser_ready = true
            end
          rescue => e
            message(e.full_message, nil, :light_red)
          ensure
            retries+=1
            browser_ready = true if retries > max_retries

            unless browser_ready
              close
            end
          end until browser_ready
          if !@page.network.response.nil?
            @body = @page.body
            @headers = @page.network.response.headers
            @cookies = to_set_cookie(@page.cookies.all)
            #@page.close
          end
          #@context.dispose if @permanent_conn == 0
          @body
        end


        def rest_old(url, success, method)
          retries = 0
          max_retries = 5
          browser_ready = false

          begin
            connect if @permanent_conn == 0 || @browser.nil? || @current_proxy.nil?
            @browser.go_to(url)

            check_response_answer = check_response(@browser, success)

            if !@browser.network.status.in? [200,300,301] || !check_response_answer
              ban(@current_proxy)
              @current_proxy = nil
            else
              browser_ready = true
            end
          rescue => e
            message(e.full_message, nil, :light_red)
          ensure
            retries+=1
            browser_ready = true if retries > max_retries
            @browser.quit unless @browser.nil? unless browser_ready
          end until browser_ready

          if !@browser.client.nil? && !@browser.network.response.nil?
            @body = @browser.body
            @headers = @browser.network.response.headers
            @cookies = to_set_cookie(@browser.cookies.all)
          end
          @browser.quit if @permanent_conn == 0
          @body
        end

        def to_set_cookie(cookies_jar)
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

