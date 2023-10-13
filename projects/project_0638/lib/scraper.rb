# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def opinions_page(link)
    Hamster.logger.info("GET: https://www.courts.maine.gov/courts/sjc/#{link}")
    response = connect_to(url: "https://www.courts.maine.gov/courts/sjc/#{link}")
    Hamster.logger.info("___Status: #{response.status}____")
    response&.body
  end

  def download_pdf(url, tries: 10)
    Hamster.logger.info("Processing URL -> #{url}")
    response = connect_to(url: url)
    Hamster.logger.info("___Status: #{response.status}____")
    raise if response.nil? || response.status != 200

    response.body
  rescue => e
    tries -= 1
    if tries < 1
      Hamster.logger.error("Skipped pdf: #{url}")
      return nil
    else
      sleep(rand(10))
      Hamster.logger.error("PDF not downloaded....Retry....")
      retry
    end
  end
end
  