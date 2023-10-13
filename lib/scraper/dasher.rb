# frozen_string_literal: true

require_relative 'dasher/cobble' # based on Net/HTTP and Faraday
require_relative 'dasher/crowbar' # based on Mechanize
require_relative 'dasher/hammer' # based on Ferrum

module Hamster
  class Scraper < Hamster::Harvester

    class Dasher < Scraper

      def initialize(**params)
        super
        @url          = params[:url]
        @method       = params[:using]  || :hammer
        @rest_method  = params[:method] || :get
        @params       = params

        @dasher = class_object unless params[:super_config]
      end


      def get(url, success: nil)
        @dasher.get(url, success: success) unless @dasher.nil?
      end

      def post(url, success: nil)
        @dasher.post(url, success: success) unless @dasher.nil?
      end

      def get_file(url, filename:nil, success: nil)
        @dasher.get_file(url, filename:filename, success: success) unless @dasher.nil?
      end

      # Make connection
      def connect
        message("Dont Forget to close browser!!", nil, 'red') if @method == :hammer
        @dasher.connect
      end

      def connection
        @dasher.connection unless @dasher.nil?
      end

      # Close connection
      def close
        @dasher.close unless @dasher.nil?
      end

      # Return html body from last url
      def body
        @dasher.body unless @dasher.nil?
      end

      # Return last used proxy
      def current_proxy
        @dasher.current_proxy unless @dasher.nil?
      end

      def headers
        @dasher.headers unless @dasher.nil?
      end

      def cookies
        @dasher.cookies unless @dasher.nil?
      end

      # Put cookies for next connection,
      # Alpha version, need to check
      def set_cookies(cookies, url=@url)
        @dasher.set_cookies(cookies, url) unless @dasher.nil?
      end

      def smash(url: nil, success: nil)
        case @rest_method
        when :get
          get(url, success: success)
        when :post
          post(url, success: success)
        else
          message('wrong rest method', @rest_method, :orange)
        end
      end

      # Get connection depends on method
      def connection
        unless @dasher.nil?
          connection =
            case @method
            when :cobble
              @dasher.connection
            when :crowbar
              @dasher.agent
            when :hammer
              @dasher.browser
            end
        end

        if connection.nil?
          puts "Connection is nil. If you need it you can make connection by self.connect."
        else
          connection
        end
      end

      private

      # Initialize class depends on using @method (Faraday, Mechanize, Ferrum)
      def class_object
        case @method
        when :cobble
          Cobble.new(**@params)
        when :crowbar
          Crowbar.new(**@params)
        when :hammer
          Hammer.new(**@params)
        else
          message "WRONG METHOD!!!", ""
        end
      end

      def devtools
      end

      def ban(proxy)
        @proxy_filter.ban(proxy)

        # @todo need to change all print, puts, p and pp to log when it'll be done
        message("Proxy was banned: ", proxy)
      end

      # @todo need to change all print, puts, p and pp to log when it'll be done
      def message(text, proxy, color = :yellow)
        print Time.now.strftime("%H:%M:%S ").colorize(color)
        puts text.colorize(:light_white) + proxy.to_s.colorize(:light_yellow)
      end

      # Get new proxy
      def next_proxy(proxy, proxy_filter = ProxyFilter.new)
        current_proxy = proxy.swap
        while proxy_filter.filter(current_proxy).nil? && proxy.count > proxy_filter.count
          # todo need to change all print, puts, p and pp to log when it'll be done
          message('Bad proxy filtered: ', current_proxy)
          current_proxy = proxy.swap
        end if proxy_filter
        current_proxy
      end

      # Check response if code 200 but maybe something wrong with answer
      def check_response_general(response, success, headers)
        return if headers["content-type"].nil?
        block_given? ? success.call(response) : (headers["content-type"].match?(%r{text|html|json}) || !headers["content-type"].nil?)
      end

      def check_filename(url, filename = nil)
        path    =  URI(url).path.split(/\//)
        filename = path.pop || 'index.html' if filename.nil?
        path_to_file = storehouse + 'store/' + filename.to_s

        base_path_to_file = path_to_file

        number = 1

        while File.exist? path_to_file do
          path_to_file = "#{base_path_to_file}_#{number}"
          number += 1
        end
        path_to_file
      end

      def unused_parameters(params, used_parameters)
        unused_parameters = []

        params.each_key { |key| unused_parameters.push(key) unless key.in?(used_parameters) }

        unless unused_parameters.empty?
          puts "Connection doesn't use these parameters: #{unused_parameters.join(', ')}."
          puts "We only use: #{used_parameters.join(', ')}. Maybe you have misspelling or use string."
        end
      end

    end
  end
end

