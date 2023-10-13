class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  HEADERS = {
    POST: "/rijrs/searchAttorney.do HTTP/1.1",
    Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
    Cookie: "JSESSIONID=CTwEWLsNAJM7pg0Dzy1KBSX9.node1",
    Host: "rijrs.courts.ri.gov",
    Origin: "http://rijrs.courts.ri.gov",
    Referer: "http://rijrs.courts.ri.gov/rijrs/searchAttorney.do?subactionId=1",
    # Proxy_Authorization: "Basic RUVDNTkzNUQ2NDI1RDRFMUNBN0QwNzM2Mzk1RUY1MjE1MUNBNUNDOTpleUpoYkdjaU9pSkZRMFJJTFVWVEswRXlOVFpMVnlJc0ltTjBlU0k2SWtwWFZDSXNJbVZ1WXlJNklrRXlOVFpIUTAwaUxDSmxjR3NpT25zaWEzUjVJam9pUlVNaUxDSmpjbllpT2lKUUxUSTFOaUlzSW5naU9pSjBRbTFuYW00M01XSjBabGxWU1c5Vk1XNXdVVFJUTmxObVJVdHRjR1pwVFVSc1NHVmFSSFZmTmpaUklpd2llU0k2SW5WNWJtbGpORFJzZVdkSGNGbHVTM1ZHUmtSYWVGTllhbFI2Y0ZCYU9WZHNNV0ZaVlZoSVZVWjNURFFpZlgwLjlpNWhUWTJmeUJIMnJ5aXExSW4xR0NJVFc1aVFaUWFybndTU0FORXlGQ1hpblJZNEZoYjV1QS5pd1Qwc1hNb1RqR0FHYVEyLmxKN1JITUpjRkl2WU5LWmVrRXRSX2RuTkp2NUl5ZGpXbFNNMWFJM2ZONU1iRFN4YklHUHQ3ek42SzR4d2M0eUNOQmVLaUtFeDYtYTlIQ2d0SU5rT0RTZm1KMDRUMTZkdnA5VnhGWk4wV19hQ1pEU19pYVF0d0xuTWdOQXNYMGdtLW1wSzNBUkN3dWkzNTZwdmI0dUxrOU03YkpIaElzdjZwTGlDS0JUdFRvTVNpR0RIdVVLQTFvcnJoclJDSG1UNmZicmdQUV9RbkM1RVlPX1ZvYVFPdHFia0JsbFlNQVJ4Z0xBWTQwUjV1Smo4NVVsdzVaNUtERC02aXBmQ0l0MmtId0VMYU9fUlhDNEJhdXFMT0VFNTVpdll0QnZsU0pRQ0RTVm9wbnp4S1ZqcVI2bm5MUXVfNFNHX2xxV0x5UjZEZXBCZXcwaURJTTBjN0NHRlJ5UWFvSGlUZkRHVHZmaHNUTEFoT0xjUHg0dXg4eXg0QUlKVndSakNjQmkzWEFLem1RUWVSOWdkQWVSVVlmbEVxZldlMFFuTGZJSC14ZVhIVVQ3ZUxGNUZoQTZBYVZ4Wjd3RnNDZUxfV3NNRnVKOC5CdHdjVFdSOXhQZXdpX3pmbWVNZFh3",
    # Proxy_Connection: "keep-alive"
  }

  def download_main_page_with_form(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter , method: :post, headers: HEADERS)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  def download_inner_page(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter, headers: HEADERS)
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