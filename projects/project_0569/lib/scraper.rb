class Scraper < Hamster::Scraper

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  MAIN_URL = 'https://mn.gov/mmb/transparency-mn/payrolldata.jsp'

  def connect_main
    connect_to(MAIN_URL)
  end

  def connect_link(link)
    connect_to(link)
  end

  private
  
  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    # unless @silence
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
    # end
  end 

end
