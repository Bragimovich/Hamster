# frozen_string_literal: true

module Hamster
  class Scraper < Hamster::Harvester
    class Dasher < Scraper

      class Cobble < Dasher
        attr_reader :connection, :current_proxy, :cookies, :headers

        def initialize(**params)
          super(super_config: true)
          @set_headers    = params[:headers].dup      || default_header
          @proxy_filter   = params[:proxy_filter].dup || ProxyFilter.new
          @permanent_conn = params[:pc]               || 0
          @user_agent     = params[:user_agent]       || nil
          @req_body       = params[:req_body].dup
          @redirect       = params[:redirect]? true : false
          set_cookies(params[:cookies])

          open_timeout   = params[:open_timeout].dup  || 5
          timeout        = params[:timeout].dup       || 60
          ssl_verify     = params[:ssl_verify].dup

          url            = params[:url].dup
          matched_url    = url ? url.match(%r{^(https?://[-a-z0-9._]+)(/.+)?}i) : nil
          url_domain     = matched_url ? matched_url[1] : ''

          @faraday_params = {
            url:     url_domain,
            ssl:     { verify: ssl_verify },
            request: {
              open_timeout: open_timeout,
              timeout:      timeout
            }
          }
          unused_parameters(params, used_parameters)
        end

        # Open connection
        def connect
          @current_proxy = next_proxy(Camouflage.new(), @proxy_filter)
          @faraday_params[:proxy] = @current_proxy
          @set_headers.merge!(@set_cookies) if @set_cookies
          @set_headers.merge!(user_agent: @user_agent || FakeAgent.new.any)
          @connection     =
            Faraday.new(@faraday_params) do |c|
              c.headers = @set_headers
              c.use FaradayMiddleware::FollowRedirects if @redirect
              c.adapter :net_http
              c.response :logger
            end
        end

        def connection
          @connection
        end

        # Close connection
        def close
          @connection&.close
          @connection    = nil
          @current_proxy = nil
          GC.start
        end

        # Method to set_cookie for the next connect
        def set_cookies(cookies, url=@url)
          if cookies.class == String
            cookies = HTTP::Cookie.cookie_value_to_hash(cookies)
          elsif cookies.class != Hash
            cookies = nil
          end
          @set_cookies = cookies
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
          %i[headers req_body url proxy_filter cookies open_timeout timeout ssl_verify method redirect pc user_agent]
        end

        def check_response(response, success)
          headers = response.headers
          check_response_general(response, success, headers)
        end

        def rest(url, success, method)
          @headers = nil
          @cookies = nil
          retries = 0
          max_retries = 5
          response_ready = false
          begin
            connect if @permanent_conn == 0 || @connection.nil? || @current_proxy.nil?
            response =
              case method
              when :get
                @connection.get(url)
              when :post
                @connection.post(url, @req_body)
              when :get_file
                path_to_file = check_filename(url, @filename)
                file = open(path_to_file, "wb")
                begin
                  @connection.get(url) do |req|
                    req.options.on_data = Proc.new do |chunk, _|
                      file.write chunk
                    end
                  end
                ensure
                  file.close
                end

              end
            response_ready = true
          rescue Exception => e
            sleep(rand(15))

            if retries <= max_retries
              logger.info e.full_message
              logger.debug "Retry connection ##{retries}" if @debug

              if @proxy_filter && @current_proxy
                @proxy_filter.ban(@current_proxy)
                message("Proxy was banned:", @current_proxy) if @debug
                @current_proxy = nil
              end
              response_ready = false
            else
              logger.debug e.message
              response = nil
              response_ready = true
            end
          else
            check_response_answer = check_response(response, success)
            if @proxy_filter&.ban_reason?(response) && retries <= max_retries
              @proxy_filter&.ban(@current_proxy)
              message("Proxy was banned:", @current_proxy) if @debug
              response_ready = false
              @current_proxy = nil
            elsif not check_response_answer

              if retries<max_retries
                response_ready = false
                @current_proxy = nil
                retries += 1
              else
                response = nil
              end
            end
            response
          ensure
            retries += 1
          end until response_ready
          unless response.nil?
            @headers = response.headers
            @cookies = response.headers['set-cookie']
            body = response.body
          end
          body
        end

        def default_header
          {
            "Accept"=> 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
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
      end
    end
  end
end
