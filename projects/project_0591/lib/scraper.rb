# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end

  private
  
  def reporting_request(response)
    Hamster.logger.debug '=================================='.yellow
    Hamster.logger.info 'Response status: '.indent(1, "\t").green
    status = response&.status
    Hamster.logger.info status == 200 ? status.to_s.greenish : status.to_s.red
    Hamster.logger.debug '=================================='.yellow
  end

end
