# frozen_string_literal: true
require 'csv'

class Parser < Hamster::Parser

  #
  def parse_link_for_download_cvs_data(html)
    document = Nokogiri::HTML html
    document.css("a[class='ds-c-button ds-c-button--small ds-c-button--transparent']").first['href']
  end

  def parse_cvs_data(file)

    csv_data = CSV.read(file)
    headers = csv_data.shift.map { |header| header.downcase }

    # Rename headers for correct hash title
    headers[headers.index('cityst')] = 'location'
    headers[headers.index('faildate')] = 'effective_date'
    headers[headers.index('savr')] = 'insurance_fund'
    headers[headers.index('restype')] = 'resolution'
    headers[headers.index('cost')] = 'estimated_loss'
    headers[headers.index('restype1')] = 'transaction_type'
    headers[headers.index('chclass1')] = 'charter_class'
    headers[headers.index('qbfdep')] = 'total_deposits'
    headers[headers.index('qbfasset')] = 'total_assets'

    data = csv_data.map do |row|
      hash = Hash[headers.zip(row)]

      hash.delete('id')

      hash['effective_date'] = Date.strptime(hash['effective_date'], '%m/%d/%Y').strftime('%Y-%m-%d')

      location_value = hash.delete('location')
      city, state = location_value.split(',').map(&:strip)
      hash['city'] = city
      hash['state'] = state

      hash
    end

    data
  end

end
