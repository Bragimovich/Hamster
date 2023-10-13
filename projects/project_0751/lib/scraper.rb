# frozen_string_literal: true
require 'zip'

class Scraper < Hamster::Scraper
  def initialize
    super
  end

  def download(url)
    dirname = "#{storehouse}store/"
    response = connect_to(url: url)
    doc = Nokogiri::HTML(response.body)
    link_url = []
    doc.xpath("//tbody/tr/th/a/@href").each do |link|
      link_url << url + link
    end

    filter_url = link_url.select {|link| link.split('/').last.split('_').first.to_i >= 2016 }
    filter_url.each do |link|
      filename = dirname + link.split('/').last
      unless File.file?(filename)
        connect_to(url: link, method: :get_file, filename: filename)
      end
    end
  end

  def download_files(link)
    dirname = "#{storehouse}store/"
    filename = dirname + link.split('/')[3] + '.txt'
    connect_to(url: link, method: :get_file, filename: filename)
    filename
  end
end
