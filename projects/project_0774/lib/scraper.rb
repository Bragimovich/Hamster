# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def post_response(report_id,page)
    url = 'https://www.kansasopengov.org/kog/table_api.php'
    body = prepare_body(report_id,page)
    connect_to(url: url,method: :post,req_body: body,proxy_filter: @proxy_filter)
  end

  private

  def prepare_body(report_id,page)
    "report_id=#{report_id}&page=#{page}"
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    Hamster.logger.info 'Response status: '.indent(1, "\t").green
    status = response&.status
    Hamster.logger.info status == 200 ? status.to_s.greenish : status.to_s.red
  end

end
