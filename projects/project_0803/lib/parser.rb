# frozen_string_literal: true

class Parser < Hamster::Parser
  SOURCE_URL = 'https://data.bls.gov/cgi-bin/cpicalc.pl?'

  def parse_html(body)
    Nokogiri::HTML(body)
  end

  def get_data_hash(page, base_year, year, response_req_body, run_id)
    amount = page.css("#answer").text.gsub("$", "")
    data_source_url = "#{SOURCE_URL}#{response_req_body}"
    data_hash = {}
    data_hash["year"] = year
    data_hash["base_year"] = base_year
    data_hash["inflation_amount"] = amount
    data_hash["data_source_url"] = data_source_url
    data_hash = mark_empty_as_nil(data_hash)
    data_hash["md5_hash"] = create_md5_hash(data_hash)
    data_hash["run_id"] = run_id
    data_hash
  end

  private 

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end
  
end
