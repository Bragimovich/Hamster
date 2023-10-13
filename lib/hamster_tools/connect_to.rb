# frozen_string_literal: true

module Hamster
  module HamsterTools
    SSL_OPTS = { verify: true }
    
    # Tries connect to a source via GET or POST method and receive a response.
    # @param [Array] arguments
    # @option [String] url Target url that we need to connect
    # @option [Symbol] method Choose REST method to get site: :get, :post, :get_file
    # @option [Hash] headers List of HTTP headers
    # @option [String] req_body Request body
    # @option [String] proxy Proxy address. If scheme wasn't defined uses it as SOCKS5-proxy
    # @option [String] cookies String with cookies
    # @option [ProxyFilter] proxy_filter ProxyFilter instance
    # @option [Integer] open_timeout Timeout of waiting the source will be opened
    # @option [Integer] timeout Timeout of waiting the source will be downloaded
    # @option [Bool] ssl_verify Check ssl in connection on site or not. Some sites have problem with ssl you have to put false for them.
    # @option [String] filename Filename for saving file in method get_file ({:method=> get_file})
    # @option [Symbol] method Using HTTP-method. It can be :post or :get (default)
    # @return [Faraday::Response, Nil] the source response or nil unless response given
    def connect_to(*arguments, &block)
      return nil if arguments.nil? || arguments.empty?
      
      given_arguments = arguments.dup
      url             = arguments.first.is_a?(String) ? arguments.shift : arguments.first[:url]
      
      return nil if url.nil?
      
      arguments    = arguments.first.dup
      condition    = arguments.is_a?(Hash)
      headers      = (condition ? arguments[:headers].dup : nil) || {}
      req_body     = condition ? arguments[:req_body].dup : nil
      proxy        = condition ? arguments[:proxy].dup : nil
      cookies      = condition ? arguments[:cookies].dup : nil
      proxy_filter = condition ? arguments[:proxy_filter].dup : nil
      iteration    = (condition ? arguments[:iteration].dup : nil) || 0
      open_timeout = (condition ? arguments[:open_timeout].dup : nil) || 5
      method       = (condition ? arguments[:method].dup : nil) || :get
      timeout      = (condition ? arguments[:timeout].dup : nil) || 60
      ssl_verify   = (condition ? arguments[:ssl_verify].dup : true)
      filename     = (condition ? arguments[:filename].dup : nil)
      matched_url  = url ? url.match(%r{^(https?://[-a-z0-9._]+)(/.+)?}i) : nil
      url_domain   = matched_url ? matched_url[1] : ''
      url_path     = matched_url ? matched_url[2] : '/'
      
      if iteration == 10
        log "\nLoop depth more than 10.", :red
        exit 0
      end
      
      current_proxy = nil
      proxy         = Camouflage.new(proxy)
      retries       = 0
      response      = nil
      headers       = headers.merge(user_agent: FakeAgent.new.any) unless headers.include?(:user_agent)
      headers.merge!(cookies) if cookies

      begin
        current_proxy = proxy.swap

        if proxy_filter
          while proxy_filter.filter(current_proxy).nil? && proxy.count > proxy_filter.count
            puts "Bad proxy filtered: ".yellow + current_proxy.to_s.red if @debug
            current_proxy = proxy.swap
          end
        end
        
        faraday_params = {
          url:     url_domain,
          ssl:     { verify: ssl_verify },
          proxy:   current_proxy,
          request: {
            open_timeout: open_timeout,
            timeout:      timeout
          }
        }
        connection     =
          Faraday.new(faraday_params) do |c|
            c.headers = headers
            c.adapter :net_http
            c.response :logger
          end
        response       =
          case method
          when :get
            connection.get(url_path)
          when :post
            connection.post(url_path, req_body)
          when :get_file
            file = open(filename, "wb")
            begin
              connection.get(url_path) do |req|
                req.options.on_data = Proc.new do |chunk, _|
                  file.write chunk
                end
              end
            ensure
              file.close
            end
          else
            nil
          end
      
      rescue Interrupt, SystemExit
        log "\nInterrupted by user.", :red
        exit 0
      
      rescue Exception => e
        retries += 1
        sleep(rand(15))
        
        if retries <= proxy.count
          puts e.message
          puts e.full_message if @debug
          puts "Retry connection ##{retries}" if @debug
          if proxy_filter && current_proxy
            proxy_filter.ban(current_proxy)
            puts "Proxy #{current_proxy} was banned.".red if @debug
          end
          retry
        else
          puts e.message
          response = nil
        end
      
      else
        check_response = block_given? ? block.call(response) : (response.headers[:content_type].match?(%r{text|html|json|pdf|application}) || !response.headers[:server].nil?)
        
        if proxy_filter&.ban_reason?(response)
          proxy_filter&.ban(current_proxy)
          puts "Proxy #{current_proxy} was banned.".red if @debug
        end
        
        unless check_response
          countdown(35 - rand(30), label: 'Waiting before reconnecting...')
          
          if given_arguments.last.is_a?(Hash)
            given_arguments.last.merge!(iteration: iteration + 1)
          else
            given_arguments << { iteration: iteration + 1 }
          end
          
          connect_to(*given_arguments, &block)
        end
        
        response
      ensure
        
        response
      end
    end
  end
end
