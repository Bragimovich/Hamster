# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def get_source(url)
    connect_to(url: url, headers: HEADERS)
  end

  def download_to_csv(url)
    time_now = Time.now
    date = Time.at(time_now.to_i / DAY * DAY)
    prefix = date.to_s.split[0]
    path = storehouse + "store/" + "epdata #{prefix}-World.csv"
  end

  def download_to_pdf(url)
    time_now = Time.now
    date = Time.at(time_now.to_i / DAY * DAY)
    time = Time.at(time_now.to_i % DAY)
    prefix = date.to_s.split[0]
    suffix = "World"

    path = storehouse + "store/" + "#{prefix}-#{suffix}.pdf"
    hammer = Hamster::Scraper::Dasher.new(using: :hammer)
    page = hammer.get(url)
    browser = hammer.connect
    browser.go_to(url)
    sleep(15)        # need to wait for the page to load completely
    browser.pdf(path: path, format: :A4)
    browser.quit
    pdf_data = {
        date: date,
        link: path,
        url:  url,
        type: suffix
      }
  end

  def scrape
    source = PAGE
    response = connect_to(source)
    if response.status == 200
      download_to_csv(RAW_PAGE)
      download_to_pdf(source)       # return pdf_data
    else
      raise "Status site #{source} return: #{response.status}"
    end
  end
end
