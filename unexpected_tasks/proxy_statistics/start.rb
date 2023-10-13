# frozen_string_literal: true
require_relative 'model/proxy_config'
require_relative 'model/proxy_statistics'
require_relative 'lib/proxies'

module UnexpectedTasks
  module ProxyStatistics
    class Start
      NUMBER_CONFIG = 1
      @auth_mutex = nil

      def self.report message
        Hamster.report(to: "Mikhail Golovanov", message: message, use: :telegram)
      end

      def self.run(options)
        @ping_proxy = self.new
        @ping_proxy.ping
      end

      def test_proxy (**args)
        retries = 5
        response = false
        begin
          url_proxy = args[:proxy]
          url = args[:url]

          matched_url = url ? url.match(%r{^(https?://[-a-z0-9._]+)(/.+)?}i) : nil
          url_domain = matched_url ? matched_url[1] : ''
          url_path = matched_url ? matched_url[2] : '/'

          ssl_verify = false
          open_timeout = 10
          timeout = 20

          faraday_params = {
            url: url_domain,
            ssl: { verify: ssl_verify },
            proxy: url_proxy,
            request: {
              open_timeout: open_timeout,
              timeout: timeout
            }
          }

          connection = Faraday.new(faraday_params)
          response = connection.get(url_path)
        rescue Exception => e
          sleep(rand(15))
          retry if (retries-=1) > 0
        end

        response
      end

      def test_content (content, key_word,size_true)
        content.scan(key_word).size == size_true
      end

      def initialize
        super
        @list_site_test = JSON.parse(ProxyConfig.find(NUMBER_CONFIG).list_site_test)
      end

      def proxy_main proxy
        proxy.each do |prox|

          begin
            scheme = (prox.is_socks5) ? "socks" : "https"
            p = prox
            port = p.port
            url_proxy = "#{scheme}://#{p.login}:#{p.pwd}@#{p.ip}:#{port}"

            @list_site_test.each do |test_url|

              res = test_proxy({proxy: url_proxy, url: test_url["url"]})
              stat = ProxyStatistic.new
              stat.url_test = test_url["url"]
              stat.proxy_id = p.id
              if !!res
                stat.http_code = res.status
                stat.content_return = test_content(res.body, test_url["key"], test_url["size"].to_i)
                stat.proxy_enable = (1 && stat.content_return).to_i
              else
                stat.http_code = 0
                stat.content_return = 0
                stat.proxy_enable = 0
              end
              stat.save
            end

          end
        end

      end

      def ping
        proxy = PaidProxy.all
        proxy_main(proxy)
      end

    end

  end
end