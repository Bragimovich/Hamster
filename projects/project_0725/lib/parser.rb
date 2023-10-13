require_relative 'scraper.rb'
require_relative 'manager.rb'

class Parser < Hamster::Parser
  attr_reader :scraper

  def parse_csv(filename)
    string_csv = File.read("#{storehouse}store/#{filename}")
    string_csv_parsed = string_csv.lines.to_a[1..-1].join
    date = Date.today.to_s.gsub('-', '_')
    file_name = "csv_file_#{date}.csv"
    File.open("#{storehouse}store/#{file_name}", 'w') {|file| file.write(string_csv_parsed)}
    data_hash = []
    CSV.foreach("#{storehouse}store/#{file_name}", headers: true) do |row|
      hash = {}
      hash[:grant_id] = row['GRANT ID']
      hash[:grantee] = row['GRANTEE']
      hash[:purpose] = row['PURPOSE']
      hash[:division] = row['DIVISION']
      hash[:date_committed] = row['DATE COMMITTED']
      hash[:duration_months] = row['DURATION (MONTHS)']
      hash[:amount_committed] = row['AMOUNT COMMITTED']
      hash[:grantee_website] = row['GRANTEE WEBSITE']
      hash[:grantee_city] = row['GRANTEE CITY']
      hash[:grantee_state] = row['GRANTEE STATE']
      hash[:grantee_country] = row['GRANTEE COUNTRY']
      hash[:region_served] = row['REGION SERVED'] 
      hash[:topic] = row['TOPIC']
      hash[:data_source_url] = "https://www.gatesfoundation.org/about/committed-grants"
      generate_md5_hash(%i[grant_id grantee purpose division date_committed duration_months amount_committed grantee_website grantee_city grantee_state grantee_country region_served topic], hash)
      data_hash  << hash unless hash[:grantee].nil?
    end
    data_hash
  end

  def generate_md5_hash(column, hash)
    md5 = MD5Hash.new(columns: column)
    md5.generate(hash)
    hash[:md5_hash] = md5.hash
  end
end
