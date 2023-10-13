require_relative 'connector'
class Scraper < Hamster::Scraper
  BASE_URL = 'https://www.ms.gov'
  SEARCH_PAGE = BASE_URL + '/mdoc/inmate/Search/Index'

  def initialize
    super
    @connector = MdInmateConnector.new(SEARCH_PAGE)
    @aws_s3    = AwsS3.new(:hamster, :hamster)
  end

  def scrape(last_name)
    form_data = {
      'LastName' => last_name
    }
    @connector.do_connect(SEARCH_PAGE, method: :post, data: form_data)
  end

  def scrape_detail_page(detail_page_url)
    @connector.do_connect(detail_page_url)
  end

  def upload_to_aws(original_link, inmate_id, full_name)
    return unless original_link

    content = @connector.do_connect(original_link)
    key     = "inmates/ms/#{inmate_id}/#{full_name.parameterize.underscore}.jpg"
    @aws_s3.put_file(content.body, key) if content
  end
end
