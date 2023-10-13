# frozen_string_literal: true

class Scraper < Hamster::Scraper
  attr_accessor :s3

  def initialize
    super
    @s3 = AwsS3.new(bucket_key = :hamster, account = :hamster)
  end

  def main_page(url)
    main_page = connect_to(url)
    main_page.body
  end

  def save_html(data_link, subfolder)
    data_link.each do |link|
      filename = link.split("/").last.gsub(/[^\w]/, '') + ".html"
      response = connect_to(link)
      Dir.mkdir("#{storehouse}/store/#{subfolder}") unless File.exists?("#{storehouse}/store/#{subfolder}")
      peon.put(file: "#{filename}", content: response.body, subfolder: subfolder.to_s)
    end
  end

  def save_to_aws(url_file, key_start)
    return nil if url_file.blank?
    base_url = "https://polkinmates.polkcountyiowa.gov"
    cobble = Hamster::Scraper::Dasher.new(using: :cobble)
    response = cobble.get(base_url + url_file)
    key = key_start + url_file.split('/').last + '.jpg'
    aws_link = s3.put_file(response, key, metadata={url: url_file})
    aws_link
  end
end
