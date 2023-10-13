# frozen_string_literal: true
class Parser < Hamster::Parser

  def get_data(line, run_id)
    data_hash = {}
    line                                = line.split("|")
    data_hash[:year]                    = line[1]
    data_hash[:legal_name]              = line[2]
    data_hash[:tax_period_to]           = line[6]
    data_hash[:tax_period_from]         = line[5]
    data_hash[:ein]                     = line[0]
    data_hash[:md5_hash]                = create_md5_hash(data_hash)
    data_hash[:mailing_addres]          = line[16]
    data_hash[:city]                    = line[18]
    data_hash[:state]                   = line[20]
    data_hash[:zip]                     = line[21]
    data_hash[:country]                 = line[22]
    data_hash[:principal_name]          = line[8]
    data_hash[:principal_address]       = line[9]
    data_hash[:principal_city]          = line[11]
    data_hash[:principal_state]         = line[13]
    data_hash[:principal_zip]           = line[14]
    data_hash[:principal_country]       = line[15]
    data_hash[:organization_terminated] = line[4]
    data_hash[:website]                 = line[7]
    data_hash[:last_scrape_date]        = Date.today
    data_hash[:next_scrape_date]        = Date.today.next_month
    data_hash                           = mark_null(data_hash)
    data_hash[:gross_receipts_not_greater_than] = line[3]
    data_hash
  end

  private

  def mark_null(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
