# frozen_string_literal: true

require_relative '../lib/parser'
require_relative '../models/pdfs'

class Scraper < Hamster::Scraper

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
    browser.resize(**{width: 3000, height: 4000})
    browser.go_to(url)
    sleep(15)        # need to wait for the page to load completely
    browser.pdf(path: path, format: :A4, landscape: true)

    browser.mouse.click(**{x: 2500, y: 1500, button: :right})
    sleep(1)
    browser.keyboard.type(:enter)
    sleep(5)        # need to wait for the page to load completely
    browser.mouse
      .move(x: 128, y: 80)
      .down
      .move(x: 400, y: 80)
      .up
    path = storehouse + "store/" + "#{prefix}-#{suffix}Table.pdf"
    browser.pdf(path: path, paper_width: 8.0, paper_height: 24.0)#, landscape: true)
    browser.quit
    pdf_data =
      {
        date: date,
        link: path.sub('Table', ''),
        url: url,
        type: suffix
      }
  end

  def scrape
    source = PAGE
    response = connect_to(source)
    if response.status == 200
      download_to_pdf(source)       # return pdf_data
    else
      raise "Status site #{source} return: #{response.status}"
    end
  end

end
