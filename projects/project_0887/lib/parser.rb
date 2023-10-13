require_relative 'scraper'
require_relative 'manager'

class Parser < Hamster::Parser
  def parse_pdf(pdf)
    data = []
    pdf.pages.each do |page|
      page.text.scan(/.*\d{4}/)[1..-1].each do |line|
        data_inmate = {}
        line = line.split(/ {1,}/)
        data_inmate[:booking_number] = !line[0].blank? ? line[0] : nil
        if line.count == 5
          booking_date = line[4]
          data_inmate[:first_name] = line[2..3].join(' ')
        else
          booking_date = line[3]
          data_inmate[:first_name] = line[2]
        end
        data_inmate[:booking_date] = Date.strptime(booking_date, "%m/%d/%Y").to_s rescue nil
        data_inmate[:last_name] = line[1]
        data_inmate[:full_name] = data_inmate[:first_name] + ' ' + data_inmate[:last_name]
        data_inmate[:status] = 'In custody' 
        data_inmate[:data_source_url] = 'https://www.monroecounty.gov/files/inmate/roster.pdf'
        data << data_inmate
        generate_md5_hash(%i[booking_number booking_date first_name last_name], data_inmate)
      end
    end
    data
  end

  def generate_md5_hash(column, hash)
    md5 = MD5Hash.new(columns: column)
    md5.generate(hash)
    hash[:md5_hash] = md5.hash
  end
end
