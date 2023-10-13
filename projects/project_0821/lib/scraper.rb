require_relative 'connector'
require_relative 'parser'
class Scraper < Hamster::Scraper
  BASE_URL = 'https://jailinq.fortbendcountytx.gov'
  def initialize
    super
    @connector = TxInmateConnector.new(BASE_URL)
    @parser = Parser.new
    @aws_s3   = AwsS3.new(:hamster, :hamster)
  end

  def search_by(last_name)
    response = @connector.do_connect(BASE_URL)
    search_url = @connector.search_url
    form_data = @parser.search_form_data(response.body, last_name)
    response = @connector.do_connect(search_url, method: :post, data: form_data)
    @parser.inmate_ids(response.body)
  end

  def scrape_by(inmate_id)
    query_params    = "jailid=#{inmate_id}&rview=detail"
    detail_page_url = "#{@connector.search_url}?#{query_params}"
    response = @connector.do_connect(detail_page_url)
    [response, query_params]
  end

  def upload_to_aws(photo_url, full_name, inmate_id)
    return unless photo_url
    return if photo_url.include?('unknown.jpg')

    begin
      photo_url = "#{@connector.search_url.split('default.aspx').first}#{photo_url}"
      response  = @connector.do_connect(photo_url)
      content   = response.body if response
      key       = "inmates/tx/fort_bend/#{full_name.parameterize.underscore}_#{inmate_id}.jpg"
      @aws_s3.put_file(content, key) if content
    rescue => e
      logger.info "------404 not found mugshot--#{photo_url}----"
      logger.info e.full_message

      return
    end
  end
end
