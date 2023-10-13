# frozen_string_literal: true
class Scraper <  Hamster::Scraper
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      next if response.nil?
      reporting_request(response)
      break if response&.status && [200, 304, 302, 500].include?(response.status)
    end
    response
  end

  private

  def reporting_request(response)
    # unless @silence
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
  end

end
