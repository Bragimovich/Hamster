class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get_request(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      headers = {
        "Accept-Encoding": "gzip, deflate, br",
        "Cookie": "8b25d7a90c26baadd286af7afdea90d6_Cluster1=F477F9776127F83F1CA0A14BDBDD7A14.8b25d7a90c26baadd286af7afdea90d6_SASServer1_1; TS01834729=01b459be4ec63ce4ed4a80af87602772936ed3569e304b830ca74f44427447765012b94efd7d6cc8c82e445b093f3e908a8dea5d279a8a4aa8ccf2e1fbe63e3868c3307c39; _gid=GA1.2.353732005.1671823095; ctsessionlanguage=en_US; googtrans=/auto/en; _ga=GA1.2.531402579.1671823094; _ga_4ERYR0PZ7T=GS1.1.1671823094.1.1.1671823221.57.0.0; TS0172db19=01b459be4e510cad5a8d736ef4d57fd6b3a239ab28cd32e4612cf2c6fb9bd0e419b57ab3581d67f3b6c3f18a5b1e94e01e51c3a269",
      }
      response = connect_to(url: url , proxy_filter: @proxy_filter, headers: headers)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  def download_csv_file(url,file_name)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      headers = {
        "Accept": "application/csv",
        "Accept-Encoding": "gzip, deflate, br",
        "Cookie": "8b25d7a90c26baadd286af7afdea90d6_Cluster1=F477F9776127F83F1CA0A14BDBDD7A14.8b25d7a90c26baadd286af7afdea90d6_SASServer1_1; TS01834729=01b459be4ec63ce4ed4a80af87602772936ed3569e304b830ca74f44427447765012b94efd7d6cc8c82e445b093f3e908a8dea5d279a8a4aa8ccf2e1fbe63e3868c3307c39; _gid=GA1.2.353732005.1671823095; ctsessionlanguage=en_US; googtrans=/auto/en; _ga=GA1.2.531402579.1671823094; _ga_4ERYR0PZ7T=GS1.1.1671823094.1.1.1671823221.57.0.0; TS0172db19=01b459be4e510cad5a8d736ef4d57fd6b3a239ab28cd32e4612cf2c6fb9bd0e419b57ab3581d67f3b6c3f18a5b1e94e01e51c3a269",
        "Connection": "keep-alive",
      }

      response = connect_to(url: url , proxy_filter: @proxy_filter, method: :get_file, headers: headers, filename: file_name)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  private

  def reporting_request(response)
    if response.present?
      puts '=================================='.yellow
      print 'Response status: '.indent(1, "\t").green
      status = "#{response.status}"
      puts response.status == 200 ? status.greenish : status.red
      puts '=================================='.yellow
    end
  end
end