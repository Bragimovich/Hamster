require_relative '../../../lib/scraper'
class Scraper < Hamster::Scraper

  def initialize
    super
    @cobble = Dasher.new(using: :cobble, redirect: true)
    @s3 = AwsS3.new(bucket_key = :us_court)
  end

  def fetch_main_page
    url = 'http://www.courtswv.gov/supreme-court/docs/index.html'
    @cobble.get(url)
  end

  def fetch_latest_page
    url = 'http://www.courtswv.gov/supreme-court/opinions.html'
    @cobble.get(url)
  end

  def fetch_sub_page(query)
    url = "http://www.courtswv.gov/supreme-court/docs/#{query}"
    @cobble.get(url)
  end

  def get_file_path(href, query_str)
    if href.include?('memo-decisions')
      href = href.gsub(' ', '%20')
      "http://www.courtswv.gov/supreme-court/#{href.gsub('../../', '')}"
    else
      "http://www.courtswv.gov/supreme-court/docs/#{query_str.gsub('/index.html', '')}/#{href}"
    end
  end

  def fetch_pdf_data(url)
    @cobble.get(url)
  end

  def save_pdf_file(href, year, case_id)
    file_name = "#{case_id}"
    year = year
    case_id = case_id
    body = fetch_pdf_data(href)
    save_pdf(body, file_name, year)
  end

  def save_pdf(content, file_name,year)
    FileUtils.mkdir_p"#{storehouse}store/pdfs/#{year}"
    pdf_storage_path = "#{storehouse}store/pdfs/#{year}/#{file_name}.pdf"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(content)
    end
  end
end
