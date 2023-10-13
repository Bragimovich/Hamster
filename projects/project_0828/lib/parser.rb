require_relative 'scraper.rb'
require_relative 'manager.rb'

class Parser < Hamster::Parser
  def parse_pdf(pdf)
    data = []
    pdf.pages.each do |page|
      page.text.scan(/\d+.*\d{2}/)[0..-2].each do |line|
        data << line
      end
    end

    data_hash = []
    data.each do |ar|
      new_ar = ar.split(/ {2,}| \d/)
      new_hash = {}
      new_hash[:number] = new_ar[0]
      new_hash[:full_name] = new_ar[1]
      new_hash[:last_name] = new_hash[:full_name].split(',').first rescue nil
      new_hash[:first_name] = new_hash[:full_name].split[1] rescue nil
      middle_name = new_hash[:full_name].split(',').last.split rescue nil
      new_hash[:middle_name] = middle_name.count >= 2 ? middle_name[1..-1][0] : nil rescue nil
      new_hash[:birthdate] = Date.strptime(new_ar[2], "%m/%d/%Y").to_s rescue nil
      new_hash[:facility] = new_ar[3]
      new_hash[:booking_date] = Date.strptime(new_ar[4], "%m/%d/%Y").to_s rescue nil
      new_hash[:type] = "ICN #"
      new_hash[:data_source_url] = "https://www4.erie.gov/sheriff/"
      next if new_hash[:first_name] == nil
      data_hash << new_hash
      generate_md5_hash(%i[full_name birthdate booking_date number facility], new_hash)
    end
    data_hash 
  end

  def generate_md5_hash(column, hash)
    md5 = MD5Hash.new(columns: column)
    md5.generate(hash)
    hash[:md5_hash] = md5.hash
  end
end
