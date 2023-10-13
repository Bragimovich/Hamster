class Scraper < Hamster::Scraper

  def initialize(**option)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @url = option[:url]
    @s3 = AwsS3.new(bucket_key = :us_court)
  end

  attr_accessor :s3

  def scrape_links
    links    = []
    opinions = []
    orders   = []
    response = connect_to(@url, proxy_filter: @proxy_filter, ssl_verify: false)
    page     = Nokogiri::HTML(response.body)
    pointer  = page.css('div.main_col.column a')
    pointer.each { |elem| links << ('https://www.courts.ri.gov') + (elem['href']) }
    links.delete_if { |link| link.split('-')[0].split('')[-4..-1].join.to_i < 2016 }.uniq!
    links.each { |link| link.include?('Opinions') ? opinions << link : orders << link }
    links_by_years = [opinions.reverse, orders.reverse]
  end

  def scrape(opinions_orders)
    links_pdf  = []
    opinions_orders.each do |links|
      links.each do |link|
        next_pages        = [link]
        loop do
          response  = connect_to(next_pages.last, proxy_filter: @proxy_filter, ssl_verify: false)
          site      = Nokogiri::HTML(response.body)
          if site.css('td a').empty?
            next_page = link
          else
            next_page = ('https://www.courts.ri.gov' + site.css('td a').last.to_html.match(/\/Courts.+}/).to_s).gsub('amp;', '')
          end
          if next_page == next_pages[-2]
            break
          else
            md5  = MD5Hash.new(columns:    [:url])
            md5.generate({url: next_pages.last})
            name = md5.hash
            peon.put(file: name, content: response.body, subfolder: '1_pages')
            next_pages << next_page
          end

          site.css('td.ms-vb2 a').each do|info|
            pdf_link = 'https://www.courts.ri.gov' + info['href'].gsub(' ', '%20')
            download_pdf(pdf_link)
          end
          site.css('td a').empty? ? break : next_page
        end
        rescue => e
          Hamster.logger.error(e.full_message)
        end
      end
    links_pdf
  end

  def download_pdf(pdf_link)
    pdf_body = connect_to(pdf_link, proxy_filter: @proxy_filter, ssl_verify: false).body
    md5  = MD5Hash.new(columns:    [:url])
    md5.generate({url: pdf_link})
    name = md5.hash
    peon.put(file: name, content: pdf_body, subfolder: '1_pdfs')
  end

  def save_aws(link, key_info)
    body = connect_to(link, proxy_filter: @proxy_filter, ssl_verify: false).body
    key  = 'us_courts_pdf/' + key_info + '.pdf'
    aws_link = s3.put_file(body, key, metadata = {})
    aws_link
  end
end
