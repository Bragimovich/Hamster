# frozen_string_literal: true

module Hamster
  class Scraper < Hamster::Harvester
    class Dasher < Scraper

      class Crowbar < Dasher
        attr_reader :agent, :current_proxy, :cookies, :headers

        def initialize(**params)
          super(super_config: true)
          @user_agent     = params[:user_agent]        || FakeAgent.new.any
          @max_history    = params[:max_history]       || 50
          @set_headers    = params[:headers].dup       || {}
          @query          = params[:query]             || {}
          @referer        = params[:referer]
          @url            = params[:url].dup
          @proxy_filter   = params[:proxy_filter].dup  || ProxyFilter.new
          @permanent_conn = params[:pc]                || 0
          @ssl_verify     = params[:ssl_verify].dup

          set_cookies(params[:cookies]) if !params[:cookies].nil?
          unused_parameters(params, used_parameters)
        end

        def connect
          close
          proxy         = Camouflage.new()

          @current_proxy = next_proxy(proxy, @proxy_filter)
          proxy_dict = proxy.uri(@current_proxy)

          @agent = Mechanize.new do |a|
            a.user_agent  = @user_agent
            a.max_history = @max_history
          end

          @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE if @ssl_verify

          @agent.cookie_jar.add(@url, @set_cookies[0]) if @set_cookies

          if proxy_dict[:scheme] == 'socks5'
            @agent.agent.set_proxy("socks://#{proxy_dict[:username]}:#{proxy_dict[:password]}@#{proxy_dict[:host]}:#{proxy_dict[:port]}")
          else
            @agent.set_proxy proxy_dict[:host], proxy_dict[:port], proxy_dict[:username], proxy_dict[:password]
          end          
        end

        def connection
          @agent
        end

        def close
          @agent&.shutdown
          @agent         = nil
          @current_proxy = nil
          GC.start
        end


        def set_cookies(cookies, uri=@url)
          if cookies.class==HTTP::Cookie
            @set_cookies = cookies
            cookies = nil
          elsif uri.nil?
            message('We need url for add cookies. Put it in param[:url] or in the method.', '', 'blue')
            cookies = nil
          elsif cookies.class==Hash
            cookies_str = ''
            cookies.each_key do |key|
              cookies_str += "#{key}=#{cookies[key]};"
            end
            cookies = cookies_str
          elsif cookies.class==Array
            cookies_str = ''
            cookies.each do |c|
              @set_cookies = c if c.class==HTTP::Cookie
              cookies_str += c if c.class==String
            end
            cookies = cookies_str
          elsif cookies.class!=String
            cookies = nil
          end
          @set_cookies = HTTP::Cookie.parse(cookies, uri) unless cookies.nil?
        end

        def get(url, success: nil)
          rest(url, success, :get)
        end

        def post(url, success: nil)
          rest(url, success, :post)
        end

        def get_file(url, filename: nil, success: nil)
          @filename = filename
          rest(url, success, :get_file)
        end

        private

        def used_parameters
          [:proxy, :user_agent, :url, :max_history, :headers, :query, :referer, :cookies, :pc, :using, :method]
        end

        def check_response(page, success)
          headers = page.response.to_h
          check_response_general(page, success, headers)
        end

        def rest(url, success, method)
          @headers = nil
          @cookies = nil
          retries = 0
          max_retries = 5

          mech_ready = false
          begin
            connect if @permanent_conn == 0 || @agent.nil? || @current_proxy.nil?
            page =
              case method
              when :get
                @agent.get(url, [], @referer, @set_headers)
              when :post
                @agent.post(url, @query, @set_headers)
              when :get_file
                path_to_file = check_filename(url, @filename)

                @agent.pluggable_parser.default = Mechanize::Download
                page = @agent.get(url)
                page.save(path_to_file)
                page
              end

            mech_ready = true

          rescue => e
            if @proxy_filter && @current_proxy && retries < max_retries
              logger.info e.full_message
              logger.debug "Retry connection ##{retries}" if @debug

              message("Proxy was banned:", @current_proxy) if @debug
              @proxy_filter.ban(@current_proxy)
              @current_proxy = nil
            elsif retries>5
              page = nil
              mech_ready = true
            end
          else
            check_response_answer = check_response(page, success)
            if not check_response_answer
              if retries < max_retries
                mech_ready = false
                @current_proxy = nil
                retries += 1
              else
                page = nil
              end
            end
          ensure
            retries += 1
          end until mech_ready

          unless page.nil?
            @headers = page.response.to_h
            @cookies = to_set_cookie(@agent.cookie_jar.jar)
            body = page.body
          end
          body
        end

        # Make from cookie_jar String
        def to_set_cookie(cookies_jar)
          cookies = ""
          cookies_jar.each_value do |value|
            value.each_value do |value2|
              value2.each_value do |cook|
                cookies += cook.set_cookie_value + ", "
              end
            end
          end
          cookies[0...-2]
        end
      end
    end
  end
end
