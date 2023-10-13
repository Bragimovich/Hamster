# frozen_string_literal: true
class Scraper < Hamster::Scraper

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def main_request(row_start, retries = 50)
    begin
      uri = URI.parse("https://secure2.kentucky.gov//TransparencyWebApi/v1/Salary?dataGroupViewName=Individual&dataGroupViewCode=5&branchCode=&firstname=&lastname=&beginSalaryRange=&endSalaryRange=&title=&department=&cabinet=&maximumRows=100&startRowIndex=#{row_start}")
      request = Net::HTTP::Get.new(uri)
      request["Authority"] = "secure2.kentucky.gov"
      request["Accept"] = "application/json, text/plain, */*"
      request["Accept-Language"] = "en-US,en;q=0.9"
      request["Origin"] = "https://transparency.ky.gov"
      request["Referer"] = "https://transparency.ky.gov/"
      request["Sec-Ch-Ua"] = "\"Google Chrome\";v=\"107\", \"Chromium\";v=\"107\", \"Not=A?Brand\";v=\"24\""
      request["Sec-Ch-Ua-Mobile"] = "?0"
      request["Sec-Ch-Ua-Platform"] = "\"Linux\""
      request["Sec-Fetch-Dest"] = "empty"
      request["Sec-Fetch-Mode"] = "cors"
      request["Sec-Fetch-Site"] = "cross-site"
      request["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"

      req_options = {
        use_ssl: uri.scheme == "https",
      }
      proxy_ip, proxy_port = fetch_proxies
      response = Net::HTTP.SOCKSProxy(proxy_ip, proxy_port).start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    rescue => exception
      raise if retries < 1
      main_request(row_start, retries - 1)
    end
  end

  def fetch_proxies
    proxy = PaidProxy.all.to_a.shuffle.first
    proxy_ip, proxy_port = proxy["ip"], proxy["port"]
    [proxy_ip, proxy_port]
  end
end
