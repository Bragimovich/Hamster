# frozen_string_literal: true

class Parser < Hamster::Parser
  def get_all_url_from_page(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    get_all_download_links_xpath = "//*[@id='download-container']//div//li//a"
    parsed_page.xpath(get_all_download_links_xpath)
  end

  def extract_url(li_tag)
    li_tag.attributes["href"].value
  end

  def read_csv(file_path)
    file = File.open(file_path).readlines
    @hash_in_hash = {}
    list_of_hashes = []
    og_headers = file[0].gsub("\"", "").strip.split(",").map(&:downcase)
    file[1..-1].each do |record|
      record = record.encode("UTF-8", invalid: :replace, replace: "")
      record_splits = record.strip.split("','")
      if record_splits.length == 1
        record_splits = CSV.parse(record)&.first
      end
      hash = {}
      og_headers.zip(record_splits).map{|x| hash[x[0]] = x[1]}
      year = hash["fiscal_year"]&.match(/\d{4}/)&.to_s
      hash["fiscal_year"] = year
      hash["name"] = hash["name"].gsub("'","")
      list_of_hashes << hash
    end
    list_of_hashes
  end

end
