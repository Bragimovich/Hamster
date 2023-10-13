require_relative'../../../lib/scraper'

class Scraper < Hamster::Scraper

  CASES_SUB_FOLDER = 'vt_sc_cases'
  def initialize
    super
    @cobble = Dasher.new(using: :cobble, redirect: true)
    @s3 = AwsS3.new(bucket_key = :us_court)
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    
  end
  
  def fetch_main_page
    url =  'https://www.vermontjudiciary.org/supreme-court/published-opinions-and-entry-orders'
    @cobble.get(url)
  end

  def fetch_pdf_data(url)
    body = connect_to(url)&.body
    body
  end
  
  def get_file_path(href)
    base_url = 'https://www.vermontjudiciary.org'
    if href.include?('http')
      href = href
    else
      href = base_url + href
    end
  end

  def save_pdf_file(href, year, case_id)
    file_name = "#{case_id.gsub("/", '_')}"
    year = year
    base_url = 'https://www.vermontjudiciary.org'
    if href.include?('http')
      href = href
    else
      href = base_url + href
    end

    body = connect_to(href)&.body
    url = body.match(/url='(.*?)'/)
    if url
      url = url[1]
      body = connect_to(url)&.body
      save_pdf(body, file_name, year)
    else
      save_pdf(body, file_name, year)
    end

  end

  def save_pdf(content, file_name, year)
    FileUtils.mkdir_p "#{storehouse}store/pdfs/#{year}"
    pdf_storage_path = "#{storehouse}store/pdfs/#{year}/#{file_name}.pdf"
    logger.info '=========================================================================='
    logger.info "Processing year => #{year} => Downloading file => #{file_name}"
    logger.info '=========================================================================='
    File.open(pdf_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  private
    
  def connect_to(url)
    response = nil
    retries = 0
    begin
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      retries += 1
    end until response&.status == 200 or response&.status == 404 or response&.status == 301 or retries == 10
    response

  end
end
